#!/usr/bin/env python3
"""
TMS to OBJ Converter for Yu-Gi-Oh! Tag Force Evolution (PS2)

TMS format (TGMS):
  Header (96 bytes):
    [0:4]   Magic: "TGMS"
    [4:8]   Header size (always 0x60 = 96)
    [8:12]  Geometry section offset
    [12:16] Section 2 offset (materials)
    [16:20] Section 3 offset
    [20:24] Section 4 offset
    [32:36] Section 5 offset (transforms)
    [36:40] Section 6 offset (texture refs)
    [40:44] Count 1 (mesh count)
    [48:52] Count 2
    [52:56] Count 3

  Geometry data:
    Vertices stored as VIF-like packets:
    - 32 bytes of CD padding between each vertex
    - 32-byte header blocks (8 float32: strip orientation?)
    - 48-byte vertex blocks: 16 bytes color + 32 bytes geometry
      - Color: 4x uint32 (vertex color, 0x80 = half intensity)
      - Geometry: 8 float32:
        [0] Position X
        [1] Position Z
        [2] UV U
        [3] UV V
        [4] Position Y (height)
        [5] Normal X
        [6] Normal Y
        [7] Normal Z
    - 16-byte end marker (0,0,0,0xFF)

  Section 6 (texture refs):
    Null-terminated texture filenames (.gim references)
"""

import struct
import sys
from pathlib import Path


def parse_tms(filepath):
    """Parse a TMS file and return vertex data organized by mesh groups."""
    with open(filepath, 'rb') as f:
        data = f.read()

    if data[:4] != b'TGMS':
        raise ValueError(f"Not a TMS file: {filepath}")

    header_size = struct.unpack_from('<I', data, 0x04)[0]
    off_geom = struct.unpack_from('<I', data, 0x08)[0]
    off_sec2 = struct.unpack_from('<I', data, 0x0c)[0]
    off_sec6 = struct.unpack_from('<I', data, 0x24)[0]
    count1 = struct.unpack_from('<I', data, 0x28)[0]

    # Extract texture references from section 6
    textures = []
    if off_sec6 < len(data):
        pos = off_sec6
        while pos < len(data):
            end = data.find(b'\x00', pos)
            if end <= pos:
                break
            name = data[pos:end].decode('ascii', errors='replace')
            if '.' in name and len(name) > 3:
                textures.append(name)
            pos = end + 1

    # Extract non-CD data regions from geometry section
    i = off_geom
    regions = []
    current_start = None
    while i < off_sec2:
        if data[i] != 0xCD:
            if current_start is None:
                current_start = i
        else:
            if current_start is not None:
                regions.append((current_start, i))
                current_start = None
        i += 1
    if current_start is not None:
        regions.append((current_start, off_sec2))

    # Parse vertices from regions, splitting into strips at non-vertex boundaries.
    # Non-48-byte regions (VIF command blocks) mark strip boundaries.
    vertices = []
    strips = []       # list of strips, each strip is a list of global vertex indices
    current_strip = []

    for start, end in regions:
        size = end - start
        if size == 48:
            # Vertex: 16 bytes color + 32 bytes geometry
            c0 = struct.unpack_from('<I', data, start)[0]
            color_val = c0 & 0xFF
            floats = struct.unpack_from('<8f', data, start + 16)

            idx = len(vertices)
            vertices.append({
                'x': floats[0],
                'z': floats[1],
                'u': floats[2],
                'v': floats[3],
                'y': floats[4],
                'nx': floats[5],
                'ny': floats[6],
                'nz': floats[7],
                'color': color_val,
            })
            current_strip.append(idx)
        else:
            # Non-vertex region = strip boundary
            if len(current_strip) >= 3:
                strips.append(current_strip)
            current_strip = []

    if len(current_strip) >= 3:
        strips.append(current_strip)

    return {
        'vertices': vertices,
        'strips': strips,
        'textures': textures,
        'counts': (count1,),
    }



