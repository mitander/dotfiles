# Personal ltui applications

Application changes and the Flume adapter live in
[`mitander/ltui`](https://github.com/mitander/ltui/tree/flume-personal), on branch `flume-personal`.
See the fork's `PERSONAL.md` for behavior, checks, and the upstream update procedure. The fork
preserves upstream's GPL license, notices, and attribution.

`home/common.nix` fetches a pinned Git commit with a verified content hash. It builds ltui, jtui,
and the adapter directly; no local ltui checkout or replacement-script patch is required at build
time. Generate theme data from a pinned remote Flume palette source at build time. The wrapper
points `FLUME_TRACKER_THEME_DIR` at those store assets, not at a removed directory in Flume.
`FLUME_SCHEMA_FILE` still follows Flume's active schema marker. Rebuild after editing palette colors
in the `flumeSource` pin; palette switches among loaded themes remain live.

Home Manager links `~/.config/bronson/flume-themes` to the same generated palettes and
`~/.config/bronson/flume` to Flume's live extras directory. Bronson loads colors separately from the
active schema marker. Flume does not need to ship application-specific tracker exports. Restart
applications after the first activation so they register all four palettes.

## Validate without deploying

```sh
FLUME_RUNTIME="$HOME/c/p/flume.nvim" PYTHON=/path/to/venv/bin/python \
  "$HOME/c/p/ltui/scripts/check"
nix build --no-link .#checks.aarch64-darwin.tracker-tui
```

Use the appropriate system attribute on Linux. The checks stub application startup and credentials;
they do not contact tracker services or activate Home Manager. The local fork checkout is needed
only for the first command. Nix downloads the pinned fork and Flume palette source automatically.
Builds and CI do not need a local Flume checkout. Target machines still need the Flume checkout for
live runtime theme switching.

## Update the remote pin

After editing and testing the fork, publish the changes to `mitander/ltui` on `flume-personal`.
Resolve the published commit and compute its unpacked archive hash:

```sh
rev=$(git ls-remote https://github.com/mitander/ltui.git refs/heads/flume-personal | cut -f1)
nix store prefetch-file --json --unpack "https://github.com/mitander/ltui/archive/$rev.tar.gz"
```

Set `trackerTuiSource.rev` to that commit and `trackerTuiSource.hash` to the returned `hash` in
`home/common.nix`. Rerun the build checks before activation. Branch updates and local fork edits do
not change the installed applications until this pin is updated and Home Manager is applied.

For palette changes, use the same procedure with `https://github.com/mitander/flume.nvim.git` and
the desired published commit. Update `flumeSource.rev` and `flumeSource.hash` in `home/common.nix`,
then rerun the build checks. Editing the local Flume checkout alone does not change built palettes.
