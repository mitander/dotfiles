# Local tracker applications

Application changes and the Flume adapter live in
[`mitander/ltui`](https://github.com/mitander/ltui/tree/flume-personal). Dotfiles supplies
launchers, not application snapshots or a second package definition.

## Setup

With Python 3.11 or newer installed:

```sh
git clone --branch flume-personal https://github.com/mitander/ltui.git ~/c/p/ltui
./scripts/setup-trackers
```

Setup creates `~/c/p/ltui/.venv` and installs the adapter, ltui and jtui in editable mode.
Dependencies are resolved only during explicit setup. Nothing installs packages when an application
starts. Set `PYTHON=/path/to/python` to choose the setup interpreter.

Home Manager links `~/.local/bin/ltui` and `jtui` to the shared launcher. When migrating from the
old Nix packages, run `dotfiles apply` once to remove those snapshots and install these links. After
that, editing Python source requires only an application restart, not Nix activation, publishing or
reinstalling. Re-run setup after dependency or package-metadata changes.

`LTUI_CHECKOUT=/path/to/ltui` selects a different local checkout for both setup and launch. There is
no remote-source fallback. A missing environment reports the setup command instead of silently
running an older installed snapshot. Ltui defaults `TRACKER_SCOPE` to `dev` when unset.

## Themes

The launcher points `FLUME_TRACKER_THEME_DIR` at the local Flume checkout's `extras/palette` and
`FLUME_SCHEMA_FILE` at `extras/current/schema`. Both remain overridable. The application adapter
reads Flume's semantic JSON exports directly and maps them to Textual colors. No pinned palette
source, generated Textual directory or Neovim subprocess is involved.

After editing palette colors, use Flume's normal compile/sync command and restart the application.
Switching among already loaded palettes stays live. Bronson reads the same palette exports through
its `~/.config/bronson/flume` link, without an external Python bridge.

## Checks

```sh
./scripts/check trackers
```

This verifies that module imports point at the editable checkout, then runs the fork's own
`scripts/check`. Tests stub credentials and application startup, without contacting tracker
services. Application and theme changes do not require a Home Manager build.