def export_obj(tms_data, output_path):
    """Export parsed TMS data to OBJ format.

    Triangulates each strip independently, skipping degenerate triangles.
    """
    vertices = tms_data['vertices']
    strips = tms_data['strips']

    # Triangulate each strip, skipping degenerate triangles
    faces = []
    for strip in strips:
        for i in range(len(strip) - 2):
            if i % 2 == 0:
                a, b, c = strip[i], strip[i + 1], strip[i + 2]
            else:
                a, b, c = strip[i], strip[i + 2], strip[i + 1]

            va, vb, vc = vertices[a], vertices[b], vertices[c]
            pa = (va['x'], va['y'], va['z'])
            pb = (vb['x'], vb['y'], vb['z'])
            pc = (vc['x'], vc['y'], vc['z'])

            if pa == pb or pb == pc or pa == pc:
                continue

            faces.append((a, b, c))

    with open(output_path, 'w') as f:
        f.write(f"# TMS to OBJ Export\n")
        f.write(f"# Vertices: {len(vertices)}, Faces: {len(faces)}, Strips: {len(strips)}\n")
        if tms_data['textures']:
            f.write(f"# Textures: {', '.join(tms_data['textures'])}\n")
        f.write(f"\n")

        for v in vertices:
            f.write(f"v {v['x']:.6f} {v['y']:.6f} {v['z']:.6f}\n")
        f.write(f"\n")

        for v in vertices:
            f.write(f"vt {v['u']:.6f} {v['v']:.6f}\n")
        f.write(f"\n")

        for v in vertices:
            f.write(f"vn {v['nx']:.6f} {v['ny']:.6f} {v['nz']:.6f}\n")
        f.write(f"\n")

        f.write(f"g mesh\n")
        for a, b, c in faces:
            ia, ib, ic = a + 1, b + 1, c + 1
            f.write(f"f {ia}/{ia}/{ia} {ib}/{ib}/{ib} {ic}/{ic}/{ic}\n")

    return len(vertices), len(faces)


def convert_tms(tms_path, output_path=None):
    """Convert a single TMS file to OBJ."""
    tms_path = Path(tms_path)
    if output_path is None:
        output_path = tms_path.with_suffix('.obj')
    else:
        output_path = Path(output_path)

    tms_data = parse_tms(tms_path)
    vert_count, face_count = export_obj(tms_data, output_path)

    print(f"Converted {tms_path.name}: {vert_count} vertices, "
          f"{face_count} faces, {len(tms_data['strips'])} strips, "
          f"{len(tms_data['textures'])} textures")
    return tms_data


def batch_convert(source_dir, output_dir):
    """Convert all TMS files in a directory tree."""
    source_dir = Path(source_dir)
    output_dir = Path(output_dir)
    tms_files = sorted(source_dir.rglob('*.tms'))
    print(f"Found {len(tms_files)} TMS files")

    total = 0
    errors = 0
    for tms_path in tms_files:
        rel = tms_path.relative_to(source_dir)
        obj_path = output_dir / rel.with_suffix('.obj')
        obj_path.parent.mkdir(parents=True, exist_ok=True)
        try:
            convert_tms(tms_path, obj_path)
            total += 1
        except Exception as e:
            print(f"  ERROR: {tms_path.name}: {e}")
            errors += 1

    print(f"\nConverted {total} files ({errors} errors)")


if __name__ == '__main__':
    if len(sys.argv) < 2:
        print("Usage:")
        print("  tms_to_obj.py <file.tms> [output.obj]  Convert single file")
        print("  tms_to_obj.py --all <src_dir> <out_dir> Batch convert")
        sys.exit(1)

    if sys.argv[1] == '--all':
        batch_convert(sys.argv[2], sys.argv[3])
    else:
        convert_tms(sys.argv[1], sys.argv[2] if len(sys.argv) > 2 else None)
