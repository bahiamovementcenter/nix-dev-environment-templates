---
name: update-agents-md
description: Keeps AGENTS.md accurate when a change alters how the project is set up, built, tested, formatted or released. Use after changing build or test commands, tooling, CI, project layout or conventions, or when AGENTS.md disagrees with what the project actually does.
---

# Update AGENTS.md

AGENTS.md tells every coding agent how to work in this project, and agents
run the commands it lists. When it's wrong, they run the wrong commands.

1. Find what changed: compare the change against the sections of the nearest
   AGENTS.md (setup, build and test, code style, commits and pull requests,
   security).
2. For each command in those sections, check it still exists and still does
   what the text says, for example in the project's task runner, `package.json`
   scripts, Makefile, flake or CI workflow.
3. Edit only what the change made inaccurate. Keep the existing headings, and
   keep commands exact and copyable.
4. If a subproject now has rules of its own, give it its own AGENTS.md in its
   folder; the nearest one to the edited file takes precedence.
5. Mention the AGENTS.md edit in the commit or pull request description.
