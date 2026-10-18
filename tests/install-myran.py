#!/usr/bin/env python3
"""Disposable installer proof. Never writes the real HOME or installed binary."""

import hashlib
import json
import os
import runpy
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

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
            [sys.executable, str(Path(__file__).resolve()), "--run-installer", *map(str, args)],
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
        result = self.run_installer("install", self.source, protected / "myran", success=False)
        self.assertIn(f"unsafe ancestor: {unsafe}", result.stderr)
        self.assertFalse((protected / "myran").exists())
        self.env["XDG_STATE_HOME"] = str(protected / "state")
        self.run_installer("install", self.source, success=False)
        self.assertFalse(self.destination.exists())
        self.assertFalse((protected / "state").exists())

    def test_foreign_owned_or_world_writable_root_refused(self):
        installer = runpy.run_path(str(INSTALLER))
        original_stat = Path.stat
        root_info = original_stat(Path("/"))
        foreign_uid = max(0, os.getuid()) + 1

        for owner, mode in ((foreign_uid, 0o755), (0, 0o757)):
            with self.subTest(owner=owner, mode=oct(mode)):
                fields = list(root_info)
                fields[0] = (fields[0] & ~0o777) | mode
                fields[4] = owner

                def stat_with_unsafe_root(path, *args, root_fields=fields, **kwargs):
                    if path == Path("/"):
                        return os.stat_result(root_fields)
                    return original_stat(path, *args, **kwargs)

                with patch.object(Path, "stat", stat_with_unsafe_root):
                    with self.assertRaisesRegex(ValueError, "^unsafe ancestor: /$"):
                        installer["no_symlinks"](self.source)

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


def run_installer_with_trusted_root():
    original_stat = Path.stat

    def stat_with_trusted_root(path, *args, **kwargs):
        info = original_stat(path, *args, **kwargs)
        if path == Path("/"):
            # Linux Nix sandboxes leave the host-owned root UID unmapped. Model
            # a root-owned /, but keep its real permissions and all other metadata.
            fields = list(info)
            fields[4] = 0
            return os.stat_result(fields)
        return info

    sys.argv = [str(INSTALLER), *sys.argv[2:]]
    with patch.object(Path, "stat", stat_with_trusted_root):
        runpy.run_path(str(INSTALLER), run_name="__main__")


if __name__ == "__main__":
    if sys.argv[1:2] == ["--run-installer"]:
        run_installer_with_trusted_root()
    else:
        unittest.main()
