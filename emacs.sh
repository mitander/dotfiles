#!/bin/bash
sudo add-apt-repository -y ppa:kelleyk/emacs
sudo apt-get -y update
sudo apt-get -y install zsh git emacs27 gdb htop
sudo chsh $USER -s /bin/zsh
cp -r -f .emacs.d .gdbinit $HOME
