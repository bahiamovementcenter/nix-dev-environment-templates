#!/usr/bin/env bash
# Installs gstack into this project's .claude/skills the first time a Claude
# Code session starts here, so sessions launched outside the dev shell (cloud
# agents, for one) get it too. Never blocks the session: on any problem it
# says so and exits 0.
set -uo pipefail

cd "${CLAUDE_PROJECT_DIR:-.}" || exit 0

if [ -f .gstack/bootstrap-done ] && [ -d .claude/skills/gstack ]; then
  exit 0
fi

if ! command -v nix >/dev/null 2>&1; then
  echo "gstack: Nix is needed to install gstack here (https://nixos.org/download)" >&2
  exit 0
fi

nix --extra-experimental-features 'nix-command flakes' run .#gstack-bootstrap >&2 \
  || echo "gstack: installing gstack failed; see .gstack/bootstrap.log" >&2
exit 0
