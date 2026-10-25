#!/usr/bin/env python3
"""Render tree's Git-aware file selection with tokei's per-file code counts."""

from __future__ import annotations

import argparse
import json
import os
import subprocess
import sys
import unicodedata
from dataclasses import dataclass
from pathlib import Path


@dataclass
class Row:
    label: str
    path: Path | None = None


def object_fields(value: object) -> dict[str, object]:
    if not isinstance(value, dict):
        raise ValueError("expected a JSON object")
    return value


def array_items(value: object) -> list[object]:
    if not isinstance(value, list):
        raise ValueError("expected a JSON array")
    return value


def display_name(name: str) -> str:
    return "".join(char if char.isprintable() else ascii(char)[1:-1] for char in name)


def display_width(text: str) -> int:
    return sum(
        0 if unicodedata.combining(char) else 2 if unicodedata.east_asian_width(char) in "WF" else 1
        for char in text
    )


def tree_rows(nodes: list[object], parent: Path | None = None, prefix: str = "") -> list[Row]:
    rows: list[Row] = []
    for index, value in enumerate(nodes):
        node = object_fields(value)
        if "error" in node:
            raise ValueError(f"tree: {node['error']}")
        name = node.get("name")
        if not isinstance(name, str):
            raise ValueError("tree returned an entry without a name")
        path = Path(name) if parent is None else parent / name
        last = index == len(nodes) - 1
        branch = "" if parent is None else "└── " if last else "├── "
        label = prefix + branch + display_name(name)
        if node.get("type") == "directory":
            rows.append(Row(label + "/" if not label.endswith("/") else label))
            children = array_items(node.get("contents", []))
            child_prefix = prefix + ("" if parent is None else "    " if last else "│   ")
            rows.extend(tree_rows(children, path, child_prefix))
        else:
            if node.get("type") == "link":
                label += " -> " + display_name(str(node.get("target", "")))
            rows.append(Row(label, path if node.get("type") == "file" else None))
    return rows


def code_lines(value: object) -> int:
    stats = object_fields(value)
    count = stats.get("code")
    if type(count) is not int or count < 0:
        raise ValueError("tokei returned an invalid code count")
    # Embedded languages belong to their containing file, not additional tree rows.
    blobs = object_fields(stats.get("blobs", {}))
    return count + sum(code_lines(blob) for blob in blobs.values())


def file_counts(paths: list[Path]) -> dict[Path, int]:
    counts: dict[Path, int] = {}
    # Explicit files keep counting consistent with tree's filters. Batch argv to stay
    # below OS argument limits without launching a process for every individual file.
    for start in range(0, len(paths), 128):
        result = subprocess.run(
            [
                "tokei",
                "--files",
                "--output",
                "json",
                "--hidden",
                "--no-ignore",
                "--",
                *(str(path.absolute()) for path in paths[start : start + 128]),
            ],
            check=True,
            stdout=subprocess.PIPE,
            text=True,
            encoding="utf-8",
        )
        languages = object_fields(json.loads(result.stdout))
        for language, value in languages.items():
            if language == "Total":
                continue
            reports = array_items(object_fields(value).get("reports", []))
            for report_value in reports:
                report = object_fields(report_value)
                name = report.get("name")
                if not isinstance(name, str):
                    raise ValueError("tokei returned a report without a filename")
                counts[Path(name).absolute()] = code_lines(report.get("stats"))
    return counts


def render(rows: list[Row], counts: dict[Path, int], *, color: bool) -> str:
    labels_width = max((display_width(row.label) for row in rows), default=0)
    count_width = max((len(str(count)) for count in counts.values()), default=1)
    lines: list[str] = []
    for row in rows:
        if row.path is None:
            lines.append(row.label)
            continue
        count = counts.get(row.path.absolute())
        number = str(count) if count is not None else "—"
        number = number.rjust(count_width)
        if color:
            shade = 90 if count is None or count < 200 else 33 if count < 500 else 31
            number = f"\033[{shade}m{number}\033[0m"
        padding = " " * (labels_width - display_width(row.label) + 2)
        lines.append(f"{row.label}{padding}{number} LOC")
    return "\n".join(lines)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("paths", nargs="*", default=["."])
    parser.add_argument("-a", action="store_true", help="include hidden files")
    parser.add_argument("-d", action="store_true", help="list directories only")
    parser.add_argument("-L", type=int, metavar="DEPTH", help="maximum tree depth")
    parser.add_argument("-I", metavar="PATTERN", help="exclude matching names (tree syntax)")
    parser.add_argument("-P", metavar="PATTERN", help="include matching files (tree syntax)")
    for option in ("dirsfirst", "prune"):
        parser.add_argument(f"--{option}", action="store_true")
    parser.add_argument("-r", action="store_true", help="reverse sort order")
    parser.add_argument("--color", choices=("auto", "always", "never"), default="auto")
    # Existing lt callers may already pass these tree display flags.
    parser.add_argument("-N", "--noreport", action="store_true", help=argparse.SUPPRESS)
    args = parser.parse_args()
    if args.L is not None and args.L < 1:
        parser.error("depth must be at least 1")

    command = ["tree", "--gitignore", "-J", "--noreport"]
    for flag in ("a", "d", "r"):
        if getattr(args, flag):
            command.append(f"-{flag}")
    for option in ("dirsfirst", "prune"):
        if getattr(args, option):
            command.append(f"--{option}")
    for flag in ("L", "I", "P"):
        value = getattr(args, flag)
        if value is not None:
            command.extend([f"-{flag}", str(value)])
    color = args.color == "always" or (
        args.color == "auto" and sys.stdout.isatty() and "NO_COLOR" not in os.environ
    )
    try:
        nodes: list[object] = []
        for name in args.paths:
            path = Path(name)
            # tree's JSON output for file roots is malformed in some releases.
            if path.is_symlink():
                nodes.append({"type": "link", "name": name, "target": os.readlink(path)})
            elif path.is_file():
                if not args.d:
                    nodes.append({"type": "file", "name": name})
            else:
                result = subprocess.run(
                    [*command, "--", name],
                    check=True,
                    stdout=subprocess.PIPE,
                    text=True,
                    encoding="utf-8",
                )
                nodes.extend(array_items(json.loads(result.stdout)))
        rows = tree_rows(nodes)
        counts = file_counts([row.path for row in rows if row.path is not None])
        print(render(rows, counts, color=color))
    except FileNotFoundError as error:
        print(f"lt: missing command: {error.filename}", file=sys.stderr)
        return 1
    except (subprocess.CalledProcessError, ValueError, OSError) as error:
        print(f"lt: {error}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
