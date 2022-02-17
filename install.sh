# Create temporary build location
mkdir -p ~/tmp
cd ~/tmp

# Install dependancies
sudo apt install zsh tmux build-essential libtool-bin gettext

# Install neovim
which nvim
nvim -v
git clone --depth 1 https://github.com/neovim/neovim.git
cd ./neovim
./configure --prefix=$HOME/.local/bin
sudo make CMAKE_BUILD_TYPE=RelWithDebInfo
sudo make install


cd $HOME/dotfiles
stow nvim
stow zsh
stow tmux

# Remove build location
cd
