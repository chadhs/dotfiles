#!/usr/bin/env python3
"""Restore our workspace module loader without replacing Omarchy's entrypoint."""
from pathlib import Path
from datetime import datetime
import re
import shutil
import sys

config = Path(sys.argv[1]) if len(sys.argv) > 1 else Path.home() / ".config/hypr/hyprland.lua"
text = config.read_text()
if re.search(r'^\s*require\([\"\']hypr\.workspaces[\"\']\)', text, re.M):
    print("Workspace loader already present")
else:
    anchor = 'require("hypr.monitors")'
    if text.count(anchor) != 1:
        raise SystemExit("Cannot safely locate monitor loader; add require(\"hypr.workspaces\") after monitors manually")
    backup = config.with_name(config.name + ".bak." + datetime.now().strftime("%Y%m%d-%H%M%S-%f"))
    shutil.copy2(config, backup)
    config.write_text(text.replace(anchor, anchor + '\nrequire("hypr.workspaces") -- Five persistent workspaces per monitor.'))
    print("Added workspace loader; backup:", backup)
