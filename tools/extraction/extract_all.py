#!/usr/bin/env python3
"""
Tag Force Evolution - Complete Asset Extraction Pipeline

Extracts, converts, and organizes ALL art assets from the raw extracted
PS2 data into a clean, categorized directory structure.

Usage:
    python3 tools/extraction/extract_all.py

Requires:
    - assets/extracted/ directory with raw PS2 data
    - Pillow (pip3 install Pillow)

Output:
    assets/tagforce/  (organized asset library)
"""

import gzip
import os
import shutil
import sys
import time
from pathlib import Path

# Add tools/extraction to path so we can import our converters
SCRIPT_DIR = Path(__file__).parent
sys.path.insert(0, str(SCRIPT_DIR))

from ehp_extract import extract_ehp
from gim_to_png import convert_gim
from tms_to_obj import convert_tms

# ──────────────────────────────────────────────────────────────
# Configuration
# ──────────────────────────────────────────────────────────────

PROJECT_ROOT = SCRIPT_DIR.parent.parent
EXTRACTED = PROJECT_ROOT / "assets" / "extracted"
OUTPUT = PROJECT_ROOT / "assets" / "tagforce"

# Language suffix mapping (Tag Force uses these suffixes)
LANG_MAP = {
    "_E": "en", "_F": "fr", "_G": "de", "_I": "it", "_S": "es",
    "_BE": "en", "_FF": "fr", "_GG": "de", "_II": "it", "_SS": "es",
    "_B": "base",  # Japanese/base assets
    "_ENG": "en", "_FRA": "fr", "_GER": "de", "_ITA": "it", "_SPA": "es",
}

# Stats
stats = {
    "ehp_gz_decompressed": 0,
    "ehp_extracted": 0,
    "ehp_files_total": 0,
    "gim_converted": 0,
    "gim_failed": 0,
    "tms_converted": 0,
    "tms_failed": 0,
    "files_copied": 0,
    "errors": [],
}


# ──────────────────────────────────────────────────────────────
# Helpers
# ──────────────────────────────────────────────────────────────

def detect_language(name):
    """Detect language from directory/file name suffix."""
    upper = name.upper()
    # Check longer suffixes first
    for suffix, lang in sorted(LANG_MAP.items(), key=lambda x: -len(x[0])):
        if upper.endswith(suffix):
            return lang
    return None


def ensure_dir(path):
    """Create directory if it doesn't exist."""
    os.makedirs(path, exist_ok=True)
    return path


def convert_gim_safe(src, dst):
    """Convert GIM to PNG, return True on success."""
    try:
        result = convert_gim(str(src), str(dst), verbose=False)
        if result:
            stats["gim_converted"] += 1
            return True
        stats["gim_failed"] += 1
        return False
    except Exception as e:
        stats["gim_failed"] += 1
        stats["errors"].append(f"GIM: {src} -> {e}")
        return False


def convert_tms_safe(src, dst):
    """Convert TMS to OBJ, return True on success."""
    import io
    from contextlib import redirect_stdout
    try:
        # Suppress convert_tms print output
        with redirect_stdout(io.StringIO()):
            result = convert_tms(str(src), str(dst))
        if result:
            stats["tms_converted"] += 1
            return True
        stats["tms_failed"] += 1
        return False
    except Exception as e:
        stats["tms_failed"] += 1
        stats["errors"].append(f"TMS: {src} -> {e}")
        return False


def copy_file(src, dst):
    """Copy a file preserving directory structure."""
    ensure_dir(Path(dst).parent)
    shutil.copy2(src, dst)
    stats["files_copied"] += 1


