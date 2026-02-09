#!/usr/bin/env python3
"""GIM to PNG Converter for PSP/PS2 Image Files.

GIM format (MIG.00.1PSP):
  Block-based structure with nested image and palette data.
  Supports indexed (4-bit, 8-bit) and direct color (RGBA5650, RGBA5551,
  RGBA4444, RGBA8888) pixel formats. PS2/PSP textures may use swizzled
  storage for cache efficiency.
"""

import struct
import sys
import os
from pathlib import Path

try:
    from PIL import Image
except ImportError:
    print("ERROR: Pillow required. Install with: pip3 install Pillow")
    sys.exit(1)

FORMAT_NAMES = {
    0: "RGBA5650", 1: "RGBA5551", 2: "RGBA4444",
    3: "RGBA8888", 4: "4bit-indexed", 5: "8bit-indexed",
}
FORMAT_BPP = {0: 16, 1: 16, 2: 16, 3: 32, 4: 4, 5: 8}


def psp_alpha(a):
    """Convert PSP alpha (0x7F=opaque) to standard (0xFF=opaque)."""
    return 255 if a >= 128 else min(255, a * 2)


def unswizzle(data, width, height, bpp):
    """Unswizzle PSP texture data (16-byte block, 8-row tile pattern)."""
    row_bytes = (width * bpp + 7) // 8
    if row_bytes < 16:
        return data
    out = bytearray(len(data))
    blocks_per_row = row_bytes // 16
    src = 0
    for by in range(0, height, 8):
        for bx in range(blocks_per_row):
            for row in range(8):
                y = by + row
                if y >= height:
                    break
                dst = y * row_bytes + bx * 16
                chunk = min(16, len(data) - src)
                if chunk <= 0:
                    break
                copy_len = min(dst + chunk, len(out)) - dst
                if copy_len > 0:
                    out[dst:dst + copy_len] = data[src:src + copy_len]
                src += 16
    return bytes(out)


def unswizzle_palette_index(idx):
    """Unswizzle 8-bit palette index (PS2 block interleave)."""
    block = idx & ~31
    sub = idx & 31
    group = (sub >> 3) & 3
    if group == 1:
        return block + (sub & 7) + 16
    if group == 2:
        return block + (sub & 7) + 8
    return idx


def parse_block_header(data, offset):
    """Parse a 16-byte GIM block header."""
    if offset + 16 > len(data):
        return None
    return {
        'type': struct.unpack_from('<H', data, offset)[0],
        'size': struct.unpack_from('<I', data, offset + 4)[0],
        'next': struct.unpack_from('<I', data, offset + 8)[0],
        'child': struct.unpack_from('<I', data, offset + 12)[0],
        'offset': offset,
    }


def parse_sub_header(data, offset):
    """Parse a GIM image/palette sub-header (48+ bytes)."""
    if offset + 48 > len(data):
        return None
    return {
        'pixel_format': struct.unpack_from('<H', data, offset + 4)[0],
        'pixel_order': struct.unpack_from('<H', data, offset + 6)[0],
        'width': struct.unpack_from('<H', data, offset + 8)[0],
        'height': struct.unpack_from('<H', data, offset + 10)[0],
        'pixel_data_off': struct.unpack_from('<I', data, offset + 28)[0],
        'data_size': struct.unpack_from('<I', data, offset + 32)[0],
        'sub_offset': offset,
    }


def parse_gim(filepath):
    """Parse GIM file and return raw data, image blocks, and palette blocks."""
    with open(filepath, 'rb') as f:
        data = f.read()

    if data[:11] != b'MIG.00.1PSP':
        raise ValueError("Not a GIM file")

    images = []
    palettes = []

    def walk(offset, end):
        while offset < end and offset + 16 <= len(data):
            block = parse_block_header(data, offset)
            if not block or block['size'] == 0:
                break
            block_end = min(offset + block['size'], len(data))

            if block['type'] == 4:  # Image data
                sub = parse_sub_header(data, offset + block['child'])
                if sub:
                    images.append((block, sub))
            elif block['type'] == 5:  # Palette data
                sub = parse_sub_header(data, offset + block['child'])
                if sub:
                    palettes.append((block, sub))
            elif block['type'] in (2, 3):  # Container blocks
                walk(offset + block['child'], block_end)

            if block['next'] == 0:
                break
            next_offset = offset + block['next']
            if next_offset <= offset:
                break
            offset = next_offset

    walk(16, len(data))
    return data, images, palettes


