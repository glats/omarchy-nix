"""Probe the generated launcher PATH without launching a graphical session."""
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest


class ShellAPI(unittest.TestCase):
    def test_panel_contract(self):
        prefix = Path(os.environ["QUATTRO_LAUNCHER"]).read_text().split("\nexec ", 1)[0]
        bash = shutil.which("bash")
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            ctl = root / "powerprofilesctl"
            ctl.write_text(
                f"#!{bash}\n"
                'case "$1" in\n'
                "list) printf '* balanced:\n  power-saver:\n  performance:\n';;\n"
                'set) printf "%s\\n" "$2" > "$PROBE_STATE";;\n'
                "esac\n"
            )
            ctl.chmod(0o755)
            env = dict(os.environ, HOME=tmp, PATH=f"{tmp}:{os.environ['PATH']}",
                       PROBE_STATE=str(root / "selected"),
                       OMARCHY_POWERPROFILES_STATE_DIR=str(root / "profiles"))

            def run(command):
                result = subprocess.run([bash, "-c", prefix + "\n" + command],
                                        env=env, capture_output=True, text=True)
                self.assertEqual((result.returncode, result.stderr), (0, ""))
                return result.stdout

            self.assertEqual(run("omarchy-powerprofiles-list --active-state"),
                             "performance\t0\npower-saver\t0\nbalanced\t1\n")
            run("omarchy-powerprofiles-set battery power-saver")
            self.assertEqual((root / "selected").read_text(), "power-saver\n")
            for executable in ("pactl", "xkbcli"):
                self.assertTrue(run(f"command -v {executable}").startswith("/nix/store/"))


if __name__ == "__main__":
    unittest.main()
