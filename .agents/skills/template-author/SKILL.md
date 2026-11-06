---
name: template-author
description: Adds, changes or ports a Nix flake template in this repository, keeping the root flake.nix, README and CI in step. Use when creating a template for a new language or tool, changing what a template's dev shell provides, or porting a template to Organist.
---

# Template author

You maintain the templates: each top-level directory with a `flake.nix` (plus `organist/*`).

## Adding a template

1. Copy the closest existing template (for a plain toolchain, `go/` or `zig/`), keeping its shape: `supportedSystems`, `forEachSupportedSystem`, `devShells.<system>.default` and `formatter = nixfmt`. Use `mkShellNoCC` unless the shell needs a C compiler.
2. Pin Nixpkgs to `https://flakehub.com/f/NixOS/nixpkgs/0.1`. Don't commit a `flake.lock` in the template: the root `.gitignore` excludes them, so each user resolves their own.
3. Add `.envrc` with `use flake` if the template ships one (most do).
4. Register it in the root `flake.nix` under `templates`, alphabetically, with a one-line description.
5. In `README.md`, add a row to "Available templates" and a section under "Template contents", both alphabetical, and any link reference the row uses.
6. Run `format`, then `check <template>`. CI picks up any directory with a `flake.nix`, so there's nothing to add to the workflow.

## Changing a template

- Upstream owns most templates (compare with the `upstream-main` branch). Change one only when it's broken or the change is ours to keep, and keep the diff small so the daily upstream merge stays clean; consider contributing it upstream instead.
- Something fetched outside Nixpkgs needs a pinned hash: build once with `lib.fakeHash` and copy the hash from the error.
- A workaround gets a comment saying when to drop it, with a link to the upstream fix (see `purescript/flake.nix`).

## Porting to Organist

Organist templates live in `organist/<name>/` (`project.ncl` plus a generated `flake.nix`) and are registered as `organist-<name>`. Add the original and its smoke commands to `organist/parity.json`, then run `check-organist <name>` with `NIX_CONFIG='lazy-trees = false'` on Determinate Nix. Organist uses import from derivation, so `check` skips these.

## Before you finish

- `check-formatting` passes and `check <template>` passes for every template you touched.
- README and root `flake.nix` list the template; the description matches.
