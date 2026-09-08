#!/usr/bin/env python3
"""Install the Solarized UI refinements into an explicitly chosen, closed profile."""
import argparse
import datetime
import json
import os
import re
import shutil
import subprocess
from pathlib import Path


def install(profile):
    profile = profile.expanduser().resolve()
    prefs = profile / "prefs.js"
    if not prefs.is_file():
        raise SystemExit("Choose an existing Thunderbird profile containing prefs.js")
    running = subprocess.run(
        ["pgrep", "-u", str(os.getuid()), "-x", "thunderbird|thunderbird-bin|Thunderbird"],
        capture_output=True,
    )
    if running.returncode == 0:
        raise SystemExit("Close Thunderbird before installing the style")
    if running.returncode != 1:
        raise SystemExit("Could not check whether Thunderbird is running")
    source = Path(__file__).resolve().parent / "chrome" / "solarized-ui.css"
    css = source.read_text(encoding="utf-8")
    store = profile / "xulstore.json"
    state = json.loads(store.read_text()) if store.exists() else {}
    main = state.setdefault("chrome://messenger/content/messenger.xhtml", {})
    header = main.setdefault("messageHeader", {})
    layout = json.loads(header.get("layout", "{}"))
    toolbar = main.setdefault("unifiedToolbar", {})
    toolbar_state = json.loads(toolbar.get("state", "{}"))
    if "mail" not in toolbar_state:
        spaces = json.loads(toolbar.get("allowedExtSpaces", "{}"))
        toolbar_state["mail"] = ["spacer", "search-bar", "spacer"] + [
            "ext-" + addon for addon, allowed in spaces.items() if "mail" in allowed
        ]
    toolbar_state["mail"] = [item for item in toolbar_state["mail"]
                             if item != "ext-quickmove@mozilla.kewis.ch"]
    backup = profile / "solarized-style-backups" / datetime.datetime.now().strftime("%Y%m%d-%H%M%S-%f")
    backup.mkdir(parents=True)
    files = ["prefs.js", "xulstore.json", "chrome/userChrome.css",
             "chrome/userContent.css", "chrome/solarized-ui.css"]
    for name in files:
        path = profile / name
        if path.exists():
            target = backup / name
            target.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(path, target)

    chrome = profile / "chrome"
    chrome.mkdir(exist_ok=True)
    (chrome / "solarized-ui.css").write_text(css, encoding="utf-8")
    statement = '@import url("solarized-ui.css");'
    for name in ["userChrome.css", "userContent.css"]:
        path = chrome / name
        text = path.read_text(encoding="utf-8") if path.exists() else ""
        if statement not in text:
            charset = re.match(r'\s*@charset\s+"[^"]+"\s*;', text)
            index = charset.end() if charset else 0
            text = text[:index] + "\n" + statement + "\n" + text[index:]
            path.write_text(text, encoding="utf-8")

    text = prefs.read_text(encoding="utf-8")
    updates = {
        "toolkit.legacyUserProfileCustomizations.stylesheets": True,
        "mail.threadpane.cardsview.rowcount": 2,
        "mail.pane_config.dynamic": 2,
        "mail.threadpane.listview": 0,
    }
    for key, value in updates.items():
        text = re.sub(r"^user_pref\(" + re.escape(json.dumps(key)) + r",.*\);\n?", "", text, flags=re.M)
        text += f"user_pref({json.dumps(key)}, {json.dumps(value)});\n"
    prefs.write_text(text, encoding="utf-8")

    main.setdefault("folderPaneBox", {})["width"] = "230"
    main.setdefault("messagepaneboxwrapper", {}).update({"width": "540", "collapsed": "false"})
    layout.update({"showAvatar": False, "showBigAvatar": False,
                   "showFullAddress": True, "hideLabels": True,
                   "subjectLarge": False, "buttonStyle": "only-icons"})
    header["layout"] = json.dumps(layout)
    toolbar["state"] = json.dumps(toolbar_state)
    store.write_text(json.dumps(state), encoding="utf-8")
    print(f"Installed Solarized UI refinements. Backup: {backup}")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--profile", type=Path, required=True)
    install(parser.parse_args().profile)
