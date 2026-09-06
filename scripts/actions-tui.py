#!/usr/bin/env python3
"""Minimal GitHub Actions dashboard for the tmux Actions role window.

One row per (workflow, branch): the current run and the previous run, each
with start time, length, status, and commit. Current lengths tick live between
polls. Data comes from `gh run list`, so authentication and repo resolution
follow the GitHub CLI. Themes follow the Flume tracker suite when available.
"""

from __future__ import annotations

import json
import os
import subprocess
import sys
import webbrowser
from datetime import datetime, timezone
from pathlib import Path

from rich.text import Text
from textual import work
from textual.app import App, ComposeResult
from textual.screen import ModalScreen
from textual.widgets import DataTable, Footer, Static

try:
    from flume_tracker_theme import (
        active_flume_theme,
        load_flume_themes,
        theme_roles,
        watch_flume_theme_changes,
    )
except ImportError:  # Flume bridge is optional; fall back to built-in themes.
    active_flume_theme = None
    load_flume_themes = None
    theme_roles = None
    watch_flume_theme_changes = None

RUN_FIELDS = (
    "databaseId,workflowName,headBranch,headSha,status,conclusion,"
    "startedAt,updatedAt,createdAt"
)
VIEW_FIELDS = (
    "displayTitle,url,workflowName,headBranch,headSha,status,conclusion,"
    "createdAt,startedAt,updatedAt,jobs"
)
POLL_SECONDS = 20
TICK_SECONDS = 1
ROW_LIMIT = 100
MAX_ROWS = 40

# status/conclusion -> (theme role, ANSI fallback, glyph)
STATUS_STYLE = {
    "success": ("success", "green", "✓"),
    "failure": ("error", "red", "✗"),
    "startup_failure": ("error", "red", "✗"),
    "cancelled": ("text_muted", "dim", "⊘"),
    "skipped": ("text_muted", "dim", "◦"),
    "in_progress": ("warning", "yellow", "●"),
    "queued": ("warning", "yellow", "○"),
    "waiting": ("warning", "yellow", "○"),
    "requested": ("warning", "yellow", "○"),
    "pending": ("warning", "yellow", "○"),
}


def repo_from_git(cwd: str) -> str | None:
    try:
        url = subprocess.run(
            ["git", "-C", cwd, "remote", "get-url", "origin"],
            capture_output=True,
            text=True,
            check=True,
            timeout=5,
        ).stdout.strip()
    except (OSError, subprocess.SubprocessError):
        return None
    for prefix in ("git@github.com:", "ssh://git@github.com/", "https://github.com/"):
        if url.startswith(prefix):
            path = url[len(prefix) :]
            break
    else:
        return None
    return path.removesuffix(".git")


def gh_json(args: list[str], timeout: int = 30) -> dict | list:
    out = subprocess.run(
        ["gh", *args],
        capture_output=True,
        text=True,
        check=True,
        timeout=timeout,
    ).stdout
    return json.loads(out)


def parse_time(value: str | None) -> datetime | None:
    if not value:
        return None
    return datetime.fromisoformat(value.replace("Z", "+00:00"))


def length_label(start: datetime, end: datetime) -> str:
    seconds = max(0, int((end - start).total_seconds()))
    minutes, sec = divmod(seconds, 60)
    hours, minutes = divmod(minutes, 60)
    if hours:
        return f"{hours}:{minutes:02d}:{sec:02d}"
    return f"{minutes:02d}:{sec:02d}"


def run_length(run: dict, now: datetime) -> str | None:
    start = parse_time(run.get("startedAt"))
    if start is None:
        return None
    if run.get("status") == "completed":
        end = parse_time(run.get("updatedAt")) or now
    else:
        end = now
    return length_label(start, end)


def start_label(run: dict, now: datetime) -> str:
    start = parse_time(run.get("startedAt") or run.get("createdAt"))
    if start is None:
        return "—"
    local = start.astimezone()
    if local.date() == now.astimezone().date():
        return local.strftime("%H:%M")
    return local.strftime("%m-%d %H:%M")


def dash() -> Text:
    return Text("—", style="dim")