def decode_palette(data, psub):
    """Decode palette colors from a palette sub-block."""
    fmt = psub['pixel_format']
    w, h = psub['width'], psub['height']
    offset = psub['sub_offset'] + psub['pixel_data_off']
    count = max(w * h, 16)
    colors = []

    for i in range(count):
        if fmt == 3:  # RGBA8888
            o = offset + i * 4
            if o + 4 > len(data):
                break
            colors.append((data[o], data[o + 1], data[o + 2], psp_alpha(data[o + 3])))
        elif fmt == 1:  # RGBA5551
            o = offset + i * 2
            if o + 2 > len(data):
                break
            v = struct.unpack_from('<H', data, o)[0]
            colors.append((
                (v & 0x1F) * 255 // 31,
                ((v >> 5) & 0x1F) * 255 // 31,
                ((v >> 10) & 0x1F) * 255 // 31,
                255 if (v >> 15) & 1 else 0,
            ))
        elif fmt == 0:  # RGBA5650
            o = offset + i * 2
            if o + 2 > len(data):
                break
            v = struct.unpack_from('<H', data, o)[0]
            colors.append((
                (v & 0x1F) * 255 // 31,
                ((v >> 5) & 0x3F) * 255 // 63,
                ((v >> 11) & 0x1F) * 255 // 31,
                255,
            ))
        elif fmt == 2:  # RGBA4444
            o = offset + i * 2
            if o + 2 > len(data):
                break
            v = struct.unpack_from('<H', data, o)[0]
            colors.append((
                (v & 0xF) * 17,
                ((v >> 4) & 0xF) * 17,
                ((v >> 8) & 0xF) * 17,
                ((v >> 12) & 0xF) * 17,
            ))

    return colors


def decode_indexed(data, isub, palette):
    """Decode an indexed-color image using a palette."""
    fmt = isub['pixel_format']
    w, h = isub['width'], isub['height']
    offset = isub['sub_offset'] + isub['pixel_data_off']
    bpp = FORMAT_BPP[fmt]
    row_bytes = (w * bpp + 7) // 8

    pixel_data = data[offset:offset + row_bytes * h]
    if isub['pixel_order'] == 1:
        pixel_data = unswizzle(pixel_data, w, h, bpp)

    img = Image.new('RGBA', (w, h))
    px = img.load()

    for y in range(h):
        for x in range(w):
            if fmt == 4:  # 4-bit indexed
                bi = y * row_bytes + x // 2
                if bi >= len(pixel_data):
                    continue
                idx = (pixel_data[bi] & 0x0F) if x % 2 == 0 else ((pixel_data[bi] >> 4) & 0x0F)
            else:  # 8-bit indexed
                bi = y * row_bytes + x
                if bi >= len(pixel_data):
                    continue
                idx = unswizzle_palette_index(pixel_data[bi])

            px[x, y] = palette[idx] if idx < len(palette) else (0, 0, 0, 0)

    return img


