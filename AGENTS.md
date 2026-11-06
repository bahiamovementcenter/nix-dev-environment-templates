# AGENTS.md

Nix flake templates for development environments: a fork of [the-nix-way/dev-templates](https://github.com/the-nix-way/dev-templates) with templates of its own. Each top-level directory with a `flake.nix` is a template; the root `flake.nix` lists them and defines the dev shell with this repo's tooling.

## Setup

Enter the dev shell with `nix develop` (or `direnv allow`). If flakes aren't enabled, add `--extra-experimental-features 'nix-command flakes'`.

## Build and test

All from the dev shell (`nix develop --command <script>`):

| Script | What it does |
| :-- | :-- |
| `check [TEMPLATE…]` | `nix flake check --all-systems --no-build` and a dev shell build, for the templates named or every template |
| `build [TEMPLATE…]` | Builds each template's dev shell for the current system |
| `check-formatting` / `format` | `nixfmt` on every tracked `.nix` file |
| `check-organist [TEMPLATE…]` | Compares `organist/*` with the templates they were ported from (needs `lazy-trees = false` on Determinate Nix) |
| `check-vendored` | Checks that templates' copies of packages in `pkgs/` are identical to the originals |
| `check-agents [DIR…]` | Validates skills, subagents, `.claude/settings.json` and the `.claude/skills` symlink, here and in `agents/` |

Checking a template builds its whole shell, so check only the templates you changed. CI does the same: see `.github/workflows/ci.yml`.

## Code style

- Run `format` before committing; CI fails on unformatted Nix.
- Templates follow one shape: `supportedSystems` (`x86_64-linux`, `aarch64-linux`, `aarch64-darwin`), `forEachSupportedSystem`, `devShells.<system>.default`, and `formatter` set to `nixfmt`, with Nixpkgs from `https://flakehub.com/f/NixOS/nixpkgs/0.1`.
- Comments say why, not what. Pin anything fetched by hash, and say in a comment when a workaround can be dropped.
- A package Nixpkgs lacks goes in `pkgs/<name>.nix`, in `callPackage` form, and the root flake exports it (`packages`, `overlays.default`). A template that needs it keeps an identical copy in its own `pkgs/` and calls `pkgs.callPackage ./pkgs/<name>.nix { }`, so it stays self-contained; edit the original and copy it over.

## Commits and pull requests

- Develop on a branch and open a pull request against `main`; don't push to `main` or `upstream-main`.
- Commit subjects start with the area: `rust: …`, `CI: …`, `johnny-decimal: …`.
- `upstream-main` mirrors upstream and is merged into `main` daily by `.github/workflows/sync-upstream.yml`; keep changes to upstream's templates small so those merges stay clean.

## Personas

Four roles for maintaining this repo, each an Agent Skill in `.agents/skills/` that any agent can load (Claude Code also has each as a subagent in `.claude/agents/`):

| Persona | Use it to |
| :-- | :-- |
| `template-author` | Add, change or port a template |
| `pin-keeper` | Update `flake.lock`, fixed-output hashes, nixtrobox image pins, and drop workarounds once upstream fixes land |
| `ci-steward` | Change CI: which templates a run checks, how long it takes, why it failed |
| `upstream-merger` | Resolve a failed upstream sync |

What a persona learns about this repo goes in `.claude/agent-memory/<persona>/MEMORY.md`, which is committed; keep it short and factual.
