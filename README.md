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

Config edits are live-linked. Use `apply` for package or managed-link changes, not ordinary config
edits. Restart Neovim after Lua changes. Before activation, use `./scripts/dotfiles`.
