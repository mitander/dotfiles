# dotfiles

Development-environment configuration for Apple Silicon macOS and Linux on ARM64/x86-64.

## Everyday changes

Configuration is live-linked into this checkout. Editing Fish, Neovim, tmux, Ghostty or Git
configuration does not require a Nix build.

```sh
dotfiles              # reload tmux and the calling Fish shell, without Nix
dotfiles apply        # rebuild/activate Home Manager, then reload
dotfiles check        # formatting and isolated behavior checks
```

Use `apply` after changing packages or Home Manager links, not after every configuration edit.
Ghostty watches its configuration. Restart Neovim after changing its Lua configuration. Other
applications may also need a restart. Reloading tmux requires the installed Myran binary.

## File links on macOS

Run `./scripts/install-myran-editor` to build or update `~/Applications/Myran Editor.app` with the
Xcode command line tools. Installation advertises document support and the `myran://` scheme. It
does not select file or browser defaults and never requests bulk association confirmations. Use
`--no-register` to build or update the bundle without advertising it to Launch Services.

For each text-file type, select a representative file in Finder, then use **Get Info → Open with →
Myran Editor → Change All**. Use **Other…** and select the app under `~/Applications` if necessary.
The app supports macOS text types, including `.log`, and declares Rust, Fish, Lua, Nix and JSX
source types. Existing per-type defaults still need manual selection. Keep web links and HTML on
your browser, and images and movies on their existing apps. In particular, macOS can identify `.ts`
as MPEG video, so it is not declared as a text extension.

The launcher opens files through `myran open` in the most recently active attached tmux client's
workspace on the default server. It pins that client's pane and server incarnation before forwarding
paths. A server restart rejects the handoff instead of reusing an old pane ID. An attached client in
a Myran workspace is required. Files outside the project, including handoffs, still open in that
workspace's editor. Errors appear in a macOS dialog instead of starting another editor.

Ordinary `file://` links use macOS's selected document app. For a line or inclusive range, use:

```text
myran://open?path=/absolute/path/tests/test_evidence.py&line=352&end=596
```

Percent-encode query values, especially spaces, `#`, `%`, `&` and `+` in paths. Omit `end` for a
single line. Myran must support `open-at LINE[-END] -- path`. The editor opens at the first line and
temporarily highlights the range without Visual selection. Movement, editing, Escape, leaving the
buffer/window or another open clears the highlight. There is no timer. macOS drops fragments such as
`file:///path#L352-L596` before document delivery, so use `myran://` rather than a file fragment for
clickable location links. A bare `path:352-596` in terminal text does not automatically become a
location link.

The app live-links `scripts/myran-open-files`. After editing the Swift app or document declarations,
rerun the installer. Installation rejects symlink destinations and atomically replaces the
executable so a running copy is not truncated. To change defaults back, select the previous
application using Finder's same **Open with → Change All** control. There are no automatic
default-setting or restore commands. The default gate tests path forwarding in isolation.
`./scripts/check myran-editor` tests parsing and native macOS URL delivery, plus install/update and
failure safety in a disposable HOME without registering that fixture app or changing defaults.

## Ownership

- **Home Manager** installs the common CLI packages and links declared in
  [`home/common.nix`](home/common.nix). [`flake.nix`](flake.nix) selects three platform profiles.
  Native graphical applications, login shells, GPU/audio/display settings and mutable application
  state remain host-managed.
- **Myran** owns workspaces, roles and runs. Fish, Neovim and tmux call it rather than implement
  another workspace manager. `scripts/install-myran.py` retains exact-install receipts and rollback
  for manually installed binaries. It is not part of reload or Home Manager activation.
- **Flume** owns palettes and active-theme selection in the linked `themes/flume` checkout.
  Applications read its local exports directly. Theme changes use Flume's normal compile/sync flow,
  not Nix builds or a separate Textual export.
- **Local Python applications** run from editable checkouts. Tracker setup is
  [`scripts/setup-trackers`](scripts/setup-trackers), and [`tracker-tui/launch`](tracker-tui/launch)
  supplies the live Flume paths. Restart after source edits. Re-run setup only for dependency or
  package-metadata changes. Bronson already uses an editable pipx installation. See
  [`tracker-tui/README.md`](tracker-tui/README.md).

Home Manager generations restore packages and links, **not earlier contents of this live checkout**.
Git owns configuration history. Nix manages pinned CLI tools, not snapshots of local application or
theme source. `dotfiles apply` is needed only for package or managed-link changes.

The extra nixpkgs inputs keep selected Atuin and formatter versions independent of general package
updates. The tmux override pins its release across platforms. These are package-version choices, not
additional configuration managers.

## Checks

```sh
./scripts/check                # same gate as dotfiles check
./scripts/check myran          # installed Myran + private tmux caller/reload check
./scripts/check myran-editor   # native macOS file-URL delivery, without changing defaults
./scripts/check formatters     # installed Conform + real formatter smoke tests
./scripts/check trackers       # editable installation + the tracker fork's own tests
```

The default gate checks executable glue: literal paths, clipboard behavior, navigation, reload,
installation rollback and source selection. It uses disposable directories and private tmux servers,
not the running desktop or tracker services. It needs tools on PATH, but no installed Neovim
plugins, Myran binary or credentials. The optional lanes qualify those installed tools. Myran's
prompt/picker behavior is tested by Myran, not reimplemented in this repository's tests.

CI builds two outputs on each native platform: `home` for the installable environment and `default`
for the dotfiles gate. Application tests stay with their editable checkout and run through the
optional tracker lane. To run the isolated Nix-backed dotfiles gate on macOS:

```sh
nix build path:.#checks.aarch64-darwin.default --no-link
```

Use `aarch64-linux` or `x86_64-linux` on Linux. `scripts/dotfiles-nix.sh check` only evaluates all
platforms. It does not execute tests.

## Bootstrap and package changes

After installing Nix and opening a fresh terminal:

```sh
mkdir -p ~/c/p
git clone https://github.com/mitander/flume.nvim.git ~/c/p/flume.nvim
git clone --branch flume-personal https://github.com/mitander/ltui.git ~/c/p/ltui
git clone https://github.com/mitander/dotfiles.git ~/dotfiles
mkdir -p ~/.agents
gh repo clone mitander/agent-config ~/.agents
cd ~/dotfiles
./install.sh           # doctor + build, without activation
./install.sh --check   # also evaluate every supported system
./install.sh --activate
./scripts/setup-trackers  # requires Python 3.11+; installs editable app dependencies once
```

Profiles expect this checkout at `~/dotfiles`. Home Manager activation also requires `~/.agents`.
For package changes, inspect and build before explicitly activating:

```sh
./scripts/dotfiles-nix.sh doctor
./scripts/dotfiles-nix.sh build
DOTFILES_ALLOW_ACTIVATE=1 ./scripts/dotfiles-nix.sh switch
```
