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

## Workspace creation

Fish `tn [path]` uses `myr workspace open` to establish Project identity when
creating a Workspace. `tm` remains the existing Workspace picker.
Reload Fish configuration or open a fresh shell to use the updated shortcut.

Restoring Project identity through tmux-resurrect is not implemented. Restored
Sessions without root metadata still need explicit root assignment before Myran
can open roles. Opening Term is not a required part of Myran's role contract.

## Myran installation and callers

Build and validate Myran in its owning checkout first. Install the reviewed binary:

```sh
python3 scripts/install-myr.py install /absolute/path/to/myran/target/release/myr
```

The installer atomically replaces `~/.local/bin/myr` and prints a receipt directory
and exact rollback command. It preserves the prior binary, mode and checksums and
refuses symlinks, unsafe ownership or writable ancestors. Rollback refuses to
replace a binary changed since installation. Keep caller configuration backups
separately because Home Manager's live links do not preserve previous file contents.

Fish `tn` and `tm`, tmux role bindings and status-left clicks, and Neovim role
callbacks call Myran. Native navigation, raw splits and outside-tmux editor/Git
fallbacks stay native. Inside tmux, Fish `nvim`/`vim` and LazyGit file edits use
`myr open` with literal paths. Use `command nvim` for startup flags or `+commands`.
LazyGit file handoff does not jump to a line or replace commit-message editing.

Run the installed caller lane after installation:

```sh
python3 tests/myran-installed.py
```

It uses a private tmux server and recording Agent fixture, not live Sessions.
It checks literal named-agent input, quoted project paths, Workspace switching
and an actual status-left mouse click. It requires installed Myran, tmux, fzf,
Fish and Python 3. Myran's repository owns the full Workspace/role integration gates.

## Tracker and cooling

The Tracker role uses the shared Pantheon TUI suite. It defaults to Linear
(`ltui`) and can use Jira (`jtui`) per repository:

```sh
git config workspace.tracker jira      # run once in a work repository
git config workspace.tracker-team OPS  # optional explicit Jira project / Linear team
# git config workspace.tracker linear  # optional; Linear is the default
```

`prefix + t` opens or focuses the current Tracker. For explicit selection use
`myr role open tracker --tracker linear|jira --scope TEAM`. Changing selection
preserves the previous whole window, and returning to it reuses that terminal.
`TRACKER_TUI=linear|jira` overrides the repository default for new launches.
Scope comes from `TRACKER_SCOPE`, `workspace.tracker-team`, then an issue-key
branch prefix. Repository matching remains a startup hint, not an enforced filter.

Press `b` inside either TUI to hide or restore the left team/settings sidebar.
The issue list keeps the reclaimed width and tickets still open in the detail
split.

Linear starts in **Now and next**, showing started and unstarted issues only.
Press `f` to toggle **All issues**. The selection is remembered across launches.
Issues follow Linear's manual list order within each status, not assignment,
priority, or update time. Reorder tickets in Linear with status grouping and
Manual ordering. ltui only reads those ranks and never changes them.
The focused view numbers visible unstarted tickets within each group. `?` means
an old cached ticket has no rank yet and needs a successful refresh.
Existing `m`, `/`, and `V` filters still apply. Press `v` after initiative to
group by project milestone, ordered by target date. Milestones also appear in
issue details. This is a local status filter, not an import of a saved Linear
view or a dependency scheduler. Blocked tickets remain visible if they are in a
started/unstarted status.

Both apps load Flume's dusk, opal, mira, and mesa themes from the linked
checkout. Running task windows follow `:FlumeSync` through the same event-driven
integration switch as Neovim.

`prefix + w` opens the Workspace picker. Automatic and manual cooling are retired.
Detached tools keep running. Automatic tmux restore is disabled so a fresh server
cannot replay old helper commands or stale Workspace state. Historical Resurrect
snapshots remain on disk, but are not a supported Myran Workspace restore path.
Open fresh Workspaces with `myr workspace open [path]`. Richer restoration is separate
work. Never replay historical snapshots as part of a clean reset.

Run completion uses tmux's `pane-died` event, not a polling watcher. Ctrl-h/j/k/l
navigation uses pane metadata, not process probes on each keypress.

## Safe bootstrap

Clone this repository and the Flume theme source at the paths used by the
selected profiles, then run the non-destructive bootstrap.

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

`install.sh` never invokes a host package manager and does not install Nix
automatically. Ordinary dotfile edits are live-linked and require no activation.
Use Git for configuration rollback and Home Manager generations for package or
declaration rollback.
