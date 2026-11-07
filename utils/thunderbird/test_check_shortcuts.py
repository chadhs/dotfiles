import importlib.util
import json
import tempfile
import unittest
from pathlib import Path

spec = importlib.util.spec_from_file_location("checker", Path(__file__).with_name("check-shortcuts.py"))
checker = importlib.util.module_from_spec(spec)
spec.loader.exec_module(checker)


class Checks(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.profile = Path(self.temp.name)
        self.addons = [{"id": key, "active": True, "appDisabled": False, "userDisabled": False}
                       for key in checker.REQUIRED]
        (self.profile / "prefs.js").write_text("")
        self.save()

    def save(self):
        (self.profile / "extensions.json").write_text(json.dumps({"addons": self.addons}))

    def test_active_addons_and_no_file_changes(self):
        before = {p.name: p.read_bytes() for p in self.profile.iterdir()}
        self.assertFalse(any(level == "FAIL" for level, _ in checker.inspect(self.profile)))
        self.assertEqual(before, {p.name: p.read_bytes() for p in self.profile.iterdir()})

    def test_incompatible_addon(self):
        self.addons[0].update(active=False, appDisabled=True)
        self.save()
        self.assertTrue(any(level == "FAIL" and "inactive" in message
                            for level, message in checker.inspect(self.profile)))

    def test_missing_addon(self):
        self.addons.pop()
        self.save()
        self.assertTrue(any("missing" in message for _, message in checker.inspect(self.profile)))

    def test_user_js_overrides_prefs_and_reports_no_endpoint_value(self):
        (self.profile / "prefs.js").write_text('user_pref("extensions.update.enabled", true);\n')
        (self.profile / "user.js").write_text(
            'user_pref("extensions.update.enabled", false);\n'
            'user_pref("extensions.update.url", "http://secret/extensions-dummy/updateURL");\n')
        findings = checker.inspect(self.profile)
        self.assertEqual(sum(level == "FAIL" for level, _ in findings), 2)
        self.assertNotIn("secret", str(findings))

    def test_install_default_wins_over_legacy_profile_default(self):
        root = self.profile / ".thunderbird"
        root.mkdir()
        (root / "profiles.ini").write_text(
            '[InstallABC]\nDefault=release\n[Profile0]\nPath=old\nIsRelative=1\nDefault=1\n')
        self.assertEqual(checker.default_profile(self.profile), root / "release")

    def test_ambiguous_install_defaults_require_selection(self):
        root = self.profile / ".thunderbird"
        root.mkdir()
        (root / "profiles.ini").write_text('[InstallA]\nDefault=a\n[InstallB]\nDefault=b\n')
        with self.assertRaises(ValueError):
            checker.default_profile(self.profile)


if __name__ == "__main__":
    unittest.main()
