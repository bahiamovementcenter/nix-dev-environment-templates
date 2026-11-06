---
name: ci-steward
description: Maintains this repository's GitHub Actions CI - which templates a run checks, how long runs take, and why a run failed. Use when changing .github/workflows, when CI is slow, or when diagnosing a red check.
---

# CI steward

`.github/workflows/ci.yml` checks templates; `.github/workflows/sync-upstream.yml` merges upstream daily.

## How ci.yml decides what to check

- The `changes` job lists the templates a run checks:
  - pull requests: `HEAD^1..HEAD`, the merge commit against its first parent (the event's base SHA can be older than `main`);
  - pushes: `github.event.before..HEAD`, or `HEAD^..HEAD` for a new branch;
  - weekly schedule, tags and manual runs without a `templates` input: every template.
- A change to the root `flake.nix` or `ci.yml` adds `empty`, the smallest template, so the check script itself is exercised.
- `organist` runs when `organist/`, a template it was ported from, `flake.lock` or `ci.yml` changes; it needs `NIX_CONFIG: lazy-trees = false`.
- `agents` runs when agent files (`agents/`, `.agents/`, `.claude/`, `AGENTS.md`, `CLAUDE.md`), the root `flake.nix` or `ci.yml` change.
- `determinate-ci` needs every job and runs with `!failure() && !cancelled()`, so skipped jobs don't block it.

## Keeping it fast

Checking a template builds its whole shell, so a full run takes hours: never make pull requests check every template. `concurrency` cancels superseded runs. When adding a job, give it an output in `changes` and an `if:` on that output.

## Diagnosing a failure

1. Read the failing job's log, not just its name.
2. Ask whether the failure is this change's: is the same check red on `main`? A template that wasn't touched failing usually means Nixpkgs moved.
3. Reproduce locally with the same script CI runs (`nix develop --command check <template>`), then fix the cause. Re-run a job at most once, and never skip or disable a check to get green.

## sync-upstream.yml

It mirrors upstream to `upstream-main` and merges that into `main`, failing on a conflict (hand that to the `upstream-merger` persona). Pushing workflow changes needs the `SYNC_TOKEN` secret, a token with `workflow` scope.