class RunDetailScreen(ModalScreen):
    """Run details: metadata plus per-job status. `l` tails logs in a pager."""

    BINDINGS = [
        ("escape", "close", "Close"),
        ("enter", "close", "Close"),
        ("l", "logs", "Logs"),
        ("o", "open_url", "Open"),
    ]

    CSS = """
    RunDetailScreen {
        align: center middle;
    }
    #detail {
        width: 100%;
        max-width: 120;
        height: auto;
        max-height: 80%;
        padding: 1 2;
        border: round $border-blurred;
        background: $surface;
    }
    """

    def __init__(self, repo: str, run: dict, colorize) -> None:
        super().__init__()
        self.repo = repo
        self.run = run
        self.colorize = colorize
        self.url: str | None = None

    def compose(self) -> ComposeResult:
        yield Static("loading run details…", id="detail")

    def on_mount(self) -> None:
        self.fetch_detail()

    @work(thread=True, exclusive=True, group="detail")
    def fetch_detail(self) -> None:
        try:
            data = gh_json(
                ["run", "view", str(self.run["databaseId"]), "--repo", self.repo,
                 "--json", VIEW_FIELDS],
                timeout=60,
            )
            error = None
        except (OSError, subprocess.SubprocessError, ValueError) as exc:
            data, error = None, str(exc).strip().splitlines()[-1]
        self.app.call_from_thread(self.apply_detail, data, error)

    def apply_detail(self, data: dict | None, error: str | None) -> None:
        widget = self.query_one("#detail", Static)
        now = datetime.now(timezone.utc)
        if error or data is None:
            widget.update(f"[b]gh failed[/b]\n{error or 'unknown error'}")
            return
        self.url = data.get("url")
        lines = [f"[b]{data.get('displayTitle') or self.run.get('workflowName', 'run')}[/b]"]
        lines.append(
            f"{data.get('workflowName', '?')} · {data.get('headBranch', '?')} · "
            f"{start_label(data, now)} → {run_length(data, now) or '—'} · "
            f"{(data.get('headSha') or '')[:7]}"
        )
        previous = self.run.get("previous")
        if previous:
            lines.append(
                f"prev: {previous.get('workflowName', '?')} · "
                f"{start_label(previous, now)} → {run_length(previous, now) or '—'} · "
                f"{(previous.get('headSha') or '')[:7]}"
            )
        lines.append("")
        lines.append("[b]jobs[/b]")
        jobs = data.get("jobs") or []
        if not jobs:
            lines.append("(no job data)")
        for job in jobs:
            conclusion = job.get("conclusion") or job.get("status") or "?"
            role, fallback, glyph = STATUS_STYLE.get(
                conclusion, ("accent", "magenta", conclusion[:3])
            )
            start = parse_time(job.get("startedAt"))
            if start is None:
                span = "—"
            elif job.get("status") == "completed":
                end = parse_time(job.get("completedAt")) or now
                span = length_label(start, end)
            else:
                span = length_label(start, now)
            name = job.get("name") or "?"
            lines.append(
                f"  [{self.colorize(role, fallback)}]{glyph}[/{self.colorize(role, fallback)}]"
                f" {name:<40} {span}"
            )
        widget.update("\n".join(lines))

    def action_close(self) -> None:
        self.dismiss()

    def action_open_url(self) -> None:
        if self.url:
            webbrowser.open(self.url)

    def action_logs(self) -> None:
        pager = os.environ.get("PAGER", "less -R")
        command = (
            f"gh run view {self.run['databaseId']} --repo {self.repo} --log | {pager}"
        )
        with self.app.suspend():
            subprocess.run(command, shell=True)


