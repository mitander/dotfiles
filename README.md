# dotfiles

My Fish, Neovim, tmux and Ghostty configuration for Apple Silicon macOS and Linux (ARM64/x86-64).
Managed with Nix. Also depends on my private myran and bronson projects.

## Install

With Nix and Git installed:

```sh
mkdir -p ~/c/p
git clone https://github.com/mitander/flume.nvim.git ~/c/p/flume.nvim
git clone --branch flume-personal https://github.com/mitander/ltui.git ~/c/p/ltui
git clone https://github.com/mitander/agent-config.git ~/.agents
git clone https://github.com/mitander/dotfiles.git ~/dotfiles

cd ~/dotfiles
./scripts/dotfiles doctor
./scripts/dotfiles build
./scripts/dotfiles apply
./scripts/setup-trackers  # Python 3.11+
```

Keep the checkouts at these paths. In Neovim, run `:FlumeSync` and `:FlumeInstallExtras` to set up
shared theme integrations.

## Commands

```sh
dotfiles              # reload tmux and the calling Fish shell
dotfiles build        # build package/link changes without activating
dotfiles apply        # activate Home Manager, then reload
dotfiles check        # formatting, types and isolated tests
dotfiles doctor       # check the selected profile and checkout
dotfiles eval         # evaluate all supported systems
dotfiles generations  # list Home Manager history
```

To check the Tmux color composition against all four Flume palettes:

```sh
FLUME_RUNTIME=~/c/p/flume.nvim bash tests/tmux-run-borders.sh
```

This uses a private server and attached terminal client. It checks rendered normal messages, vi
command-mode prompts, inactive labels, unfilled scroll positions, and filled active-tab/zoom badges.
The ordinary gate checks the tracked fallback composition without requiring a Flume checkout.
`FLUME_RUNTIME=~/c/p/flume.nvim ./scripts/check yazi` also checks the real file picker's selection
slots against all four terminal palettes. Yazi uses reversed terminal magenta and the canvas rather
than ANSI black as filled-label text. Its named-slot configuration follows the terminal palette, not
a separate RGB theme.

Config edits are live-linked. Use `apply` for package or managed-link changes, not ordinary config
edits. Restart Neovim after Lua changes. Before activation, use `./scripts/dotfiles`.
