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

Tracker applications use the local `~/c/p/ltui` checkout when it exists, including uncommitted
edits. Run the helper's `build` and guarded `switch` commands after changing application code.
Machines without the checkout use the locked remote source. See
[`tracker-tui/README.md`](tracker-tui/README.md) for source overrides and validation commands.

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