def convert_all_gim_in_dir(src_dir, dst_dir, flat=False):
    """Convert all GIM files in a directory to PNG."""
    src_dir = Path(src_dir)
    dst_dir = Path(dst_dir)
    if not src_dir.exists():
        return

    gim_files = sorted(set(
        list(src_dir.rglob("*.gim")) + list(src_dir.rglob("*.GIM"))
    ))

    for gim in gim_files:
        if flat:
            png_path = dst_dir / gim.with_suffix(".png").name
        else:
            rel = gim.relative_to(src_dir)
            png_path = dst_dir / rel.with_suffix(".png")
        ensure_dir(png_path.parent)
        convert_gim_safe(gim, png_path)


def copy_non_gim_files(src_dir, dst_dir):
    """Copy non-GIM files (BIN, etc.) preserving structure."""
    src_dir = Path(src_dir)
    dst_dir = Path(dst_dir)
    if not src_dir.exists():
        return

    for f in src_dir.rglob("*"):
        if f.is_file() and f.suffix.lower() not in (".gim",):
            rel = f.relative_to(src_dir)
            copy_file(f, dst_dir / rel)


# ──────────────────────────────────────────────────────────────
# Step 1: Decompress EHP.GZ archives
# ──────────────────────────────────────────────────────────────

def step_decompress_ehp_gz():
    """Decompress all .ehp.gz files in-place (creates .ehp next to .gz)."""
    print("\n" + "=" * 60)
    print("STEP 1: Decompress EHP.GZ archives")
    print("=" * 60)

    gz_files = sorted(EXTRACTED.rglob("*.ehp.gz"))
    gz_files += sorted(EXTRACTED.rglob("*.EHP.GZ"))
    gz_files = sorted(set(gz_files))

    print(f"Found {len(gz_files)} compressed archives\n")

    for gz_path in gz_files:
        ehp_path = gz_path.with_suffix("")  # Remove .gz
        if ehp_path.exists():
            print(f"  [skip] {gz_path.relative_to(EXTRACTED)} (already decompressed)")
            continue

        try:
            with gzip.open(gz_path, "rb") as f_in:
                with open(ehp_path, "wb") as f_out:
                    f_out.write(f_in.read())
            stats["ehp_gz_decompressed"] += 1
            print(f"  [ok]   {gz_path.relative_to(EXTRACTED)} -> {ehp_path.name}")
        except Exception as e:
            stats["errors"].append(f"GZIP: {gz_path} -> {e}")
            print(f"  [FAIL] {gz_path.relative_to(EXTRACTED)}: {e}")

    print(f"\nDecompressed: {stats['ehp_gz_decompressed']}")


# ──────────────────────────────────────────────────────────────
# Step 2: Extract EHP archives
# ──────────────────────────────────────────────────────────────

def step_extract_ehp():
    """Extract all EHP archives into subdirectories."""
    print("\n" + "=" * 60)
    print("STEP 2: Extract EHP archives")
    print("=" * 60)

    ehp_files = sorted(set(
        list(EXTRACTED.rglob("*.ehp")) + list(EXTRACTED.rglob("*.EHP"))
    ))

    # Exclude .ehf files (different format)
    ehp_files = [f for f in ehp_files if f.suffix.lower() == ".ehp"]

    print(f"Found {len(ehp_files)} EHP archives\n")

    for ehp_path in ehp_files:
        out_dir = ehp_path.parent / ehp_path.stem
        if out_dir.exists() and any(out_dir.iterdir()):
            # Already extracted
            continue

        try:
            files = extract_ehp(str(ehp_path), str(out_dir))
            stats["ehp_extracted"] += 1
            stats["ehp_files_total"] += len(files)
            rel = ehp_path.relative_to(EXTRACTED)
            print(f"  [ok]   {rel} -> {len(files)} files")
        except Exception as e:
            stats["errors"].append(f"EHP: {ehp_path} -> {e}")
            print(f"  [FAIL] {ehp_path.relative_to(EXTRACTED)}: {e}")

    print(f"\nExtracted: {stats['ehp_extracted']} archives, {stats['ehp_files_total']} files")


# ──────────────────────────────────────────────────────────────
# Step 3: Convert and organize assets
# ──────────────────────────────────────────────────────────────

