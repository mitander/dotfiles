# dotfiles

Cross-platform development-environment configuration for Apple Silicon macOS and Linux on
ARM64/x86-64.

## Nix migration

The repository now contains a pinned Nix flake and conservative Home Manager profiles. Home Manager
installs the common CLI package set and owns the live configuration links declared in
[`home/common.nix`](home/common.nix). The login shell, native graphical applications,
Flume-generated themes, mutable application state, and host GPU/audio/display settings remain
host-managed.

After installing Nix and opening a fresh terminal:

```sh
./scripts/dotfiles-nix.sh doctor   # evaluate the selected profile
./scripts/dotfiles-nix.sh check    # evaluate every supported system
./scripts/dotfiles-nix.sh build    # build without activation
```

Activation requires an explicit guard:

```sh
DOTFILES_ALLOW_ACTIVATE=1 ./scripts/dotfiles-nix.sh switch
```

Managed configuration uses live out-of-store links into this checkout. Editing Fish, Neovim, tmux,
Ghostty, Git, or other declared dotfiles takes effect immediately; run `switch` only after changing
packages, profiles, or Home Manager declarations. Each profile explicitly defines its expected
checkout path.

## Formatting

```sh
./scripts/format.sh        # format maintained source and documentation
./scripts/format.sh check  # check formatting and Python/shell lint without writes
```

Home Manager installs the pinned native tools and links `dotfiles-format` to the same command. Ruff
owns Python formatting and import ordering; Prettier owns Markdown and structured data; shfmt owns
sh/bash; Fish uses `fish_indent`; Lua uses StyLua; Nix uses Alejandra; TOML uses Taplo. Generated
themes, lockfiles, and configuration without a native formatter are left alone.

Python and prose use a 100-column target. Shell indentation is two spaces; Python and Fish use four.
Repository-local formatter settings also apply to Neovim saves. Rust projects with
`rustfmt-nightly.toml` use the pinned nightly formatter in both the editor and repository gate.
Restart Neovim after updating its configuration.

The flake's `formatting` check runs the same command in check mode. Other projects own their native
settings and existing format command; they do not depend on this checkout.

## Myran shortcuts

Tmux delegates workspace, role and run shortcuts through one `myran tmux configure --replace` setup
call. Personal tool argv, named agents and shortcut choices belong in `~/.config/myran/config.toml`;
project run declarations remain in `.myran.toml`. Install a Myran binary supporting `tmux configure`
before reloading this tmux config. General navigation, native splits, copy mode, themes and plugins
remain here. Plain Enter/q/Escape are not intercepted by these dotfiles.

The disposable config proof can use a source-built binary without installing it:

```sh
MYRAN_TEST_BINARY="$HOME/c/p/myran/target/debug/myran" ./tests/tmux-config.sh
```

## Safe bootstrap

Clone this repository and the Flume theme source at the paths used by the selected profiles, then
run the non-destructive bootstrap.

```sh
mkdir -p ~/c/p
git clone https://github.com/mitander/flume.nvim.git ~/c/p/flume.nvim
git clone https://github.com/mitander/dotfiles.git ~/dotfiles
mkdir -p ~/.agents
gh repo clone mitander/agent-config ~/.agents
cd ~/dotfiles
./install.sh           # doctor + build; does not activate
./install.sh --check   # also evaluate every supported system
./install.sh --activate
```

`install.sh` never invokes a host package manager and does not install Nix automatically. Ordinary
dotfile edits are live-linked and require no activation. From any Fish shell, run `dotfiles` after
changing Nix declarations or when you want one refresh command. It applies Home Manager, reloads
tmux, and refreshes the calling Fish shell. Ghostty watches its linked config. Neovim configuration
changes still need `:restart`, because its plugin setup is not safely hot-reloadable. Use Git for
configuration rollback and Home Manager generations for package or declaration rollback.