class ActionsDashboard(App):
    TITLE = "actions"
    CSS = """
    DataTable { height: 1fr; }
    """
    BINDINGS = [
        ("q", "quit", "Quit"),
        ("h", "cursor_left", "Left"),
        ("j", "cursor_down", "Down"),
        ("k", "cursor_up", "Up"),
        ("l", "cursor_right", "Right"),
        ("enter", "detail", "Details"),
        ("o", "open_run", "Open"),
    ]

    def __init__(self, repo: str) -> None:
        super().__init__()
        self.repo = repo
        self.runs: list[dict] = []
        self.row_runs: list[tuple[dict, dict | None]] = []
        self.error: str | None = None
        self._roles: dict[str, str] = {}

    def compose(self) -> ComposeResult:
        table = DataTable(id="runs")
        table.cursor_type = "row"
        table.add_columns(
            "workflow",
            "branch",
            *("start", "length", "st", "commit"),
            *("prev start", "prev length", "prev st", "prev commit"),
        )
        yield table
        yield Footer()

    # ---- theming -----------------------------------------------------------

    def apply_theme(self) -> None:
        roles = theme_roles(self.theme) if theme_roles else None
        self._roles = roles or {}

    def color(self, role: str, fallback: str) -> str:
        return self._roles.get(role, fallback)

    @work(exclusive=True, group="flume-theme")
    async def watch_flume_theme(self) -> None:
        if not watch_flume_theme_changes:
            return
        async for name in watch_flume_theme_changes():
            if name in self.available_themes and name != self.theme:
                self.theme = name

    def on_mount(self) -> None:
        self._table().focus()
        if load_flume_themes:
            for theme in load_flume_themes("actions"):
                self.register_theme(theme)
        chosen = None
        if active_flume_theme:
            chosen = active_flume_theme()
        if chosen not in self.available_themes:
            flume = [
                name
                for name in self.available_themes
                if name.startswith("flume-")
            ]
            chosen = flume[0] if flume else self.theme
        self.theme = chosen
        self.apply_theme()
        self.watch_flume_theme()
        self.set_interval(TICK_SECONDS, self.refresh_rows)
        self.set_interval(POLL_SECONDS, self.poll)
        self.poll()

    # ---- data --------------------------------------------------------------

    def poll(self) -> None:
        self.fetch_runs()

    @work(thread=True, exclusive=True, group="poll")
    def fetch_runs(self) -> None:
        try:
            runs = gh_json(
                ["run", "list", "--repo", self.repo, "--json", RUN_FIELDS,
                 "--limit", str(ROW_LIMIT)]
            )
            error = None
        except (OSError, subprocess.SubprocessError, ValueError) as exc:
            runs, error = [], str(exc).strip().splitlines()[-1] if str(exc) else "gh failed"
        self.app.call_from_thread(self.apply_runs, runs, error)

    def apply_runs(self, runs: list[dict], error: str | None) -> None:
        self.runs = runs
        self.error = error
        self.refresh_rows()

    def refresh_rows(self) -> None:
        table = self.query_one("#runs", DataTable)
        now = datetime.now(timezone.utc)
        cursor_row, cursor_column = table.cursor_row, table.cursor_column
        table.clear()
        self.row_runs = self.group_runs(self.runs)
        for current, previous in self.row_runs:
            table.add_row(
                Text(current.get("workflowName") or "?"),
                Text(current.get("headBranch") or "?", style=self.color("accent", "cyan")),
                *self.run_cells(current, now),
                *self.run_cells(previous, now),
            )
        if self.row_runs:
            table.move_cursor(
                row=min(cursor_row, len(self.row_runs) - 1),
                column=cursor_column,
                animate=False,
                scroll=True,
            )
        if self.error:
            self.sub_title = f"{self.repo} — {self.error}"
        elif self.runs:
            self.sub_title = f"{self.repo} — {len(self.runs)} recent runs"
        else:
            self.sub_title = f"{self.repo} — no workflow runs"

    def group_runs(self, runs: list[dict]) -> list[tuple[dict, dict | None]]:
        """Group runs by (workflow, branch); first hit is current, second previous."""
        seen: dict[tuple[str, str], dict] = {}
        order: list[tuple[str, str]] = []
        for run in runs:
            key = (run.get("workflowName") or "?", run.get("headBranch") or "?")
            if key not in seen:
                seen[key] = {"current": run}
                order.append(key)
            elif "previous" not in seen[key]:
                seen[key]["previous"] = run

        def sort_key(key: tuple[str, str]) -> tuple:
            current = seen[key]["current"]
            active = 0 if current.get("status") == "completed" else 1
            start = parse_time(current.get("startedAt") or current.get("createdAt"))
            stamp = start.timestamp() if start else 0
            return (active, stamp)

        order.sort(key=sort_key, reverse=True)
        return [
            (seen[key]["current"], seen[key].get("previous")) for key in order[:MAX_ROWS]
        ]

    # ---- cells -------------------------------------------------------------

    def status_cell(self, run: dict) -> Text:
        status = run.get("status") or "unknown"
        conclusion = run.get("conclusion")
        role, fallback, glyph = STATUS_STYLE.get(
            conclusion or status, ("accent", "magenta", (conclusion or status)[:3])
        )
        return Text(glyph, style=self.color(role, fallback))

    def run_cells(self, run: dict | None, now: datetime) -> list[Text]:
        if run is None:
            return [dash(), dash(), dash(), dash()]
        length = run_length(run, now)
        return [
            Text(start_label(run, now)),
            Text(length) if length else dash(),
            self.status_cell(run),
            Text((run.get("headSha") or "")[:7], style=self.color("text_muted", "dim"))
            if run.get("headSha")
            else dash(),
        ]

    # ---- actions -----------------------------------------------------------

    def _table(self) -> DataTable:
        return self.query_one("#runs", DataTable)

    def action_cursor_down(self) -> None:
        self._table().action_cursor_down()

    def action_cursor_up(self) -> None:
        self._table().action_cursor_up()

    def action_cursor_left(self) -> None:
        self._table().action_cursor_left()

    def action_cursor_right(self) -> None:
        self._table().action_cursor_right()

    def selected_group(self) -> tuple[dict, dict | None] | None:
        row = self._table().cursor_row
        if 0 <= row < len(self.row_runs):
            return self.row_runs[row]
        return None

    def action_detail(self) -> None:
        group = self.selected_group()
        if group:
            current, previous = group
            payload = dict(current)
            payload["previous"] = previous
            self.push_screen(RunDetailScreen(self.repo, payload, self.color))

    def on_data_table_row_selected(self) -> None:
        self.action_detail()

    def action_open_run(self) -> None:
        group = self.selected_group()
        if group and group[0].get("url"):
            webbrowser.open(group[0]["url"])


def main() -> None:
    args = sys.argv[1:]
    repo = None
    if "--repo" in args:
        repo = args[args.index("--repo") + 1]
    if not repo:
        repo = repo_from_git(str(Path.cwd()))
    if not repo:
        print("actions-tui: no --repo and no git origin remote", file=sys.stderr)
        raise SystemExit(1)
    ActionsDashboard(repo).run()


if __name__ == "__main__":
    main()
