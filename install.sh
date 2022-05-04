# Install neovim
if ! [ -x "$(command -v nvim)" ]; then
  mkdir -p ~/tmp
  cd ~/tmp

  which nvim
  nvim -v
  git clone --depth 1 https://github.com/neovim/neovim.git
  cd ./neovim
  ./configure --prefix=$HOME/.local/bin
  sudo make CMAKE_BUILD_TYPE=RelWithDebInfo
  sudo make install

  rm -rf ~/tmp
fi

# Install dependancies
sudo apt install zsh tmux build-essential libtool-bin gettext xsel jq fzf

# Link dotfiles
cd $HOME/dotfiles
stow nvim
stow zsh
stow tmux
stow alacritty
stow git

# Install font
sudo cp -r fonts/FiraCode /usr/local/share/fonts/
sudo cp -r fonts/Meslo /usr/local/share/fonts/
fc-cache -f -v
