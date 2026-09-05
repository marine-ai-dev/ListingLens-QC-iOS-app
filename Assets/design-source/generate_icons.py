#!/usr/bin/env python3
"""
Rasterizes icon.svg into the PNG sizes required for an iOS AppIcon.appiconset.

TODO: This script could NOT be run in the cloud session that authored this repository —
no SVG rasterization tooling (rsvg-convert, ImageMagick with SVG delegate, cairosvg,
Inkscape) was available (verified: `which rsvg-convert convert inkscape` all returned
nothing, and `python3 -c "import cairosvg"` failed to import). Run this on a macOS
machine (or any machine with one of the tools below installed) before shipping.

Usage (once dependencies are available):
    pip install cairosvg      # simplest cross-platform option
    python3 generate_icons.py

Or, with ImageMagick + librsvg installed:
    for size in 20 29 40 58 60 76 80 87 120 152 167 180 1024; do
        rsvg-convert -w $size -h $size icon.svg -o "AppIcon.appiconset/icon-${size}.png"
    done
"""
import os
import sys

SIZES = [20, 29, 40, 58, 60, 76, 80, 87, 120, 152, 167, 180, 1024]
SVG_PATH = os.path.join(os.path.dirname(__file__), "icon.svg")
OUT_DIR = os.path.join(os.path.dirname(__file__), "AppIcon.appiconset")


def main():
    try:
        import cairosvg  # type: ignore
    except ImportError:
        print("cairosvg is not installed in this environment.")
        print("Install it with `pip install cairosvg` on a machine with the needed")
        print("system libraries (or use rsvg-convert / ImageMagick per the module")
        print("docstring), then re-run this script.")
        sys.exit(1)

    os.makedirs(OUT_DIR, exist_ok=True)
    for size in SIZES:
        out_path = os.path.join(OUT_DIR, f"icon-{size}.png")
        cairosvg.svg2png(url=SVG_PATH, write_to=out_path, output_width=size, output_height=size)
        print(f"Wrote {out_path}")


if __name__ == "__main__":
    main()
