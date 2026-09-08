import contextlib
import importlib.util
import io
import json
import subprocess
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

spec = importlib.util.spec_from_file_location(
    "install_style", Path(__file__).with_name("install-style.py")
)
installer = importlib.util.module_from_spec(spec)
spec.loader.exec_module(installer)


class InstallStyleTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.profile = Path(self.temp.name)
        (self.profile / "prefs.js").write_text(
            'user_pref("mail.accountmanager.accounts", "personal");\n'
            'user_pref("mail.dark-reader.enabled", false);\n'
            'user_pref("mail.threadpane.cardsview.rowcount", 3);\n'
        )
        (self.profile / "chrome").mkdir()
        self.original_css = '@charset "UTF-8";\n/* custom */\n.keep { color: red; }\n'
        (self.profile / "chrome/userChrome.css").write_text(self.original_css)
        self.state = {
            "chrome://messenger/content/messenger.xhtml": {
                "unifiedToolbar": {"state": json.dumps({"mail": ["search-bar", "ext-another-addon", "ext-quickmove@mozilla.kewis.ch"], "calendar": ["spacer"]})},
                "messageHeader": {"layout": '{"customOption": true}'},
            },
            "about:message": {"header-view-toolbar": {"currentset":
                "another-addon,quickmove_mozilla_kewis_ch-messageDisplayAction-toolbarbutton"}},
        }
        (self.profile / "xulstore.json").write_text(json.dumps(self.state))

    def install(self, running=False):
        result = subprocess.CompletedProcess([], 0 if running else 1)
        with patch.object(installer.subprocess, "run", return_value=result), contextlib.redirect_stdout(io.StringIO()):
            installer.install(self.profile)

    def test_preserves_unrelated_settings_and_existing_css(self):
        self.install()
        prefs = (self.profile / "prefs.js").read_text()
        self.assertIn('"mail.accountmanager.accounts", "personal"', prefs)
        self.assertIn('"mail.dark-reader.enabled", false', prefs)
        self.assertIn('"mail.threadpane.cardsview.rowcount", 2', prefs)
        css = (self.profile / "chrome/userChrome.css").read_text()
        self.assertTrue(css.startswith('@charset "UTF-8";'))
        self.assertIn('.keep { color: red; }', css)
        state = json.loads((self.profile / "xulstore.json").read_text())
        main = state["chrome://messenger/content/messenger.xhtml"]
        self.assertEqual(json.loads(main["unifiedToolbar"]["state"]), {"mail": ["search-bar", "ext-another-addon"], "calendar": ["spacer"]})
        self.assertTrue(json.loads(main["messageHeader"]["layout"])["customOption"])
        self.assertEqual(state["about:message"], self.state["about:message"])
        backups = list((self.profile / "solarized-style-backups").glob("*/chrome/userChrome.css"))
        self.assertEqual(backups[0].read_text(), self.original_css)

    def test_repeat_install_does_not_duplicate_imports_or_preferences(self):
        self.install()
        self.install()
        for name in ["userChrome.css", "userContent.css"]:
            self.assertEqual((self.profile / "chrome" / name).read_text().count('@import url("solarized-ui.css");'), 1)
        self.assertEqual((self.profile / "prefs.js").read_text().count('user_pref("mail.threadpane.cardsview.rowcount"'), 1)

    def test_refuses_running_thunderbird_without_writing(self):
        before = (self.profile / "prefs.js").read_bytes()
        with self.assertRaises(SystemExit):
            self.install(running=True)
        self.assertEqual((self.profile / "prefs.js").read_bytes(), before)
        self.assertFalse((self.profile / "solarized-style-backups").exists())

    def test_invalid_layout_is_rejected_before_writing(self):
        (self.profile / "xulstore.json").write_text("invalid JSON")
        before = (self.profile / "prefs.js").read_bytes()
        with self.assertRaises(json.JSONDecodeError):
            self.install()
        self.assertEqual((self.profile / "prefs.js").read_bytes(), before)
        self.assertEqual((self.profile / "chrome/userChrome.css").read_text(), self.original_css)


if __name__ == "__main__":
    unittest.main()
