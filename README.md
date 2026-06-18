# dotfiles

```sh
git clone https://github.com/mitander/dotfiles.git ~/dotfiles
cd ~/dotfiles
./install.sh

# Optional flags
DOTFILES_SKIP_PACKAGES=1 ./install.sh   # only link configs
DOTFILES_SKIP_NVIM_SYNC=1 ./install.sh  # skip Lazy plugin sync
DOTFILES_SKIP_TPM=1 ./install.sh        # skip tmux plugin manager clone
```

The installer:

1. installs dependencies when a supported package manager is present
2. clones the Flume theme repo to `~/c/p/flume` when missing
3. symlinks config files into `$HOME`
4. installs tmux plugin manager
5. syncs neovim plugins

Existing files are moved to `~/.dotfiles-backup/<timestamp>/` before linking.