def step_organize_assets():
    """Convert all GIM/TMS files and organize into categorized structure."""
    print("\n" + "=" * 60)
    print("STEP 3: Convert and organize assets")
    print("=" * 60)

    # ── UI Assets ──
    print("\n--- UI Assets ---")

    # INPUT/ -> ui/input/
    print("  Processing INPUT/...")
    convert_all_gim_in_dir(EXTRACTED / "INPUT", OUTPUT / "ui" / "input", flat=True)
    copy_non_gim_files(EXTRACTED / "INPUT", OUTPUT / "ui" / "input")

    # SHOP/ -> ui/shop/{lang}/
    print("  Processing SHOP/...")
    for sub in sorted((EXTRACTED / "SHOP").iterdir()) if (EXTRACTED / "SHOP").exists() else []:
        if sub.is_dir():
            lang = detect_language(sub.name) or sub.name.lower()
            convert_all_gim_in_dir(sub, OUTPUT / "ui" / "shop" / lang, flat=True)

    # DECK/ -> ui/deck/{category}/{lang}/
    print("  Processing DECK/...")
    for sub in sorted((EXTRACTED / "DECK").iterdir()) if (EXTRACTED / "DECK").exists() else []:
        if sub.is_dir():
            name = sub.name
            lang = detect_language(name)
            if lang:
                # Determine category (ALL, R_VIEW, TUTO, DECKSWAP)
                cat = name.rsplit("_", 1)[0].lower() if "_" in name else name.lower()
                # Normalize: ALL_E -> all, R_VIEW_E -> r_view, TUTO_E -> tuto
                for suffix in sorted(LANG_MAP.keys(), key=lambda x: -len(x)):
                    if name.upper().endswith(suffix):
                        cat = name[:len(name) - len(suffix)].lower()
                        break
                convert_all_gim_in_dir(sub, OUTPUT / "ui" / "deck" / cat / lang, flat=True)
            else:
                convert_all_gim_in_dir(sub, OUTPUT / "ui" / "deck" / name.lower(), flat=True)

    # T_MENU/ -> ui/menu/{lang}/
    print("  Processing T_MENU/...")
    for sub in sorted((EXTRACTED / "T_MENU").iterdir()) if (EXTRACTED / "T_MENU").exists() else []:
        if sub.is_dir():
            lang = detect_language(sub.name) or sub.name.lower()
            convert_all_gim_in_dir(sub, OUTPUT / "ui" / "menu" / lang, flat=True)

    # HELP/ -> ui/help/
    print("  Processing HELP/...")
    convert_all_gim_in_dir(EXTRACTED / "HELP", OUTPUT / "ui" / "help", flat=True)

    # LABO/ -> ui/labo/{subdir}/
    print("  Processing LABO/...")
    for sub in sorted((EXTRACTED / "LABO").iterdir()) if (EXTRACTED / "LABO").exists() else []:
        if sub.is_dir():
            convert_all_gim_in_dir(sub, OUTPUT / "ui" / "labo" / sub.name.lower())
            copy_non_gim_files(sub, OUTPUT / "ui" / "labo" / sub.name.lower())

    # TUTORIAL/ -> ui/tutorial/{category}/
    print("  Processing TUTORIAL/...")
    for sub in sorted((EXTRACTED / "TUTORIAL").iterdir()) if (EXTRACTED / "TUTORIAL").exists() else []:
        if sub.is_dir():
            name = sub.name
            if name == "FACE":
                convert_all_gim_in_dir(sub, OUTPUT / "ui" / "tutorial" / "face", flat=True)
            else:
                lang = detect_language(name) or name.lower()
                convert_all_gim_in_dir(sub, OUTPUT / "ui" / "tutorial" / lang, flat=True)

    # ── Card & Duel Assets ──
    print("\n--- Card & Duel Assets ---")

    # DUEL/BASIC_* -> cards/basic/{lang}/
    print("  Processing DUEL/BASIC_*/...")
    basic_lang = {"BASIC_BE": "en", "BASIC_FF": "fr", "BASIC_GG": "de",
                  "BASIC_II": "it", "BASIC_SS": "es"}
    for dirname, lang in basic_lang.items():
        src = EXTRACTED / "DUEL" / dirname
        if src.exists():
            convert_all_gim_in_dir(src, OUTPUT / "cards" / "basic" / lang, flat=True)

    # DUEL/BG/ -> cards/duel_bg/ (extract EHP first, then convert GIM inside)
    print("  Processing DUEL/BG/...")
    bg_dir = EXTRACTED / "DUEL" / "BG"
    if bg_dir.exists():
        # EHP files were extracted in step 2 - convert any GIM inside
        convert_all_gim_in_dir(bg_dir, OUTPUT / "cards" / "duel_bg")

    # DUEL/CUTIN/ -> cards/cutin/ (EHP archives with character cut-ins)
    print("  Processing DUEL/CUTIN/...")
    cutin_dir = EXTRACTED / "DUEL" / "CUTIN"
    if cutin_dir.exists():
        convert_all_gim_in_dir(cutin_dir, OUTPUT / "cards" / "cutin")

    # DUEL/CUTIN_C/ -> cards/cutin_color/
    print("  Processing DUEL/CUTIN_C/...")
    convert_all_gim_in_dir(EXTRACTED / "DUEL" / "CUTIN_C", OUTPUT / "cards" / "cutin_color")

    # DUEL/FACES/ -> cards/faces/
    print("  Processing DUEL/FACES/...")
    convert_all_gim_in_dir(EXTRACTED / "DUEL" / "FACES", OUTPUT / "cards" / "faces", flat=True)

    # DUEL/START/ -> cards/start/{lang}/
    print("  Processing DUEL/START/...")
    for sub in sorted((EXTRACTED / "DUEL" / "START").iterdir()) if (EXTRACTED / "DUEL" / "START").exists() else []:
        if sub.is_dir():
            lang = detect_language(sub.name) or sub.name.lower()
            convert_all_gim_in_dir(sub, OUTPUT / "cards" / "start" / lang)

    # DUEL/RESULT/ -> cards/result/{lang}/
    print("  Processing DUEL/RESULT/...")
    for sub in sorted((EXTRACTED / "DUEL" / "RESULT").iterdir()) if (EXTRACTED / "DUEL" / "RESULT").exists() else []:
        if sub.is_dir():
            lang = detect_language(sub.name) or sub.name.lower()
            convert_all_gim_in_dir(sub, OUTPUT / "cards" / "result" / lang)

    # DUEL/ZAKO/ -> cards/zako/
    print("  Processing DUEL/ZAKO/...")
    convert_all_gim_in_dir(EXTRACTED / "DUEL" / "ZAKO", OUTPUT / "cards" / "zako")

    # DUELSYS/ -> cards/duelsys/{lang}/
    print("  Processing DUELSYS/...")
    for sub in sorted((EXTRACTED / "DUELSYS").iterdir()) if (EXTRACTED / "DUELSYS").exists() else []:
        if sub.is_dir():
            lang = detect_language(sub.name) or sub.name.lower()
            convert_all_gim_in_dir(sub, OUTPUT / "cards" / "duelsys" / lang)

    # ── Character Assets ──
    print("\n--- Character Assets ---")

    # FIELD/BUSTUP/ -> characters/bustup/{character}/
    print("  Processing FIELD/BUSTUP/...")
    bustup_dir = EXTRACTED / "FIELD" / "BUSTUP"
    if bustup_dir.exists():
        # EHP.GZ decompressed in step 1, EHP extracted in step 2
        # Now convert all GIM files inside extracted directories
        convert_all_gim_in_dir(bustup_dir, OUTPUT / "characters" / "bustup")

    # FIELD/SDCHR/ -> characters/sd/
    print("  Processing FIELD/SDCHR/...")
    convert_all_gim_in_dir(EXTRACTED / "FIELD" / "SDCHR", OUTPUT / "characters" / "sd", flat=True)

    # FIELD/SC_SLA/ -> characters/sprites_sla/
    print("  Processing FIELD/SC_SLA/...")
    convert_all_gim_in_dir(EXTRACTED / "FIELD" / "SC_SLA", OUTPUT / "characters" / "sprites_sla", flat=True)

    # FIELD/SC_VER/ -> characters/sprites_ver/
    print("  Processing FIELD/SC_VER/...")
    convert_all_gim_in_dir(EXTRACTED / "FIELD" / "SC_VER", OUTPUT / "characters" / "sprites_ver", flat=True)

    # ── Background & Map Assets ──
    print("\n--- Background & Map Assets ---")

    # FIELD/MAP/BG_*/ -> backgrounds/maps/{BG_XX_XX}/  (textures)
    #                  -> models/maps/{BG_XX_XX}/       (3D models)
    print("  Processing FIELD/MAP/...")
    map_dir = EXTRACTED / "FIELD" / "MAP"
    if map_dir.exists():
        for sub in sorted(map_dir.iterdir()):
            if sub.is_dir() and sub.name.startswith("BG_"):
                map_id = sub.name
                # Convert GIM textures
                convert_all_gim_in_dir(sub, OUTPUT / "backgrounds" / "maps" / map_id, flat=True)
                # Convert TMS models
                tms_files = sorted(sub.glob("*.tms")) + sorted(sub.glob("*.TMS"))
                for tms in tms_files:
                    obj_path = OUTPUT / "models" / "maps" / map_id / tms.with_suffix(".obj").name
                    ensure_dir(obj_path.parent)
                    convert_tms_safe(tms, obj_path)

    # FIELD/BIG_MAP/ -> backgrounds/big_map/{time}/
    print("  Processing FIELD/BIG_MAP/...")
    big_map_dir = EXTRACTED / "FIELD" / "BIG_MAP"
    if big_map_dir.exists():
        for sub in sorted(big_map_dir.iterdir()):
            if sub.is_dir():
                convert_all_gim_in_dir(sub, OUTPUT / "backgrounds" / "big_map" / sub.name.lower())

    # FIELD/ALWAYS_*/ -> backgrounds/field/{lang}/
    print("  Processing FIELD/ALWAYS_*/...")
    for suffix, lang in {"ALWAYS_B": "base", "ALWAYS_E": "en", "ALWAYS_F": "fr",
                         "ALWAYS_G": "de", "ALWAYS_I": "it", "ALWAYS_S": "es"}.items():
        src = EXTRACTED / "FIELD" / suffix
        if src.exists():
            convert_all_gim_in_dir(src, OUTPUT / "backgrounds" / "field" / lang, flat=True)

    # FIELD/EVENT/ -> backgrounds/event/
    print("  Processing FIELD/EVENT/...")
    convert_all_gim_in_dir(EXTRACTED / "FIELD" / "EVENT", OUTPUT / "backgrounds" / "event")

    # FIELD/MAIL/ -> backgrounds/mail/
    print("  Processing FIELD/MAIL/...")
    convert_all_gim_in_dir(EXTRACTED / "FIELD" / "MAIL", OUTPUT / "backgrounds" / "mail")

    # FIELD/BREAD/ -> backgrounds/bread/
    print("  Processing FIELD/BREAD/...")
    convert_all_gim_in_dir(EXTRACTED / "FIELD" / "BREAD", OUTPUT / "backgrounds" / "bread")

    # ── Data Assets (non-graphic) ──
    print("\n--- Data Assets ---")

    # DATABASE/ -> data/database/
    print("  Processing DATABASE/...")
    copy_non_gim_files(EXTRACTED / "DATABASE", OUTPUT / "data" / "database")
    convert_all_gim_in_dir(EXTRACTED / "DATABASE", OUTPUT / "data" / "database")

    # FONT/ -> data/font/
    print("  Processing FONT/...")
    font_dir = EXTRACTED / "FONT"
    if font_dir.exists():
        for f in font_dir.iterdir():
            if f.is_file():
                copy_file(f, OUTPUT / "data" / "font" / f.name)

    # SND/ -> data/sound/
    print("  Processing SND/...")
    snd_dir = EXTRACTED / "SND"
    if snd_dir.exists():
        for f in snd_dir.iterdir():
            if f.is_file():
                copy_file(f, OUTPUT / "data" / "sound" / f.name)

    # MOVIE/ -> data/movie/
    print("  Processing MOVIE/...")
    copy_non_gim_files(EXTRACTED / "MOVIE", OUTPUT / "data" / "movie")

    # SCRIPT/ -> data/scripts/
    print("  Processing SCRIPT/...")
    copy_non_gim_files(EXTRACTED / "SCRIPT", OUTPUT / "data" / "scripts")


