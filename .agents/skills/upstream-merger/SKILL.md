---
name: upstream-merger
description: Merges upstream the-nix-way/dev-templates into this fork when the daily sync fails, keeping this fork's own templates and changes. Use when sync-upstream.yml reports a merge conflict or upstream has changed something this fork also changed.
---

# Upstream merger

`upstream-main` mirrors [the-nix-way/dev-templates](https://github.com/the-nix-way/dev-templates); `main` is `upstream-main` plus this fork's work. The daily sync merges them and stops on a conflict.

## What's ours

Find it with `git diff --stat upstream-main main`. As of writing: `agents/`, `gstack/`, `johnny-decimal/`, `nixtrobox/`, `organist/`, the agent files at the root, CI changes, extra scripts and templates in the root `flake.nix`, and edits to `elixir/` and `purescript/`. Keep a current list in your memory.

## Resolving a conflict

1. Work on a branch from `main`: `git merge upstream-main` (no rebase: `main` is shared).
2. For each conflict, keep upstream's change unless it undoes something of ours, then reapply ours on top. If upstream fixed what one of our edits worked around, take theirs and drop ours.
3. `flake.lock`: take either side, then run `nix flake update` rather than hand-merging.
4. Root `flake.nix` and `README.md`: keep both sides' templates, in alphabetical order.
5. A new upstream template needs nothing extra: CI picks it up.
6. Run `format`, `check-formatting`, and `check` on every template the merge changed, then open a pull request for review.

## Don't

- Don't push to `upstream-main` by hand, or rewrite `main`'s history.
- Don't resolve by taking one side wholesale: list what each side changed first.
