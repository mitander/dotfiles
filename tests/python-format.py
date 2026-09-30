#!/usr/bin/env python3
import shutil
import subprocess
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


class PythonFormatTests(unittest.TestCase):
    def test_repository_policy_and_import_only_fixes(self):
        with tempfile.TemporaryDirectory(prefix="python-format-") as directory:
            root = Path(directory)
            subprocess.run(["git", "init", "--quiet", str(root)], check=True)
            for name in ("ruff.toml", ".prettierrc.json", ".prettierignore"):
                shutil.copyfile(ROOT / name, root / name)
            shutil.copyfile(ROOT / ".stylua.toml", root / ".stylua.toml")
            (root / "scripts").mkdir()
            shutil.copyfile(ROOT / "scripts/format.sh", root / "scripts/format.sh")
            for name in ("nvim", "tests", "home", "fish/.config/fish"):
                (root / name).mkdir(parents=True)
            (root / "nvim/example.lua").write_text("return {}\n")
            (root / "fish/.config/fish/config.fish").write_text("echo hello\n")
            (root / "flake.nix").write_text("{}\n")
            (root / ".gitignore").touch()
            source = root / "example.py"
            source.write_text(
                "import sys\nimport os\n\nvalue='hello'\nprint(os.name,sys.version)\n"
            )

            def run(mode):
                return subprocess.run(
                    ["sh", str(root / "scripts/format.sh"), mode],
                    cwd=root.parent,
                    capture_output=True,
                    text=True,
                    timeout=30,
                    check=False,
                )

            before = source.read_bytes()
            self.assertNotEqual(run("check").returncode, 0)
            self.assertEqual(source.read_bytes(), before)
            result = run("write")
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertTrue(source.read_text().startswith("import os\nimport sys\n"))
            self.assertIn('value = "hello"', source.read_text())
            self.assertEqual(run("check").returncode, 0)
            formatted = source.read_bytes()
            self.assertEqual(run("write").returncode, 0)
            self.assertEqual(source.read_bytes(), formatted)
            source.write_text(source.read_text() + "\nimport json\n")
            self.assertEqual(run("write").returncode, 0)
            self.assertIn("import json", source.read_text())
            self.assertNotEqual(run("check").returncode, 0)
            (root / "ruff.toml").unlink()
            before = source.read_bytes()
            self.assertNotEqual(run("write").returncode, 0)
            self.assertEqual(source.read_bytes(), before)


if __name__ == "__main__":
    unittest.main()
