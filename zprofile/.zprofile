#!/bin/bash

# Set default directories
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_CACHE_HOME="$HOME/.cache"
export XDG_DATA_HOME="$HOME/.local/share"
export CUSTOM_SOURCE_HOME="$HOME/.local/src"

# Set path of programs
export JAVA_HOME="$CUSTOM_SOURCE_HOME/java"
export NODE_HOME="$CUSTOM_SOURCE_HOME/node/node-v14.4.0"
export OPT="/opt"

# Set path of scripts
export SCRIPTS="$HOME/scripts"

# Set path of pipes for xob
export XOBPIPES="/tmp/xobpipes"

# Set default programs
export EDITOR="nvim"
export TERMINAL="alacritty"
export BROWSER="firefox"
export PAGER="nvim +Man!"

# Add directories to PATH
export PATH="$PATH:$HOME/.local/bin"
export PATH="$PATH:$OPT/bin"
export PATH="$PATH:$NODE_HOME/bin"
export PATH="$PATH:$JAVA_HOME/bin"

# Set colors for man pages
export LESS_TERMCAP_mb=$'\e[1;34m'
export LESS_TERMCAP_md=$'\e[1;34m'
export LESS_TERMCAP_me=$'\e[0m'
export LESS_TERMCAP_se=$'\e[0m'
export LESS_TERMCAP_ue=$'\e[0m'
export LESS_TERMCAP_us=$'\e[4;32m'

# Set variables for man
export MANPAGER="$PAGER"
export MANWIDTH="999"

# Disable history file for less
export LESSHISTFILE="-"

# Set title color of pfetch
export PF_COL3="4"

# set keyboard rate
xset r rate 275 40