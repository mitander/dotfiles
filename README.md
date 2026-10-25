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

JavaScript and TypeScript use ES modules, four-space indentation, `camelCase` names and `const` by
default. Keep effects and cleanup visible. The installed-Pi check also runs strict TypeScript
checks, including unchecked index access and exact optional properties. JavaScript fixtures are
exercised at runtime, not statically checked.

## Neovim performance

Run `:TSInstallConfigured` in Neovim after initial plugin installation or when adding configured
parser languages. Normal startup does not install parsers. Plugin updates still run `:TSUpdate`.

Treesitter startup and Markdown rendering skip buffers above 100 KiB. Buffer-word completion uses at
most 100 KiB of visible normal buffers, preferring the current buffer. Loaded-buffer checks use
current text, including unsaved edits, without copying the buffer into Lua.

Inside tmux, the Fish `nvim` function uses `myran open` to reuse the project's running editor.
Ctrl-Q in an Edit pane returns to the previously selected tmux window without closing the editor.
Other panes receive Ctrl-Q unchanged. This is native tmux navigation, not a Myran action. Switching
back preserves the editor's language-server processes and their in-memory caches. Quitting Neovim or
restarting a server loses that analysis state. Session/layout restoration does not restore it.
Rust-analyzer cache priming is already enabled by default.

## Skim file sizes by code lines

Use `lt` for a Git-aware tree with an aligned LOC column. Counts come from tokei and exclude
comments and blank lines. Counts are gray below 200, yellow from 200 to 499, and red from 500.
Unrecognized file types show `—` instead of a misleading zero. Symlinks are displayed without
following or counting their targets. Plain `tree` is unchanged.

```fish
lt                 # current directory
lt -L 2 src        # limit displayed depth
lt -I 'vendor|dist' # exclude matching names
lt -a              # include hidden files
```

Run `lt --help` for supported options. Output is uncolored when piped or when `NO_COLOR` is set. Use
`--color always` to force color. Python, tree and tokei are included in the Home Manager profile.

## Neovim file browsing

Use `Ctrl-n` to toggle a 34-column Oil sidebar on the left. Enter opens directories inside the
sidebar and files in the editing window beside it. Use `-` or Backspace to go up, and `q` to close
the sidebar. Closing it does not quit Neovim.

Use `<leader>n` (Space, then n) to toggle a project tree and reveal the current file when sharing
the project layout. The tree loads only when requested, without Git scanning, filesystem watchers or
automatic file tracking. Use its default navigation and `q` to close it. Opening either sidebar
closes the other. Press `R` in the tree to refresh after external changes.

Browser statuslines show only the browser and directory, such as `Oil · plugins/` or
`Tree · dotfiles/`, whether focused or not.

Outside the sidebar, `-` opens Oil in the current window. `nvim .` and `:edit directory/` also use
Oil without forcing a sidebar. Edit filenames and use `:w` to apply changes. Deleted files go to the
trash. Hidden files are visible, and directory watching stays off.

## Neovim search

Use `<C-f>` for live grep. Search text is a ripgrep regex, with optional file globs after ` --`:
`error -- *.rs !*_test.rs` searches Rust files except test files. There is no custom `in:`/`out:`
syntax or implicit extension detection. Neovim uses `/bin/sh` for subprocess commands so fzf-lua's
quoting matches its command runner. Interactive tmux panes still use Fish.

Use `<leader>gl` for repository commits and `<leader>gc` for the current file's commits.

## Pi footer

The footer has one fixed layout: state indicator, location, context usage, model and token/cost
summary, with a blank line below it. It updates on events, without animation or settings commands.

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
