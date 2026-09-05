#!/usr/bin/env python3
"""Patch a pinned Pantheon tracker TUI to load and follow Flume themes."""

from __future__ import annotations

import sys
from pathlib import Path


def replace_once(source: str, old: str, new: str) -> str:
    if source.count(old) != 1:
        raise RuntimeError(f"expected one upstream match, found {source.count(old)}: {old[:80]!r}")
    return source.replace(old, new)


def main() -> None:
    app = sys.argv[1]
    path = Path(sys.argv[2])
    source = path.read_text()
    if app == "jtui":
        source = replace_once(source, "import json\n", "import json\nimport os\nimport re\n")

    source = replace_once(
        source,
        "from textual.theme import Theme\n",
        "from textual.theme import Theme\n\n"
        "from flume_tracker_theme import (\n"
        "    active_flume_theme,\n"
        "    load_flume_themes,\n"
        "    theme_palette,\n"
        "    theme_roles,\n"
        "    watch_flume_theme_changes,\n"
        ")\n",
    )
    source = replace_once(
        source,
        'def set_palette(ansi: bool) -> None:\n'
        '    """Swap the chrome palette; `system` draws it in terminal ANSI colors."""\n'
        "    globals().update(_PALETTE_ANSI if ansi else _PALETTE)\n",
        '_TRACKER_ROLES: dict[str, str] = {}\n\n\n'
        'def set_palette(theme: str) -> None:\n'
        '    """Swap the chrome palette for built-in, ANSI, or Flume themes."""\n'
        "    roles = theme_roles(theme) or {}\n"
        "    globals()[\"_TRACKER_ROLES\"] = roles\n"
        "    globals().update(theme_palette(theme) or (_PALETTE_ANSI if theme == \"system\" else _PALETTE))\n\n\n"
        "def tracker_role_color(role: str, fallback: str | None = None) -> str:\n"
        "    \"\"\"Resolve a deliberately assigned tracker role in the active theme.\"\"\"\n"
        "    return _TRACKER_ROLES.get(role, fallback or C_SUB)\n\n\n"
        "def tracker_state_color(state: dict) -> str:\n"
        "    \"\"\"Map workflow semantics onto deliberately assigned Flume roles.\"\"\"\n"
        "    role = {\n"
        "        \"triage\": \"status_triage\",\n"
        "        \"started\": \"status_started\",\n"
        "        \"unstarted\": \"status_unstarted\",\n"
        "        \"backlog\": \"status_backlog\",\n"
        "        \"completed\": \"status_completed\",\n"
        "        \"canceled\": \"status_canceled\",\n"
        "        \"duplicate\": \"status_canceled\",\n"
        "    }.get(state.get(\"type\"))\n"
        "    return tracker_role_color(role, C_SUB) if role else C_SUB\n\n\n"
        "def preferred_tracker_scope(scopes: list[dict], last_id: str | None = None) -> dict | None:\n"
        "    \"\"\"Choose the scope matching repo config, issue branch, or repository name.\"\"\"\n"
        "    def token(value: object) -> str:\n"
        "        return re.sub(r\"[^a-z0-9]\", \"\", str(value or \"\").casefold())\n\n"
        "    explicit = token(os.environ.get(\"TRACKER_SCOPE\"))\n"
        "    repository = token(os.environ.get(\"TRACKER_REPOSITORY\"))\n"
        "    for hint, fuzzy in ((explicit, False), (repository, True)):\n"
        "        if not hint:\n"
        "            continue\n"
        "        for scope in scopes:\n"
        "            candidates = (token(scope.get(\"key\")), token(scope.get(\"name\")))\n"
        "            if hint in candidates or (fuzzy and len(hint) >= 4 and any(hint in value or value in hint for value in candidates)):\n"
        "                return scope\n"
        "    return next((scope for scope in scopes if scope.get(\"id\") == last_id), None)\n",
    )
    source = replace_once(
        source,
        '    "toggle_group": (["v"], "group"),\n',
        '    "toggle_group": (["v"], "group"),\n'
        '    "toggle_sidebar": (["b"], None),\n',
    )
    source = replace_once(
        source,
        '            ("m", "toggle mine only"),\n',
        '            ("m", "toggle mine only"),\n'
        '            ("b", "toggle team sidebar"),\n',
    )
    source = replace_once(
        source,
        "                    show=bool(label) and i == 0,\n",
        "                    show=bool(label) and i == 0,\n"
        '                    priority=action == "toggle_sidebar",\n',
    )
    source = replace_once(
        source,
        '    "toggle_group": "v",\n',
        '    "toggle_group": "v",\n'
        '    "toggle_sidebar": "b",\n',
    )
    source = replace_once(
        source,
        "THEME_NAMES = [t.name for t in THEMES]\n",
        f'THEMES += load_flume_themes("{app}")\n'
        "for _theme in THEMES:\n"
        "    _chrome = theme_palette(_theme.name) or _PALETTE\n"
        "    for _key, _value in _chrome.items():\n"
        "        _variable = \"tracker-\" + _key.removeprefix(\"C_\").lower().replace(\"_\", \"-\")\n"
        "        _theme.variables.setdefault(_variable, _value)\n"
        "THEME_NAMES = [t.name for t in THEMES]\n",
    )
    source = replace_once(
        source,
        '        set_palette(self.theme == "system")\n',
        "        set_palette(self.theme)\n",
    )

    replacements = {
        'lb.get("color") or C_DIM': 'tracker_role_color("label", C_DIM)',
        't.get("color") or C_BLUE': 'tracker_role_color("team", C_BLUE)',
        'st["color"] or C_SUB': "tracker_state_color(st)",
        'state["color"] or C_SUB': "tracker_state_color(state)",
        'project.get("color") or C_DIM': 'tracker_role_color("project", C_DIM)',
        'init.get("color") or C_LAV': 'tracker_role_color("initiative", C_LAV)',
        '(self._team_of(issue) or {}).get("color") or C_DIM': 'tracker_role_color("team", C_DIM)',
        'lb["color"] or C_DIM': 'tracker_role_color("label", C_DIM)',
        'p.get("color") or C_DIM': 'tracker_role_color("project", C_DIM)',
        'to_state["color"]': "tracker_state_color(to_state)",
        's["color"] or C_SUB': "tracker_state_color(s)",
        "f\"bold {st['color'] or C_SUB}\"": "f\"bold {tracker_state_color(st)}\"",
    }
    for old, new in replacements.items():
        source = source.replace(old, new)
    source = source.replace(
        'badges.append((" \\uf056", C_RED))',
        'badges.append((" \\uf056", tracker_role_color("blocked", C_RED)))',
    )
    source = source.replace(
        'badges.append((" \\uf06a", C_PEACH))',
        'badges.append((" \\uf06a", tracker_role_color("blocking", C_PEACH)))',
    )
    source = source.replace(
        't.append(" ", style=f"bold {C_PEACH}")',
        "t.append(\" \", style=f\"bold {tracker_role_color('priority_urgent', C_PEACH)}\")",
    )

    css_start = source.index('    CSS = f\"\"\"')
    css_end = source.index('\n    \"\"\"', css_start)
    css = source[css_start:css_end]
    css = css.replace(
        "    OptionList:focus {{ background: transparent; border: none; }}\n",
        "    OptionList:focus {{ background: transparent; background-tint: transparent; border: none; }}\n"
        "    OptionList > .option-list--option-disabled {{ text-opacity: 100%; text-style: not dim; }}\n",
    )
    for constant in (
        "C_TEXT", "C_SUB", "C_DIM", "C_FAINT", "C_VFAINT", "C_BLUE",
        "C_LAV", "C_PEACH", "C_GREEN", "C_RED", "C_MAUVE",
    ):
        variable = "$tracker-" + constant.removeprefix("C_").lower().replace("_", "-")
        css = css.replace("{" + constant + "}", variable)
    if "{C_" in css:
        raise RuntimeError("upstream CSS still contains an import-time palette constant")
    source = source[:css_start] + css + source[css_end:]
    source = replace_once(
        source,
        "    def on_mount(self) -> None:\n"
        "        for t in THEMES:\n",
        "    @work(exclusive=True, group=\"flume-theme\")\n"
        "    async def watch_flume_theme(self) -> None:\n"
        "        async for theme in watch_flume_theme_changes():\n"
        "            if theme in self.available_themes and theme != self.theme:\n"
        "                self.theme = theme\n\n"
        "    def on_mount(self) -> None:\n"
        "        for t in THEMES:\n",
    )
    source = replace_once(
        source,
        "        layout = load_state()\n"
        "        if w := layout.get(\"sidebar_w\"):\n",
        "        layout = load_state()\n"
        "        self._sidebar_hidden = bool(layout.get(\"sidebar_hidden\", True))\n"
        "        if w := layout.get(\"sidebar_w\"):\n",
    )
    source = replace_once(
        source,
        "        if w := layout.get(\"detail_w\"):\n"
        "            self.query_one(\"#detail\").styles.width = int(w)\n",
        "        if w := layout.get(\"detail_w\"):\n"
        "            self.query_one(\"#detail\").styles.width = int(w)\n"
        "        self._apply_sidebar_visibility()\n",
    )
    source = replace_once(
        source,
        "        saved = load_state().get(\"theme\")\n"
        "        self.theme = saved if saved in self.available_themes else THEME_NAMES[0]\n"
        "        self.ansi_color = self._theme_is_ansi()\n",
        "        saved = active_flume_theme() or load_state().get(\"theme\")\n"
        "        self.theme = saved if saved in self.available_themes else THEME_NAMES[0]\n"
        "        set_palette(self.theme)\n"
        "        self.ansi_color = self._theme_is_ansi()\n"
        "        self.watch_flume_theme()\n",
    )

    source = replace_once(
        source,
        "    def _save_layout(self, reset: str | None = None) -> None:\n",
        "    def _apply_sidebar_visibility(self) -> None:\n"
        "        display = \"none\" if self._sidebar_hidden else \"block\"\n"
        "        self.query_one(\"#sidebar\").styles.display = display\n"
        "        self.query_one(\"#split-left\").styles.display = display\n"
        "        if self._sidebar_hidden and getattr(self.focused, \"id\", None) in {\"teams\", \"profile\"}:\n"
        "            self.query_one(\"#issues\", NavList).focus()\n\n"
        "    def action_toggle_sidebar(self) -> None:\n"
        "        self._sidebar_hidden = not self._sidebar_hidden\n"
        "        self._apply_sidebar_visibility()\n"
        "        self._save_state()\n\n"
        "    def _save_layout(self, reset: str | None = None) -> None:\n",
    )
    source = replace_once(
        source,
        '        data["group_by"] = self._group_by\n'
        "        save_state(data)\n",
        '        data["group_by"] = self._group_by\n'
        '        data["sidebar_hidden"] = self._sidebar_hidden\n'
        "        save_state(data)\n",
    )
    source = source.replace(
        '        elif fid == "issues":\n            self.query_one("#teams", NavList).focus()\n',
        '        elif fid == "issues" and not self._sidebar_hidden:\n            self.query_one("#teams", NavList).focus()\n',
    )

    if app == "ltui":
        source = replace_once(
            source,
            '            last_id = load_state().get("team_id")\n'
            "            scope = next(\n"
            '                (t for t in self._sidebar_scopes() if t["id"] == last_id), None\n'
            "            )\n",
            '            last_id = load_state().get("team_id")\n'
            "            scope = preferred_tracker_scope(self._sidebar_scopes(), last_id)\n",
        )
        source = replace_once(
            source,
            '        last = load_state().get("team_id")\n'
            "        scopes = self._sidebar_scopes()\n"
            '        scope = next((t for t in scopes if t["id"] == last), None) or (\n'
            "            self._teams[0] if self._teams else None\n"
            "        )\n",
            '        last = load_state().get("team_id")\n'
            "        scopes = self._sidebar_scopes()\n"
            "        scope = preferred_tracker_scope(scopes, last) or (self._teams[0] if self._teams else None)\n",
        )
    else:
        source = replace_once(
            source,
            '            last_id = load_state().get("team_id")\n'
            '            team = next((t for t in self._teams if t["id"] == last_id), None)\n',
            '            last_id = load_state().get("team_id")\n'
            "            team = preferred_tracker_scope(self._teams, last_id)\n",
        )
        source = replace_once(
            source,
            '        last = load_state().get("team_id")\n'
            '        team = next((t for t in self._teams if t["id"] == last), None) or (\n'
            "            self._teams[0] if self._teams else None\n"
            "        )\n",
            '        last = load_state().get("team_id")\n'
            "        team = preferred_tracker_scope(self._teams, last) or (self._teams[0] if self._teams else None)\n",
        )

    for escaped in (
        'style=st["color"]',
        'style=state["color"]',
        'style=to_state["color"]',
        'style=lb["color"]',
        'style=project.get("color")',
        'style=p.get("color")',
    ):
        if escaped in source:
            raise RuntimeError(f"tracker-owned color escaped Flume normalization: {escaped}")

    path.write_text(source)


if __name__ == "__main__":
    main()
