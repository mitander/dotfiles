# Personal ltui applications

Application changes and the Flume adapter live in `~/c/p/ltui`, on branch `flume-personal`. See that
checkout's `PERSONAL.md` for behavior, checks, and the upstream update procedure. The fork preserves
upstream's GPL license, notices, and attribution.

`home/common.nix` pins the filtered local checkout by content hash. It builds ltui, jtui, and the
adapter directly; no replacement-script patch runs at build time. Generate theme data from Flume's
canonical palette source at build time. The wrapper points `FLUME_TRACKER_THEME_DIR` at those store
assets, not at a removed directory in Flume. `FLUME_SCHEMA_FILE` still follows Flume's active schema
marker. Rebuild after editing palette colors; palette switches among loaded themes remain live.

Home Manager links `~/.config/bronson/flume-themes` to the same generated palettes and
`~/.config/bronson/flume` to Flume's live extras directory. Bronson loads colors separately from the
active schema marker. Flume does not need to ship application-specific tracker exports. Restart
applications after the first activation so they register all four palettes.

## Validate without deploying

```sh
FLUME_RUNTIME="$HOME/c/p/flume.nvim" PYTHON=/path/to/venv/bin/python \
  "$HOME/c/p/ltui/scripts/check"
nix build --impure --no-link .#checks.aarch64-darwin.tracker-tui
```

Use the appropriate system attribute on Linux. The checks stub application startup and credentials;
they do not contact tracker services or activate Home Manager. Every target machine needs the same
fork snapshot at `~/c/p/ltui` and its Flume checkout. This is a local pin, not a published remote
source.

## Update the local pin

After editing and testing the fork, compute the filtered snapshot hash:

```sh
source=$(nix eval --impure --raw --expr "builtins.path {
  path = $HOME/c/p/ltui;
  name = \"ltui-personal-source\";
  filter = path: type: !(builtins.elem (baseNameOf path) [\".git\" \"__pycache__\" \".venv\"]);
}")
nix hash path "$source"
```

Update `trackerTuiSource.sha256` in `home/common.nix` to that value and rerun the build checks. The
pin fixes the build input even when the working tree changes. A mismatched source fails when Nix
must import it; an already cached snapshot can remain usable until the pin changes. Publishing a
remote fork and replacing the local pin with a Git revision are separate operations; neither occurs
during these checks.
