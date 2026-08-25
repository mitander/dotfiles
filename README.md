# dotfiles

Cross-platform development-environment configuration for Apple Silicon macOS
and Linux on ARM64/x86-64.

## Nix migration

The repository now contains a pinned Nix flake and conservative Home Manager
profiles. Home Manager installs the common CLI package set and owns the live
configuration links declared in [`home/common.nix`](home/common.nix). The login
shell, native graphical applications, Flume-generated themes, mutable application
state, and host GPU/audio/display settings remain host-managed.

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

Managed configuration uses live out-of-store links into this checkout. Editing
Fish, Neovim, tmux, Ghostty, Git, or other declared dotfiles takes effect
immediately; run `switch` only after changing packages, profiles, or Home Manager
declarations. Each profile explicitly defines its expected checkout path.

## Workspace Residency

Workspace Residency currently runs in observation mode: tmux records when a
Workspace has been detached for 15 minutes, but does not stop any tools. The
implementation is event-driven; it adds no keypress, mouse, status-line, or
periodic polling work.

```text
prefix + I   observe an immediate cooling decision
prefix + w   open the Workspace picker
```

Useful diagnostics:

```sh
~/.local/bin/tmux-residency status
~/.local/bin/tmux-residency benchmark 100
./tests/tmux-residency.sh
```

The Workspace picker deliberately shows only names and roots; detached grace and
cooling state are internal details. Run completion is delivered by tmux's
`pane-died` event instead of a 25 ms watcher, and Ctrl-h/j/k/l routing uses pane
metadata instead of process probes on each keypress. The tmux configuration falls
back to the repository script when the Home Manager command is absent, preserving
generation rollback.

## Safe bootstrap

Clone this repository and the Flume theme source at the paths used by the
selected profiles, then run the non-destructive bootstrap. Home Manager checks
that Flume's four generated Tuxedo palettes exist before activation.

```sh
mkdir -p ~/c/p
git clone https://github.com/mitander/flume.nvim.git ~/c/p/flume.nvim
git clone https://github.com/mitander/dotfiles.git ~/dotfiles
cd ~/dotfiles
./install.sh           # doctor + build; does not activate
./install.sh --check   # also evaluate every supported system
./install.sh --activate
```

`install.sh` never invokes a host package manager and does not install Nix
automatically. Ordinary dotfile edits are live-linked and require no activation.
Use Git for configuration rollback and Home Manager generations for package or
declaration rollback.
