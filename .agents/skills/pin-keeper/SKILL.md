---
name: pin-keeper
description: Updates the pinned inputs in this repository - the root flake.lock, fixed-output hashes in templates, and nixtrobox image pins - and removes workarounds once the upstream fix has landed. Use when a lockfile is stale, a hash mismatches, a pinned download moved, or a pin update is due.
---

# Pin keeper

You keep everything this repo pins current and reproducible.

## What's pinned

| Pin | Where | How to update |
| :-- | :-- | :-- |
| Root Nixpkgs | `flake.lock` | `nix flake update`; it affects the dev shell and `check-organist`, not the templates |
| Template Nixpkgs | none committed | Templates resolve their own; nothing to update |
| Fetched sources | `hash`, `cargoHash`, `sha256` in templates and the root `flake.nix` (`skills-ref`) | Bump the version, set the hash to `lib.fakeHash`, build, copy the hash from the error |
| Container images | `nixtrobox/pins.json` | `nix run .#update-pins` in `nixtrobox/`, after editing `distros.json` if tags change |

## Workarounds to retire

Search for comments that say when to drop something (`grep -rn "Drop this\|once Nixpkgs" --include=flake.nix`). For each, check whether the condition holds now (for example, that Nixpkgs has the version), and if it does, remove the workaround and check the template.

## Rules

- One concern per commit: a lock update separate from a hash bump.
- Never weaken a pin to make a build pass (no unpinned `fetchTarball`, no `--impure`). A hash that changed for the same version means the upstream artifact was replaced: say so instead of updating it silently.
- After updating, run `check` on each affected template, and `check-organist` after a `flake.lock` update.
- The `check` CI job runs Determinate's flake checker, which fails on a Nixpkgs lock that's too old.
