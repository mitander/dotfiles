# Flume

A Neovim colorscheme packaged inside this dotfiles repo so it can be split into its own repo later.

## Character

Flume is a hybrid theme:

- Duskfox/Rosé Pine Moon-inspired UI, background, terminal, and tmux-compatible palette
- One Dark-inspired syntax hues
- softened neutral syntax foreground for lower glare on the purple background

## Files

- `lua/flume/init.lua` — palette and highlight definitions
- `colors/flume.lua` — `:colorscheme flume` entrypoint
- `lua/mitander_theme.lua` — backward-compatible alias

To extract later, copy `lua/flume/`, `colors/flume.lua`, and this README into a standalone `flume.nvim` repo.
