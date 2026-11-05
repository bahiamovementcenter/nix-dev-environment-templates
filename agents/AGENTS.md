# AGENTS.md

Instructions for AI coding agents working in this repository. Keep this file short and
accurate; stale instructions are worse than none.

## Project

<!-- One or two sentences: what this project is and who it's for. -->

## Environment

- Dev environment is a Nix flake. Enter it with `nix develop` (or `direnv allow` if
  nix-direnv is installed). Don't install tools globally; add them to `flake.nix`.
- Run formatters, linters and tests inside the dev shell.

## Commands

<!-- Fill in the real commands. Agents rely on these being exact. -->

- Build: `TODO`
- Test: `TODO`
- Lint/format: `TODO`

## Conventions

<!-- Style, naming, architecture rules that aren't obvious from the code. -->

## Boundaries

- Don't commit secrets, tokens or `.env` files.
- Ask before adding dependencies, changing CI, or touching anything outside this repo.
- Prefer small, reviewable changes.

## Sandboxing

Agents run with the invoking user's permissions. For untrusted or autonomous runs, use the
sandbox tools provided by the dev shell:

- `claudebox`: sandboxed environment for Claude Code.
- `sandbox-runtime`: run any command under filesystem and network restrictions
  (check its `--help` for the command name, usage and settings).
