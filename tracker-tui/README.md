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

Setup creates `~/c/p/ltui/.venv` and installs the adapter and ltui in editable mode. Dependencies
are resolved only during explicit setup. Nothing installs packages when an application starts. Set
`PYTHON=/path/to/python` to choose the setup interpreter.

Home Manager links `~/.local/bin/ltui` to the launcher. Run `dotfiles apply` after changing managed
links. Editing Python source requires only an application restart. Re-run setup after dependency or
package-metadata changes. Setup does not uninstall packages from an existing environment.

`LTUI_CHECKOUT=/path/to/ltui` selects a different local checkout for both setup and launch. There is
no remote-source fallback. A missing environment reports the setup command instead of silently
running an older installed snapshot. Ltui defaults `TRACKER_SCOPE` to `dev` when unset.

## Themes

The launcher defaults `FLUME_TRACKER_THEME_DIR` to the local Flume checkout's `extras/palette` and
`FLUME_SCHEMA_FILE` to `extras/current/schema`. Flume's `:FlumeSync` forwards that legacy schema
path to its data directory. Both variables are overridable. For a direct schema path, use
`<flume-data>/current/schema`, with the directory reported by `require("flume").get_sync_dir()` in
Neovim. The adapter reads Flume's JSON exports directly.

After editing palette colors, use Flume's normal compile/sync command and restart the application.
Switching among already loaded palettes stays live. Bronson reads the same palette exports through
its `~/.config/bronson/flume` link, without an external Python bridge.

## Checks

After setup, run from the dotfiles root:

```sh
./scripts/check trackers
```

This verifies that module imports point at the editable checkout, then runs the fork's own
`scripts/check`. Tests stub credentials and application startup, without contacting tracker
services. Application and theme changes do not require a Home Manager build.
