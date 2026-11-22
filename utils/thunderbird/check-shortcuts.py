#!/usr/bin/env python3
"""Read-only checks for Thunderbird shortcut dependencies; never reads messages."""
import argparse
import configparser
import json
import re
from pathlib import Path

REQUIRED = {
    "tbkeys-lite@addons.thunderbird.net": "Archive and Backspace",
    "quickmove@mozilla.kewis.ch": "Move-message picker",
}


def default_profile(home):
    root = home / ".thunderbird"
    config = configparser.ConfigParser()
    config.read(root / "profiles.ini")
    installed = {config[s]["Default"] for s in config.sections()
                 if s.startswith("Install") and "Default" in config[s]}
    if len(installed) == 1:
        return root / installed.pop()
    if len(installed) > 1:
        raise ValueError("Multiple installation profiles; specify --profile")
    for section in config.sections():
        if section.startswith("Profile") and config[section].get("Default") == "1":
            path = Path(config[section]["Path"])
            return root / path if config[section].get("IsRelative", "1") == "1" else path
    return None


def preferences(profile):
    prefs = {}
    for name in ("prefs.js", "user.js"):
        file = profile / name
        if not file.exists():
            continue
        for line in file.read_text().splitlines():
            match = re.match(r'^\s*user_pref\("([^"\n]+)",\s*(.*?)\);\s*$', line)
            if match:
                prefs[match[1]] = json.loads(match[2])
    return prefs


def inspect(profile):
    findings = []
    prefs = preferences(profile)
    for key, value in prefs.items():
        if key.startswith("extensions.") and isinstance(value, str) and "extensions-dummy" in value:
            findings.append(("FAIL", f"Test endpoint override: {key}"))
    if prefs.get("extensions.update.enabled") is False:
        findings.append(("FAIL", "Thunderbird add-on updates are disabled"))
    addons = {a["id"]: a for a in json.loads((profile / "extensions.json").read_text())["addons"]}
    for addon_id, purpose in REQUIRED.items():
        addon = addons.get(addon_id)
        if not addon:
            findings.append(("FAIL", f"{purpose}: required add-on missing ({addon_id})"))
        elif addon.get("appDisabled") or addon.get("userDisabled") or not addon.get("active"):
            findings.append(("FAIL", f"{purpose}: add-on inactive ({addon_id}); check compatibility and updates"))
        else:
            findings.append(("PASS", f"{purpose}: add-on active"))
    helper = addons.get("quickmove-focus@chadhs.local")
    if helper and not helper.get("active"):
        findings.append(("WARN", "Picker-focus helper inactive; test typing before updating or retiring it"))
    return findings


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--profile", type=Path)
    args = parser.parse_args()
    try:
        profile = args.profile or default_profile(Path.home())
        if profile is None:
            print("INFO  No default Thunderbird profile; shortcut checks skipped")
            return 0
        if not (profile / "prefs.js").is_file():
            raise ValueError("Selected profile has no prefs.js")
        findings = inspect(profile)
        for level, message in findings:
            print(f"{level}  {message}")
        print("INFO  Stored add-on state checked; physical shortcuts and picker focus still require hands-on testing")
        return int(any(level == "FAIL" for level, _ in findings))
    except (OSError, ValueError, KeyError, configparser.Error) as error:
        print(f"FAIL  Cannot check Thunderbird shortcut dependencies: {error}")
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
