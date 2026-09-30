#!/usr/bin/env python3
"""Disposable installer proof. Never writes the real HOME or installed binary."""

import hashlib
import json
import os
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

INSTALLER = Path(__file__).resolve().parents[1] / "scripts/install-myran.py"


class InstallTest(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory(prefix="install-myran-test-")
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name).resolve()
        self.home = self.root / "home"
        self.destination = self.home / ".local/bin/myran"
        self.destination.parent.mkdir(parents=True)
        self.source = self.root / "candidate"
        self.source.write_bytes(b"#!/bin/sh\nexit 0\n")
        self.source.chmod(0o700)
        self.env = dict(
            os.environ,
            HOME=str(self.home),
            XDG_STATE_HOME=str(self.home / ".local/state"),
        )

    def run_installer(self, *args, success=True):
        result = subprocess.run(
            [sys.executable, str(INSTALLER), *map(str, args)],
            env=self.env,
            text=True,
            capture_output=True,
        )
        self.assertEqual(result.returncode == 0, success, result.stdout + result.stderr)
        return result

    def receipt(self):
        return next((self.home / ".local/state/myran/cutover").glob("install-*"))

    def test_replace_and_exact_rollback(self):
        self.destination.write_bytes(b"old binary")
        self.destination.chmod(0o700)
        self.run_installer("install", self.source)
        receipt = self.receipt()
        record = json.loads((receipt / "receipt.json").read_text())
        self.assertEqual(record["previous_sha256"], hashlib.sha256(b"old binary").hexdigest())
        self.assertEqual(self.destination.read_bytes(), self.source.read_bytes())
        self.assertEqual(receipt.stat().st_mode & 0o777, 0o700)
        self.run_installer("rollback", receipt)
        self.assertEqual(self.destination.read_bytes(), b"old binary")
        self.assertEqual(self.destination.stat().st_mode & 0o777, 0o700)

    def test_new_install_and_changed_destination_guard(self):
        self.run_installer("install", self.source, self.destination)
        self.destination.write_bytes(b"unrelated update")
        self.run_installer("rollback", self.receipt(), success=False)
        self.assertEqual(self.destination.read_bytes(), b"unrelated update")
        self.destination.write_bytes(self.source.read_bytes())
        self.run_installer("rollback", self.receipt())
        self.assertFalse(self.destination.exists())

    def test_symlinks_and_special_files_refused(self):
        linked_source = self.root / "link"
        linked_source.symlink_to(self.source)
        self.run_installer("install", linked_source, success=False)
        self.destination.symlink_to(self.source)
        self.run_installer("install", self.source, success=False)
        self.destination.unlink()
        os.mkfifo(self.destination)
        self.run_installer("install", self.source, success=False)
        self.destination.unlink()
        parent_link = self.root / "bin-link"
        parent_link.symlink_to(self.destination.parent)
        self.run_installer("install", self.source, parent_link / "myran", success=False)
        self.assertFalse(self.destination.exists())

    def test_writable_ancestor_refused(self):
        unsafe = self.root / "unsafe"
        protected = unsafe / "protected"
        protected.mkdir(parents=True)
        unsafe.chmod(0o777)
        self.run_installer("install", self.source, protected / "myran", success=False)
        self.assertFalse((protected / "myran").exists())
        self.env["XDG_STATE_HOME"] = str(protected / "state")
        self.run_installer("install", self.source, success=False)
        self.assertFalse(self.destination.exists())
        self.assertFalse((protected / "state").exists())

    def test_permissions_and_corrupted_backup_refused(self):
        self.source.chmod(0o777)
        self.run_installer("install", self.source, success=False)
        self.source.chmod(0o700)
        self.destination.parent.chmod(0o777)
        self.run_installer("install", self.source, success=False)
        self.destination.parent.chmod(0o700)
        self.destination.write_bytes(b"old binary")
        self.destination.chmod(0o700)
        self.run_installer("install", self.source)
        (self.receipt() / "myr.previous").write_bytes(b"corrupt")
        self.run_installer("rollback", self.receipt(), success=False)
        self.assertEqual(self.destination.read_bytes(), self.source.read_bytes())


if __name__ == "__main__":
    unittest.main()
