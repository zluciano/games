#!/usr/bin/env python3
"""
EHP Archive Extractor for Yu-Gi-Oh! Tag Force Evolution (PS2)

EHP format (version 3):
  Header (16 bytes):
    [0:4]   Magic: "EHP\x03"
    [4:8]   Total file size (uint32 LE)
    [8:12]  Marker: "NOT "
    [12:16] File count (uint32 LE)

  Entry table (file_count * 8 bytes):
    Each entry: name_offset (uint32 LE) + data_offset (uint32 LE)
    - name_offset: absolute offset to null-terminated filename,
      immediately followed by uint32 LE file_size
    - data_offset: absolute offset to file data

  File data is aligned to 16-byte boundaries.
"""

import struct
import sys
import os
from pathlib import Path


def extract_ehp(ehp_path, output_dir=None):
    ehp_path = Path(ehp_path)
    if output_dir is None:
        output_dir = ehp_path.parent / ehp_path.stem
    else:
        output_dir = Path(output_dir)

    with open(ehp_path, 'rb') as f:
        data = f.read()

    # Validate header
    magic = data[0:4]
    if magic != b'EHP\x03':
        print(f"ERROR: Not an EHP file (magic={magic!r})")
        return []

    total_size = struct.unpack_from('<I', data, 4)[0]
    marker = data[8:12]
    file_count = struct.unpack_from('<I', data, 12)[0]

    if marker != b'NOT ':
        print(f"WARNING: Unexpected marker {marker!r} (expected 'NOT ')")

    # Parse entry table
    entries = []
    for i in range(file_count):
        offset = 16 + i * 8
        name_off = struct.unpack_from('<I', data, offset)[0]
        data_off = struct.unpack_from('<I', data, offset + 4)[0]
        entries.append((name_off, data_off))

    # Extract files
    os.makedirs(output_dir, exist_ok=True)
    extracted = []

    for i, (name_off, data_off) in enumerate(entries):
        # Read null-terminated filename
        end = data.index(b'\x00', name_off)
        filename = data[name_off:end].decode('ascii', errors='replace')

        # File size is uint32 LE immediately after the null terminator
        file_size = struct.unpack_from('<I', data, end + 1)[0]

        # Extract file data
        file_data = data[data_off:data_off + file_size]

        # Write to output
        out_path = output_dir / filename
        os.makedirs(out_path.parent, exist_ok=True)
        with open(out_path, 'wb') as f:
            f.write(file_data)

        extracted.append({
            'name': filename,
            'size': file_size,
            'offset': data_off,
            'path': str(out_path),
        })

    return extracted


def extract_all_ehp(source_dir, output_base, recursive=True):
    """Extract all EHP files from a directory tree."""
    source_dir = Path(source_dir)
    output_base = Path(output_base)
    total_files = 0

    pattern = '**/*.EHP' if recursive else '*.EHP'
    ehp_files = sorted(source_dir.glob(pattern))

    # Also match lowercase
    ehp_files += sorted(source_dir.glob(pattern.replace('.EHP', '.ehp')))
    ehp_files = sorted(set(ehp_files))

    print(f"Found {len(ehp_files)} EHP archives")

    for ehp_path in ehp_files:
        rel = ehp_path.relative_to(source_dir)
        out_dir = output_base / rel.parent / rel.stem

        print(f"\nExtracting: {rel}")
        files = extract_ehp(ehp_path, out_dir)
        total_files += len(files)

        for f in files:
            ext = Path(f['name']).suffix
            print(f"  {f['name']:40s} {f['size']:>10,} bytes  ({ext})")

    print(f"\n{'='*60}")
    print(f"Done. Extracted {total_files} files from {len(ehp_files)} archives.")
    return total_files


if __name__ == '__main__':
    if len(sys.argv) < 2:
        print("Usage:")
        print("  ehp_extract.py <file.ehp> [output_dir]     Extract single EHP")
        print("  ehp_extract.py --all <source_dir> <output>  Extract all EHP files")
        sys.exit(1)

    if sys.argv[1] == '--all':
        if len(sys.argv) < 4:
            print("Usage: ehp_extract.py --all <source_dir> <output_dir>")
            sys.exit(1)
        extract_all_ehp(sys.argv[2], sys.argv[3])
    else:
        ehp_file = sys.argv[1]
        out_dir = sys.argv[2] if len(sys.argv) > 2 else None
        files = extract_ehp(ehp_file, out_dir)
        for f in files:
            print(f"  {f['name']:40s} {f['size']:>10,} bytes")
        print(f"\nExtracted {len(files)} files.")
