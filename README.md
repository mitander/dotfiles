# dotfiles

My Fish, Neovim, tmux and Ghostty setup, managed with Nix on Apple Silicon macOS and Linux
(ARM64/x86-64).

> [!NOTE]
>
> This is a custom environment that depends on close-sourced projects (myran, bronson), not a
> general-purpose installer. Tmux will require some tinkering to work around this (no fallback).

## On a new machine

With Nix and Git installed, open a fresh terminal:

```sh
mkdir -p ~/c/p
git clone https://github.com/mitander/flume.nvim.git ~/c/p/flume.nvim
git clone --branch flume-personal https://github.com/mitander/ltui.git ~/c/p/ltui
git clone https://github.com/mitander/dotfiles.git ~/dotfiles

git clone https://github.com/mitander/agent-config.git ~/.agents

cd ~/dotfiles
./scripts/dotfiles doctor
./scripts/dotfiles build
./scripts/dotfiles apply
./scripts/setup-trackers  # Python 3.11+; installs editable app dependencies once
```

Keep this checkout at `~/dotfiles` and agent-config at `~/.agents`, where the profiles expect them.
The `apply` command checks the profile's live-link location before activation. No other command
activates the environment, and these commands do not update `flake.lock`.

Run `dotfiles doctor` to check the selected profile, `dotfiles eval` to evaluate every supported
system without building, or `dotfiles generations` to list Home Manager history. Before the first
activation, use `./scripts/dotfiles` in place of `dotfiles`.

## Everyday changes

Configuration is live-linked into this checkout. Editing Fish, Neovim, tmux, Ghostty or Git
configuration does not require a Nix build.

```sh
dotfiles              # reload tmux and the calling Fish shell, without Nix
dotfiles build        # build package/link changes without activating them
dotfiles apply        # activate Home Manager, then reload
dotfiles check        # formatting and isolated behavior checks
```

Use `apply` after changing packages or Home Manager links, not after every configuration edit. It
keeps conflicting files as timestamped `.pre-nix-*` backups. A failed activation stops before
reloading. Ghostty watches its configuration. Restart Neovim after changing its Lua configuration.
Other applications may also need a restart. Reloading tmux requires the installed Myran binary. Old
tmux servers carrying retired workspace hooks need a restart to discard them. Reload no longer
removes those hooks. Save work first, since restarting a server ends its sessions.

## Open files in Myran

The macOS desktop bridge lives in this checkout. Install or update it explicitly with
`./scripts/install-myran-editor`. It registers the handler without selecting default applications.
Its file-opening helper remains live-linked to `scripts/myran-open-files`.

The bridge chooses the most recently active attached client on the default tmux server, not the
terminal that supplied a click. It captures that pane and the existing hidden Myran server identity
together, rejects identity changes, and forwards the retained capability to `myran open`. A missing
identity is an error, not permission to initialize or adopt another server.

## Checks

With Python 3.11+ and Node.js 22.6+ on `PATH`, run `dotfiles check` when changing scripts or
integrations. It checks formatting, Python types and isolated behavior without activating Home
Manager or touching your live sessions. Nix supplies the formatting tools. Run `./scripts/format.sh`
to format the checkout.

The tests cover custom glue: file-opening arguments, activation boundaries and editor/tmux
integration. Ordinary settings don't need a matching test.

Checks that need installed applications run separately:

```sh
./scripts/check formatters    # Conform with real formatters
./scripts/check myran         # Myran's tmux integration
./scripts/check myran-editor  # macOS file-opening app
./scripts/check pi            # strict TS, footer and file links against installed Pi
./scripts/check fzf           # installed picker filtering and shell arguments
./scripts/check nvim-startup  # installed plugin activation and large-buffer limits
./scripts/check luals         # Neovim configuration diagnostics
./scripts/check files         # installed Oil and NvimTree navigation
./scripts/check preview       # installed live-preview.nvim lifecycle
```

The Pi check needs the installed host and `tsc` on `PATH` (provided by Home Manager). It does not
install dependencies. These checks use disposable fixtures, not live workspaces. Tracker setup and
application checks are in [tracker-tui](tracker-tui/README.md).
