"""Observe prompt colors from real Fish output without loading a live shell."""

import importlib.util
import json
import os
import re
import subprocess
import sys
import tempfile
from pathlib import Path

PROBE = r"""
source $argv[1]
set -g fish_term24bit 1
set -e fish_pager_color_description
if test -n "$argv[2]"
    source $argv[2]
end
function prompt_pwd
    printf PROMPT_PATH
end
function date
    printf '12:34'
end
cd $argv[3]
true
fish_prompt
printf '\n'
fish_right_prompt
printf '\n'
false
fish_prompt
printf '\n'
"""


def main() -> None:
    fish, config = sys.argv[1:]
    tests = Path(__file__).resolve().parent
    spec = importlib.util.spec_from_file_location("terminal_colors", tests / "tmux-colors.py")
    if spec is None or spec.loader is None:
        raise RuntimeError("cannot load the terminal color observer")
    observer = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(observer)

    with tempfile.TemporaryDirectory(prefix="fish-prompt-") as temporary:
        root = Path(temporary)
        home = root / "home"
        home.mkdir()
        env = {
            **os.environ,
            "HOME": str(home),
            "XDG_CONFIG_HOME": str(home / ".config"),
            "XDG_DATA_HOME": str(home / ".local/share"),
            "XDG_CACHE_HOME": str(home / ".cache"),
            "GIT_CONFIG_GLOBAL": str(home / ".gitconfig"),
            "GIT_CONFIG_NOSYSTEM": "1",
            "TERM": "xterm-256color",
            "COLORTERM": "truecolor",
            "TMUX": "",
            "TMUX_PANE": "",
        }
        repository = root / "project"
        subprocess.run(["git", "init", "-q", str(repository)], env=env, check=True)
        subprocess.run(
            ["git", "-C", str(repository), "symbolic-ref", "HEAD", "refs/heads/PROMPT_BRANCH"],
            env=env,
            check=True,
        )
        configured = root / "configured.fish"
        configured.write_text("set -g fish_pager_color_description abcdef\n")
        profiles: list[tuple[str, Path | None, str | None]] = [
            ("fallback", None, None),
            ("configured", configured, "#abcdef"),
        ]
        if runtime := os.environ.get("FLUME_RUNTIME"):
            for schema in ("dusk", "opal", "mira", "mesa"):
                extras = Path(runtime) / "extras"
                colors = json.loads((extras / f"palette/flume-{schema}.json").read_text())["colors"]
                profiles.append((schema, extras / f"fish/flume-{schema}.fish", colors["muted"]))
                if observer.contrast(colors["muted"], colors["bg"]) < 4.5:
                    raise ValueError(f"{schema}: prompt metadata must retain text contrast")

        for name, fragment, metadata in profiles:
            result = subprocess.run(
                [
                    fish,
                    "--no-config",
                    "-c",
                    PROBE,
                    "--",
                    config,
                    str(fragment or ""),
                    str(repository),
                ],
                env=env,
                text=True,
                capture_output=True,
                check=True,
                timeout=15,
            )
            plain = re.sub(r"\x1b\[[0-?]*[ -/]*[@-~]|\x1b\([A-Z]", "", result.stdout)
            host = re.search(r"(?m)^\[([^\n]+?)\]", plain)
            if host is None:
                raise ValueError(f"{name}: prompt omitted its host label")
            observer.assert_ink(result.stdout, host[0], metadata, None)
            observer.assert_ink(result.stdout, "12:34", metadata, None)
            observer.assert_ink(result.stdout, "PROMPT_BRANCH", None, None)
            observer.assert_ink(result.stdout, "PROMPT_PATH", "ansi:34", None)
            observer.assert_ink(result.stdout, "$", None, None)
            observer.assert_ink(result.stdout, "$", "ansi:31", None)
            print(f"PASS: {name} prompt metadata, path, branch and failed-exit colors")


if __name__ == "__main__":
    main()
