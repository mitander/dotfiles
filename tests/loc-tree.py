#!/usr/bin/env python3
"""Check the LOC tree through its CLI with real tree and tokei processes."""

from __future__ import annotations

import os
import re
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

SCRIPT = Path(__file__).resolve().parents[1] / "scripts/loc-tree.py"


class LocTreeTests(unittest.TestCase):
    def setUp(self) -> None:
        temporary = tempfile.TemporaryDirectory()
        self.addCleanup(temporary.cleanup)
        self.root = Path(temporary.name)
        subprocess.run(["git", "init", "-q", str(self.root)], check=True)
        (self.root / ".gitignore").write_text("ignored/\n", encoding="utf-8")
        (self.root / "ignored").mkdir()
        (self.root / "ignored/artifact.py").write_text("x = 1\n", encoding="utf-8")
        (self.root / "nested").mkdir()
        (self.root / "small.py").write_text("# comment\n\nx = 1\n", encoding="utf-8")
        (self.root / "nested/name with spaces.py").write_text("x = 1\n" * 200, encoding="utf-8")
        (self.root / "large.py").write_text("x = 1\n" * 500, encoding="utf-8")
        (self.root / "unknown.xyz").write_text("not a known language\n", encoding="utf-8")
        (self.root / ".hidden.py").write_text("x = 1\n", encoding="utf-8")

    def run_tree(
        self, *args: str, env: dict[str, str] | None = None
    ) -> subprocess.CompletedProcess[str]:
        return subprocess.run(
            [sys.executable, str(SCRIPT), *args],
            cwd=self.root,
            env=env,
            capture_output=True,
            text=True,
            encoding="utf-8",
            check=False,
        )

    def test_actual_code_counts_share_one_right_aligned_column(self) -> None:
        result = self.run_tree()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(
            result.stdout,
            "./\n"
            "├── large.py                 500 LOC\n"
            "├── nested/\n"
            "│   └── name with spaces.py  200 LOC\n"
            "├── small.py                   1 LOC\n"
            "└── unknown.xyz                — LOC\n",
        )
        self.assertNotIn("\033", result.stdout)

    def test_colors_and_thresholds_do_not_change_alignment(self) -> None:
        (self.root / "gray.py").write_text("x = 1\n" * 199, encoding="utf-8")
        (self.root / "yellow.py").write_text("x = 1\n" * 499, encoding="utf-8")
        colored = self.run_tree("--color", "always")
        self.assertEqual(colored.returncode, 0, colored.stderr)
        self.assertIn("\033[90m199\033[0m LOC", colored.stdout)
        self.assertIn("\033[33m200\033[0m LOC", colored.stdout)
        self.assertIn("\033[33m499\033[0m LOC", colored.stdout)
        self.assertIn("\033[31m500\033[0m LOC", colored.stdout)
        plain = re.sub(r"\x1b\[[0-9;]*m", "", colored.stdout)
        self.assertEqual(plain, self.run_tree("--color", "never").stdout)

    def test_unicode_names_use_terminal_columns(self) -> None:
        (self.root / "界.py").write_text("x = 1\n", encoding="utf-8")
        (self.root / "e\u0301.py").write_text("x = 1\n", encoding="utf-8")
        result = self.run_tree("--prune", "-P", "界.py|é.py")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn(" é.py   1 LOC\n", result.stdout)
        self.assertIn(" 界.py  1 LOC\n", result.stdout)

    def test_depth_filters_hidden_files_and_literal_roots(self) -> None:
        result = self.run_tree("-L", "1", "-P", "*.py")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertNotIn("name with spaces", result.stdout)
        self.assertNotIn("unknown", result.stdout)
        self.assertNotIn("ignored", result.stdout)
        self.assertNotIn(".hidden", result.stdout)
        self.assertIn(".hidden.py", self.run_tree("-a", "-L", "1").stdout)
        literal = "source dir;$(touch BAD)"
        (self.root / literal).mkdir()
        (self.root / literal / "file.py").write_text("x = 1\n", encoding="utf-8")
        result = self.run_tree("--", literal)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertRegex(result.stdout, r"file\.py +1 LOC")
        self.assertFalse((self.root / "BAD").exists())

    def test_multiple_roots_symlinks_and_empty_directories(self) -> None:
        (self.root / "empty").mkdir()
        (self.root / "link.py").symlink_to("small.py")
        result = self.run_tree("small.py", "large.py", "empty", "link.py")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("small.py               1 LOC", result.stdout)
        self.assertIn("large.py             500 LOC", result.stdout)
        self.assertIn("empty/\n", result.stdout)
        self.assertIn("link.py -> small.py\n", result.stdout)

    def test_embedded_languages_and_batched_files_are_counted_once(self) -> None:
        (self.root / "page.html").write_text(
            "<html>\n<script>\n// comment\nconst x = 1;\n</script>\n</html>\n",
            encoding="utf-8",
        )
        for index in range(130):
            (self.root / f"batch-{index:03}.py").write_text("x = 1\n", encoding="utf-8")
        result = self.run_tree("-P", "batch-*.py|page.html", "--prune")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout.count(" LOC\n"), 131)
        self.assertEqual(len(re.findall(r"batch-\d{3}\.py +1 LOC", result.stdout)), 130)
        self.assertRegex(result.stdout, r"page\.html +5 LOC")

    def test_failures_do_not_print_a_partial_tree(self) -> None:
        result = self.run_tree("missing-directory")
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(result.stdout, "")
        result = self.run_tree("-L", "0")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("depth must be at least 1", result.stderr)
        env = dict(os.environ, PATH="")
        result = self.run_tree(env=env)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("missing command: tree", result.stderr)


if __name__ == "__main__":
    unittest.main()
