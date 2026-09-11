#!/usr/bin/env python3
"""Install one reviewed Myran binary, or roll back one exact installation receipt."""
import hashlib
import json
import os
from pathlib import Path
import stat
import sys
import tempfile


def digest(data):
    return hashlib.sha256(data).hexdigest()


def no_symlinks(path):
    if not path.is_absolute() or ".." in path.parts:
        raise ValueError("use an absolute path without '..'")
    for part in [*reversed(path.parents), path]:
        if part.is_symlink():
            raise ValueError(f"refusing symlink: {part}")
        if part != path and part.exists():
            info = part.stat()
            trusted_sticky = info.st_uid == 0 and info.st_mode & stat.S_ISVTX
            if info.st_uid not in (0, os.getuid()) or (info.st_mode & 0o022 and not trusted_sticky):
                raise ValueError(f"unsafe ancestor: {part}")


def owned_directory(path):
    no_symlinks(path)
    info = path.stat()
    if not stat.S_ISDIR(info.st_mode) or info.st_uid != os.getuid() or info.st_mode & 0o022:
        raise ValueError(f"directory must be owned and not group/world writable: {path}")


def read_binary(path):
    no_symlinks(path)
    with os.fdopen(os.open(path, os.O_RDONLY | os.O_NOFOLLOW | os.O_NONBLOCK), "rb") as source:
        info = os.fstat(source.fileno())
        if not stat.S_ISREG(info.st_mode) or info.st_uid != os.getuid():
            raise ValueError(f"binary must be a regular owned file: {path}")
        if not info.st_mode & 0o111 or info.st_mode & 0o7022:
            raise ValueError(f"binary must be executable, without special or writable group/world bits: {path}")
        return source.read(), stat.S_IMODE(info.st_mode)


def atomic_write(path, data, mode):
    owned_directory(path.parent)
    no_symlinks(path)
    descriptor, temporary = tempfile.mkstemp(prefix=".myr-", dir=path.parent)
    try:
        with os.fdopen(descriptor, "wb") as output:
            output.write(data)
            output.flush()
            os.fchmod(output.fileno(), mode)
            os.fsync(output.fileno())
        os.replace(temporary, path)
    finally:
        if os.path.exists(temporary):
            os.unlink(temporary)


def install(source, destination, state):
    data, _ = read_binary(source)
    owned_directory(destination.parent)
    no_symlinks(destination)
    previous = read_binary(destination) if destination.exists() else None
    no_symlinks(state)
    state.mkdir(parents=True, exist_ok=True, mode=0o700)
    owned_directory(state)
    receipt = Path(tempfile.mkdtemp(prefix="install-", dir=state))
    record = {"destination": str(destination), "installed_sha256": digest(data), "previous_sha256": None}
    if previous:
        old_data, old_mode = previous
        atomic_write(receipt / "myr.previous", old_data, old_mode)
        record.update(previous_sha256=digest(old_data), previous_mode=old_mode)
    atomic_write(receipt / "receipt.json", (json.dumps(record, indent=2) + "\n").encode(), 0o600)
    atomic_write(destination, data, 0o755)
    print(f"Installed SHA-256: {digest(data)}")
    print(f"Receipt: {receipt}")
    import shlex
    print(f"Rollback: python3 {shlex.quote(str(Path(__file__).absolute()))} rollback {shlex.quote(str(receipt))}")


def rollback(receipt):
    owned_directory(receipt)
    no_symlinks(receipt / "receipt.json")
    info = (receipt / "receipt.json").stat()
    if not stat.S_ISREG(info.st_mode) or info.st_uid != os.getuid() or info.st_mode & 0o022:
        raise ValueError("unsafe receipt")
    record = json.loads((receipt / "receipt.json").read_text())
    destination = Path(record["destination"])
    owned_directory(destination.parent)
    current, _ = read_binary(destination)
    if digest(current) != record["installed_sha256"]:
        raise ValueError("destination changed since install, refusing rollback")
    if record["previous_sha256"] is None:
        destination.unlink()
    else:
        previous, mode = read_binary(receipt / "myr.previous")
        if digest(previous) != record["previous_sha256"] or mode != record["previous_mode"]:
            raise ValueError("backup checksum or mode changed, refusing rollback")
        atomic_write(destination, previous, mode)
    print(f"Rolled back exactly: {destination}")


def main():
    if len(sys.argv) in (3, 4) and sys.argv[1] == "install":
        destination = Path(sys.argv[3]) if len(sys.argv) == 4 else Path.home() / ".local/bin/myr"
        state = Path(os.environ.get("XDG_STATE_HOME", str(Path.home() / ".local/state"))) / "myran/cutover"
        install(Path(sys.argv[2]), destination, state)
    elif len(sys.argv) == 3 and sys.argv[1] == "rollback":
        rollback(Path(sys.argv[2]))
    else:
        raise ValueError("usage: install-myr.py install /absolute/reviewed/myr [/absolute/destination]\n"
                         "       install-myr.py rollback /absolute/receipt-directory")


if __name__ == "__main__":
    try:
        main()
    except (OSError, ValueError, KeyError) as error:
        sys.exit(f"install-myr: {error}")
