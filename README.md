# dotfiles

Cross-platform development-environment configuration for Apple Silicon macOS
and Linux on ARM64/x86-64.

## Nix migration

The repository now contains a pinned Nix flake and conservative Home Manager
profiles. Home Manager installs the common CLI package set and owns the migrated
LSD, Stylua, Git, LazyGit, Ghostty, Fish, tmux, Neovim, Pi-extension, and LLDB configuration paths listed in [`docs/nix-migration.md`](docs/nix-migration.md).
Other Stow-managed configuration, the login shell, native graphical applications,
and host GPU/audio/display settings remain unchanged.

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

Read [`docs/nix-migration.md`](docs/nix-migration.md) before activation. It
documents supported profiles, ownership transfer, rollback, and the work that
is deliberately deferred.

## Legacy bootstrap

The existing installer remains supported during migration:

```sh
git clone https://github.com/mitander/dotfiles.git ~/dotfiles
cd ~/dotfiles
./install.sh

DOTFILES_SKIP_PACKAGES=1 ./install.sh
DOTFILES_SKIP_NVIM_SYNC=1 ./install.sh
DOTFILES_SKIP_TPM=1 ./install.sh
```

The legacy installer:

1. installs dependencies when a supported package manager is present;
2. clones the Flume theme repository when missing;
3. links configuration files into `$HOME` with GNU Stow;
4. installs tmux plugin manager; and
5. synchronizes Neovim plugins.

Do not run Stow and Home Manager against the same destination. The full legacy
installer can overwrite migrated links; use the package-specific rollback
commands in [`docs/nix-migration.md`](docs/nix-migration.md) while Home Manager
is active. Remaining configuration packages will move one at a time.