def decode_direct(data, isub):
    """Decode a direct-color image."""
    fmt = isub['pixel_format']
    w, h = isub['width'], isub['height']
    offset = isub['sub_offset'] + isub['pixel_data_off']
    bpp = FORMAT_BPP[fmt]

    pixel_data = data[offset:offset + (w * bpp + 7) // 8 * h]
    if isub['pixel_order'] == 1:
        pixel_data = unswizzle(pixel_data, w, h, bpp)

    img = Image.new('RGBA', (w, h))
    px = img.load()

    for y in range(h):
        for x in range(w):
            if fmt == 3:  # RGBA8888
                o = (y * w + x) * 4
                if o + 4 > len(pixel_data):
                    continue
                px[x, y] = (pixel_data[o], pixel_data[o + 1], pixel_data[o + 2],
                             psp_alpha(pixel_data[o + 3]))
            elif fmt == 1:  # RGBA5551
                o = (y * w + x) * 2
                if o + 2 > len(pixel_data):
                    continue
                v = struct.unpack_from('<H', pixel_data, o)[0]
                px[x, y] = (
                    (v & 0x1F) * 255 // 31,
                    ((v >> 5) & 0x1F) * 255 // 31,
                    ((v >> 10) & 0x1F) * 255 // 31,
                    255 if (v >> 15) & 1 else 0,
                )
            elif fmt == 0:  # RGBA5650
                o = (y * w + x) * 2
                if o + 2 > len(pixel_data):
                    continue
                v = struct.unpack_from('<H', pixel_data, o)[0]
                px[x, y] = (
                    (v & 0x1F) * 255 // 31,
                    ((v >> 5) & 0x3F) * 255 // 63,
                    ((v >> 11) & 0x1F) * 255 // 31,
                    255,
                )
            elif fmt == 2:  # RGBA4444
                o = (y * w + x) * 2
                if o + 2 > len(pixel_data):
                    continue
                v = struct.unpack_from('<H', pixel_data, o)[0]
                px[x, y] = (
                    (v & 0xF) * 17,
                    ((v >> 4) & 0xF) * 17,
                    ((v >> 8) & 0xF) * 17,
                    ((v >> 12) & 0xF) * 17,
                )

    return img


def convert_gim(gim_path, output_path=None, verbose=True):
    """Convert a single GIM file to PNG."""
    gim_path = Path(gim_path)
    if output_path is None:
        output_path = gim_path.with_suffix('.png')
    else:
        output_path = Path(output_path)

    try:
        data, image_blocks, palette_blocks = parse_gim(str(gim_path))
    except Exception as e:
        if verbose:
            print(f"  ERROR: {gim_path}: {e}")
        return None

    if not image_blocks:
        if verbose:
            print(f"  WARNING: No image blocks in {gim_path}")
        return None

    _, isub = image_blocks[0]
    fmt = isub['pixel_format']
    w, h = isub['width'], isub['height']
    swizzled = "swizzled" if isub['pixel_order'] else "normal"

    if verbose:
        print(f"  {FORMAT_NAMES.get(fmt, '?')} {w}x{h} {swizzled}", end="")

    try:
        if fmt in (4, 5):  # Indexed
            if not palette_blocks:
                if verbose:
                    print(" - ERROR: No palette")
                return None
            _, psub = palette_blocks[0]
            palette = decode_palette(data, psub)
            if verbose:
                print(f" palette:{len(palette)}colors", end="")
            img = decode_indexed(data, isub, palette)
        elif fmt in (0, 1, 2, 3):  # Direct color
            img = decode_direct(data, isub)
        else:
            if verbose:
                print(f" - ERROR: Unsupported format {fmt}")
            return None

        os.makedirs(output_path.parent, exist_ok=True)
        img.save(str(output_path))
        if verbose:
            print(f" -> {output_path}")
        return str(output_path)

    except Exception as e:
        if verbose:
            print(f" - ERROR: {e}")
            import traceback
            traceback.print_exc()
        return None


def batch_convert(source_dir, output_dir, verbose=True):
    """Convert all GIM files in a directory tree."""
    source_dir = Path(source_dir)
    output_dir = Path(output_dir)
    gim_files = sorted(set(
        list(source_dir.rglob('*.gim')) + list(source_dir.rglob('*.GIM'))
    ))

    print(f"Found {len(gim_files)} GIM files\n")

    ok = 0
    fail = 0
    for gim_path in gim_files:
        rel = gim_path.relative_to(source_dir)
        print(f"Converting: {rel}")
        png_path = output_dir / rel.with_suffix('.png')
        if convert_gim(gim_path, png_path, verbose):
            ok += 1
        else:
            fail += 1

    print(f"\n{'=' * 60}")
    print(f"Done. {ok}/{ok + fail} converted successfully.")
    return ok, fail


if __name__ == '__main__':
    if len(sys.argv) < 2:
        print("GIM to PNG Converter")
        print()
        print("Usage:")
        print("  gim_to_png.py <file.gim> [output.png]      Convert single file")
        print("  gim_to_png.py --all <source_dir> <out_dir>  Batch convert")
        sys.exit(1)

    if sys.argv[1] == '--all':
        if len(sys.argv) < 4:
            print("Usage: gim_to_png.py --all <source_dir> <out_dir>")
            sys.exit(1)
        batch_convert(sys.argv[2], sys.argv[3])
    else:
        result = convert_gim(sys.argv[1], sys.argv[2] if len(sys.argv) > 2 else None)
        if result is None:
            sys.exit(1)
