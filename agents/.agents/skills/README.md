# Agent skills

Each folder here is one skill in the
[Agent Skills](https://agentskills.io/specification) format: a `SKILL.md`
with `name` and `description` frontmatter, and optionally `scripts/`,
`references/` and `assets/`. The `name` must match the folder name.

`.agents/skills/` is the location Agent Skills clients scan for skills shared
across tools. Claude Code reads `.claude/skills/` instead, which is a symlink
to this folder, so both find the same skills.

This file isn't a skill; skill scanners only look at folders with a
`SKILL.md`.
