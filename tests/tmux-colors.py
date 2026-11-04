"""Observe consumer colors from an attached client on the caller's private server."""

import argparse
import fcntl
import json
import os
import pty
import re
import select
import signal
import struct
import subprocess
import termios
import time
from pathlib import Path


def tmux(socket: str, *arguments: str) -> str:
    return subprocess.check_output(["tmux", "-L", socket, *arguments], text=True, timeout=5).strip()


def read_frame(master: int) -> str:
    chunks = []
    deadline = time.monotonic() + 3
    while time.monotonic() < deadline:
        ready, _, _ = select.select([master], [], [], 0.15 if chunks else 1)
        if not ready:
            if chunks:
                break
            continue
        chunks.append(os.read(master, 65536))
    return b"".join(chunks).decode("utf-8", errors="replace")


def assert_ink(output: str, token: str, foreground: str | None, background: str | None) -> None:
    # Native tmux emits RGB SGR on the RGB-capable client. Ignore cursor movement,
    # not color changes. Check every emitted character of the probe, not options.
    text = ""
    pairs: list[tuple[str | None, str | None]] = []
    fg = bg = None
    reverse = False
    position = 0
    for match in re.finditer(
        r"\x1b\[[0-?]*[ -/]*[@-~]|\x1b\][^\x07]*(?:\x07)|\x1b[()][A-Z0-9]", output
    ):
        fragment = output[position : match.start()]
        text += fragment
        pairs.extend([(bg, fg) if reverse else (fg, bg)] * len(fragment))
        position = match.end()
        if not match[0].startswith("\x1b[") or not match[0].endswith("m"):
            continue
        codes = [int(code or "0") for code in match[0][2:-1].split(";")]
        index = 0
        while index < len(codes):
            code = codes[index]
            index += 1
            if code == 0:
                fg = bg = None
                reverse = False
            elif code in (7, 27):
                reverse = code == 7
            elif 30 <= code <= 37 or 90 <= code <= 97:
                fg = f"ansi:{code}"
            elif 40 <= code <= 47 or 100 <= code <= 107:
                bg = f"ansi:{code}"
            elif code in (39, 49):
                if code == 39:
                    fg = None
                else:
                    bg = None
            elif code in (38, 48):
                if codes[index] != 2:
                    raise ValueError("native color probe requires RGB SGR")
                color = "#" + "".join(f"{channel:02x}" for channel in codes[index + 1 : index + 4])
                index += 4
                if code == 38:
                    fg = color
                else:
                    bg = color
    fragment = output[position:]
    text += fragment
    pairs.extend([(bg, fg) if reverse else (fg, bg)] * len(fragment))
    starts = [match.start() for match in re.finditer(re.escape(token), text)]
    if not starts:
        raise ValueError(f"native client did not render {token!r}")
    expected = (foreground, background)
    if not any(
        all(pair == expected for pair in pairs[start : start + len(token)]) for start in starts
    ):
        actual = [pairs[start : start + len(token)] for start in starts]
        raise ValueError(f"{token}: expected {expected}, observed {actual}")


def contrast(first: str, second: str) -> float:
    def luminance(color: str) -> float:
        encoded = [int(color[index : index + 2], 16) / 255 for index in (1, 3, 5)]
        linear = [
            value / 12.92 if value <= 0.04045 else ((value + 0.055) / 1.055) ** 2.4
            for value in encoded
        ]
        return sum(
            value * weight for value, weight in zip(linear, (0.2126, 0.7152, 0.0722), strict=True)
        )

    lower, upper = sorted((luminance(first), luminance(second)))
    return (upper + 0.05) / (lower + 0.05)


def check(socket: str, colors: dict[str, str]) -> None:
    if contrast(colors["accent"], colors["surface"]) < 4.5:
        raise ValueError("active-tab text must remain readable on its quiet surface")
    session = f"colors-{os.getpid()}"
    tmux(socket, "new-session", "-d", "-s", session, "sleep 300")
    tmux(socket, "set-option", "-t", session, "status-keys", "vi")
    tmux(socket, "set-option", "-s", "escape-time", "0")
    tmux(
        socket,
        "new-window",
        "-d",
        "-P",
        "-F",
        "#{window_id}",
        "-t",
        session + ":",
        "-n",
        "INACTIVE",
        "sleep 300",
    )
    tmux(socket, "rename-window", "-t", session + ":0", "ACTIVE")
    master, slave = pty.openpty()
    fcntl.ioctl(slave, termios.TIOCSWINSZ, struct.pack("HHHH", 24, 160, 0, 0))
    child = subprocess.Popen(
        ["tmux", "-u", "-L", socket, "-T", "RGB", "attach-session", "-t", session],
        stdin=slave,
        stdout=slave,
        stderr=slave,
        env={**os.environ, "TERM": "xterm-256color", "TMUX": ""},
        start_new_session=True,
    )
    os.close(slave)
    try:
        output = read_frame(master)
        tmux(socket, "refresh-client")
        output += read_frame(master)
        assert_ink(output, "INACTIVE", colors["muted"], colors["bg"])
        assert_ink(output, "ACTIVE", colors["accent"], colors["surface"])

        tmux(socket, "display-message", "-d", "60000", "FLUME_NOTICE")
        assert_ink(read_frame(master), "FLUME_NOTICE", colors["fg"], colors["surface"])
        os.write(master, b"\x1b")
        read_frame(master)
        tmux(socket, "run-shell", "-bC", 'command-prompt -p FLUME_COMMAND ""')
        read_frame(master)
        # message-command-style is vi command mode, not prompt insertion mode.
        os.write(master, b"\x1b")
        assert_ink(read_frame(master), "FLUME_COMMAND", colors["accent"], colors["surface"])
        os.write(master, b"\x03")
        read_frame(master)

        split = tmux(
            socket,
            "split-window",
            "-h",
            "-d",
            "-P",
            "-F",
            "#{pane_id}",
            "-t",
            session + ":0",
            "sleep 300",
        )
        try:
            tmux(socket, "resize-pane", "-Z", "-t", session + ":0")
            tmux(socket, "copy-mode", "-t", session + ":0")
            read_frame(master)
            tmux(socket, "refresh-client")
            output = read_frame(master)
            assert_ink(output, "zoom", colors["on_accent"], colors["yellow"])
            assert_ink(output, "0/0", colors["muted"], colors["bg"])
            tmux(socket, "send-keys", "-X", "-t", session + ":0", "cancel")
            tmux(socket, "resize-pane", "-Z", "-t", session + ":0")
        finally:
            tmux(socket, "kill-pane", "-t", split)
    finally:
        child.send_signal(signal.SIGTERM)
        try:
            child.wait(timeout=3)
        except subprocess.TimeoutExpired:
            child.kill()
            child.wait()
        os.close(master)
        tmux(socket, "kill-session", "-t", session)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("socket")
    parser.add_argument("palette", type=Path)
    arguments = parser.parse_args()
    colors = json.loads(arguments.palette.read_text())["colors"]
    check(arguments.socket, colors)
    print(f"PASS: native Tmux colors for {arguments.palette.stem}")


if __name__ == "__main__":
    main()