# ──────────────────────────────────────────────────────────────
# Step 4: Report
# ──────────────────────────────────────────────────────────────

def step_report():
    """Print final statistics."""
    print("\n" + "=" * 60)
    print("EXTRACTION COMPLETE")
    print("=" * 60)

    print(f"""
  EHP.GZ decompressed:  {stats['ehp_gz_decompressed']}
  EHP archives extracted: {stats['ehp_extracted']} ({stats['ehp_files_total']} files)
  GIM -> PNG converted:  {stats['gim_converted']}
  GIM conversion failed: {stats['gim_failed']}
  TMS -> OBJ converted:  {stats['tms_converted']}
  TMS conversion failed: {stats['tms_failed']}
  Other files copied:    {stats['files_copied']}
""")

    # Count output files
    total_png = len(list(OUTPUT.rglob("*.png")))
    total_obj = len(list(OUTPUT.rglob("*.obj")))
    total_all = sum(1 for _ in OUTPUT.rglob("*") if _.is_file())

    print(f"  Output directory: {OUTPUT}")
    print(f"  Total PNG files:  {total_png}")
    print(f"  Total OBJ files:  {total_obj}")
    print(f"  Total all files:  {total_all}")

    # Disk usage
    total_size = sum(f.stat().st_size for f in OUTPUT.rglob("*") if f.is_file())
    print(f"  Total disk usage: {total_size / 1024 / 1024:.1f} MB")

    if stats["errors"]:
        print(f"\n  Errors ({len(stats['errors'])}):")
        for err in stats["errors"][:20]:
            print(f"    - {err}")
        if len(stats["errors"]) > 20:
            print(f"    ... and {len(stats['errors']) - 20} more")

    # Directory summary
    print("\n  Output structure:")
    for d in sorted(OUTPUT.iterdir()):
        if d.is_dir():
            count = sum(1 for _ in d.rglob("*") if _.is_file())
            print(f"    {d.name}/: {count} files")


# ──────────────────────────────────────────────────────────────
# Main
# ──────────────────────────────────────────────────────────────

def main():
    print("Tag Force Evolution - Complete Asset Extraction Pipeline")
    print(f"Source: {EXTRACTED}")
    print(f"Output: {OUTPUT}")

    if not EXTRACTED.exists():
        print(f"\nERROR: Source directory not found: {EXTRACTED}")
        print("Run the EHP/ISO extraction first to populate assets/extracted/")
        sys.exit(1)

    start_time = time.time()

    # Clean output directory
    if OUTPUT.exists():
        print(f"\nCleaning existing output: {OUTPUT}")
        shutil.rmtree(OUTPUT)

    step_decompress_ehp_gz()
    step_extract_ehp()
    step_organize_assets()

    elapsed = time.time() - start_time
    print(f"\n  Elapsed time: {elapsed:.1f}s")

    step_report()


if __name__ == "__main__":
    main()
