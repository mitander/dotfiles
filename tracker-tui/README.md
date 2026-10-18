# Personal ltui applications

Application changes and the Flume adapter live in
[`mitander/ltui`](https://github.com/mitander/ltui/tree/flume-personal), on branch `flume-personal`.
See the fork's `PERSONAL.md` for behavior, checks, and the upstream update procedure. The fork
preserves upstream's GPL license, notices, and attribution.

`scripts/dotfiles-nix.sh` uses `~/c/p/ltui` when present, including uncommitted edits. Each build
snapshots that checkout into the Nix store. Restart ltui after rebuilding and activating Home
Manager to use the new code. No commit, push, or remote pin update is needed for local development.

```sh
./scripts/dotfiles-nix.sh build
DOTFILES_ALLOW_ACTIVATE=1 ./scripts/dotfiles-nix.sh switch
```

Set `DOTFILES_TRACKER_SOURCE=/path/to/ltui` to use another checkout, or
`DOTFILES_TRACKER_SOURCE=remote` to force the locked remote source. A missing default checkout falls
back to the remote input. An invalid explicit path or broken default checkout fails rather than
silently installing old code. The helper prints its selected source and never writes the lock file.
Direct `nix` commands use the remote input unless given an override:

```sh
nix build --no-link path:.#checks.aarch64-darwin.tracker-tui \
  --override-input tracker-tui "path:$HOME/c/p/ltui" --no-write-lock-file
```

`home/common.nix` builds ltui, jtui, and the adapter from the same `tracker-tui` flake input. The
remote revision lives in `flake.nix`, with its content hash in `flake.lock`. Generate theme data
from a pinned remote Flume palette source at build time. The wrapper points
`FLUME_TRACKER_THEME_DIR` at those store assets, not at a removed directory in Flume.
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
nix build --no-link path:.#checks.aarch64-darwin.tracker-tui
```

Use the appropriate system attribute on Linux. The checks stub application startup and credentials;
they do not contact tracker services or activate Home Manager. The local fork checkout is needed
only for the first command unless the Nix build uses the local input override. Nix downloads the
pinned fork and Flume palette source automatically for remote builds. Builds and CI do not need a
local Flume checkout. Target machines still need the Flume checkout for live runtime theme
switching.

## Update the remote pin

After editing and testing the fork, publish the changes to `mitander/ltui` on `flume-personal`.
Resolve the published commit:

```sh
rev=$(git ls-remote https://github.com/mitander/ltui.git refs/heads/flume-personal | cut -f1)
```

Set the `tracker-tui.url` revision in `flake.nix` to that commit, then run `nix flake lock` to
record its content hash. Rerun the build checks before activation. This updates the fallback for
machines without a local checkout. On a development machine, local edits take effect after
rebuilding and activating through the helper.

For palette changes, resolve the desired published commit of `mitander/flume.nvim`. Compute its
archive hash with `nix store prefetch-file --json --unpack` and the URL
`https://github.com/mitander/flume.nvim/archive/COMMIT.tar.gz`, replacing `COMMIT` with that
revision. Update `flumeSource.rev` and `flumeSource.hash` in `home/common.nix`, then rerun the build
checks. Editing the local Flume checkout alone does not change built palettes.
