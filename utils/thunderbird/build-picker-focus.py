#!/usr/bin/env python3
"""Package the Quick Folder Move focus fix from its tracked source."""
import argparse
import json
import zipfile
from pathlib import Path


def build(output):
    source = Path(__file__).resolve().parent / "picker-focus"
    files = ["manifest.json", "schema.json", "background.js", "api.js"]
    contents = {name: (source / name).read_bytes() for name in files}
    for name in ["manifest.json", "schema.json"]:
        json.loads(contents[name])
    output.parent.mkdir(parents=True, exist_ok=True)
    with zipfile.ZipFile(output, "w") as archive:
        for name, data in contents.items():
            entry = zipfile.ZipInfo(name, date_time=(1980, 1, 1, 0, 0, 0))
            entry.compress_type = zipfile.ZIP_DEFLATED
            entry.create_system = 3
            entry.external_attr = 0o100644 << 16
            archive.writestr(entry, data)
    print(output)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--output", type=Path,
        default=Path(__file__).resolve().parent / "build" / "quickmove-focus.xpi",
    )
    build(parser.parse_args().output)
