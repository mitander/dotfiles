# dotfiles

My Fish, Neovim, tmux and Ghostty configuration for Apple Silicon macOS and Linux (ARM64/x86-64).
Managed with Nix. Also depends on my private myran and bronson projects.

## Install

With Nix and Git installed:

```sh
mkdir -p ~/c/p
git clone https://github.com/mitander/flume.nvim.git ~/c/p/flume.nvim
git clone --branch flume-personal https://github.com/mitander/ltui.git ~/c/p/ltui
git clone https://github.com/mitander/agent-config.git ~/.agents
git clone https://github.com/mitander/dotfiles.git ~/dotfiles

cd ~/dotfiles
./scripts/dotfiles doctor
./scripts/dotfiles build
./scripts/dotfiles apply
./scripts/setup-trackers  # Python 3.11+
```

Keep the checkouts at these paths. In Neovim, run `:FlumeSync` and `:FlumeInstallExtras` to set up
shared theme integrations.

## Commands

```sh
dotfiles              # show which refresh command to use
dotfiles reload       # reread tmux, this Fish shell and installed Flume fragments
dotfiles build        # build package/link changes without activating
dotfiles apply        # install/activate Nix packages and managed links, then reload
dotfiles check        # formatting, types and isolated tests
dotfiles doctor       # check the selected profile and checkout
dotfiles eval         # evaluate all supported systems
dotfiles generations  # list Home Manager history
```

To check the Tmux color composition against all four Flume palettes:

```sh
FLUME_RUNTIME=~/c/p/flume.nvim bash tests/tmux-run-borders.sh
```

This uses a private server and attached terminal client. It checks rendered normal messages, vi
command-mode prompts, inactive labels, unfilled scroll positions, and filled active-tab/zoom badges.
The ordinary gate checks the tracked fallback composition without requiring a Flume checkout.
`FLUME_RUNTIME=~/c/p/flume.nvim ./scripts/check yazi` also checks the real file picker's selection
slots against all four terminal palettes. Yazi uses reversed terminal magenta and the canvas rather
than ANSI black as filled-label text. Its named-slot configuration follows the terminal palette, not
a separate RGB theme.

## Refresh after editing

| Changed                                  | Action                                                                                           |
| ---------------------------------------- | ------------------------------------------------------------------------------------------------ |
| Fish or tmux configuration               | `dotfiles reload`                                                                                |
| Neovim configuration                     | Restart Neovim                                                                                   |
| Flume palette or source                  | `:FlumeSync` in Neovim. This setup enables `dev = true`, so source and exports refresh together. |
| ltui or bronson source                   | Quit and reopen that app. Both run from editable checkouts.                                      |
| Nix packages or managed links in `home/` | `dotfiles apply`                                                                                 |

Config files are live-linked, but running applications must reread them. `reload` uses no Nix. In
Fish it refreshes only the calling shell, including installed Flume color/tool fragments. Other
existing shells keep their loaded settings. Ghostty's reload shortcut only reloads Ghostty.

Flume sync requests Ghostty and tmux reloads and notifies Pi when configured. Reopen other running
apps if their colors are stale. Existing Fish shells can use `dotfiles reload`. Normal Flume users
without dev mode sync bundled palettes without source regeneration.

Python dependency changes need environment setup, not Nix activation. For ltui, run
`./scripts/setup-trackers`. Ordinary Python source edits only need an app restart. Before
activation, use `./scripts/dotfiles` if the command is not installed yet.
