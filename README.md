# dotfiles

My Fish, Neovim, tmux and Ghostty setup, managed with Nix on Apple Silicon macOS and Linux
(ARM64/x86-64).

> [!NOTE]
>
> This is a custom environment that depends on close-sourced projects (myran, bronson), not a
> general-purpose installer. Tmux will require some tinkering to work around this (no fallback).

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

## Configuration layout

Group settings by responsibility, with a blank line between groups. Use short, sentence-case section
comments such as `# Pane navigation` or `-- Search and substitution`, with no blank line after the
heading. Keep explanations of ordering, compatibility and ownership next to the settings they
affect.

Prefer native application commands over shell wrappers. Share repeated configuration where it has
one owner, but keep small, readable settings inline. Run `./scripts/format.sh` for files with a
formatter. Tmux, Ghostty, Git and LLDB configuration use their native syntax and manual grouping.
Theme symlinks point into the Flume checkout and are maintained there.

## Neovim search

Use `<C-f>` for live grep. Search text is a ripgrep regex, with optional file globs after ` --`:
`error -- *.rs !*_test.rs` searches Rust files except test files. There is no custom `in:`/`out:`
syntax or implicit extension detection. Neovim uses `/bin/sh` for subprocess commands so fzf-lua's
quoting matches its command runner. Interactive tmux panes still use Fish.

Use `<leader>gl` for repository commits and `<leader>gc` for the current file's commits.

## Browser previews in Neovim

Use `<leader>vp` to open a preview and `<leader>vs` to stop it immediately. Each preview gets an
OS-assigned loopback port, so separate Neovim instances do not compete for port 5500. The server
stops after 30 seconds without a connected preview page, including when the browser never connects.
Refreshing during that grace period keeps it alive. After it stops, use `<leader>vp` again rather
than refreshing the old URL.

The lifecycle adapter in `nvim/.config/nvim/lua/mitander/preview.lua` depends on the pinned
live-preview.nvim server API. Run the installed-plugin preview check when updating that pin.

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

## Checks

With Python 3.11+ on `PATH`, run `dotfiles check` when changing scripts or integrations. It checks
formatting, Python types and isolated behavior without activating Home Manager or touching your live
sessions. Nix supplies the formatting tools. Run `./scripts/format.sh` to format the checkout.

The tests cover custom glue: file-opening arguments, activation boundaries and editor/tmux
integration. Ordinary settings don't need a matching test.

Checks that need installed applications run separately:

```sh
./scripts/check formatters    # Conform with real formatters
./scripts/check myran         # Myran's tmux integration
./scripts/check myran-editor  # macOS file-opening app
./scripts/check fzf           # installed picker filtering and shell arguments
./scripts/check luals         # Neovim configuration diagnostics
./scripts/check preview       # installed live-preview.nvim lifecycle
```

These checks use disposable fixtures, not live workspaces. Tracker setup and application checks are
in [tracker-tui](tracker-tui/README.md).
