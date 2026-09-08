#!/usr/bin/env python3
"""Package the tracked adaptive Thunderbird theme using the standard library."""
import argparse
import json
import zipfile
from pathlib import Path


def build(output):
    source = Path(__file__).resolve().parent / "theme" / "manifest.json"
    manifest = json.loads(source.read_text(encoding="utf-8"))
    if manifest.get("manifest_version") != 2:
        raise ValueError("Expected a Manifest V2 static theme")
    for variant, mode in [("theme", "light"), ("dark_theme", "dark")]:
        theme = manifest[variant]
        if theme["properties"]["color_scheme"] != mode:
            raise ValueError(f"Incorrect {variant} color scheme")
        if not theme.get("colors"):
            raise ValueError(f"Missing {variant} palette")
    output.parent.mkdir(parents=True, exist_ok=True)
    entry = zipfile.ZipInfo("manifest.json", date_time=(1980, 1, 1, 0, 0, 0))
    entry.compress_type = zipfile.ZIP_DEFLATED
    entry.create_system = 3
    entry.external_attr = 0o100644 << 16
    with zipfile.ZipFile(output, "w") as archive:
        archive.writestr(entry, json.dumps(manifest, indent=2) + "\n")
    print(output)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--output",
        type=Path,
        default=Path(__file__).resolve().parent / "build" / "solarized-omarchy.xpi",
    )
    args = parser.parse_args()
    build(args.output)
