"""Checks the Claude Code subagents in DIR/.claude/agents.

Each must have YAML frontmatter with a `name` matching its file name and a
`description`, and every skill it preloads (`skills:`) must exist in
DIR/.agents/skills or DIR/.claude/skills.
"""

import pathlib
import re
import sys

import yaml

NAME = re.compile(r"^[a-z0-9]+(-[a-z0-9]+)*$")


def frontmatter(path):
    text = path.read_text()
    match = re.match(r"^---\n(.*?)\n---\n", text, re.DOTALL)
    if not match:
        raise ValueError("no YAML frontmatter")
    data = yaml.safe_load(match.group(1))
    if not isinstance(data, dict):
        raise ValueError("frontmatter is not a mapping")
    return data


def check(root):
    errors = []
    skill_dirs = [root / ".agents" / "skills", root / ".claude" / "skills"]
    for path in sorted((root / ".claude" / "agents").glob("*.md")):
        before = len(errors)
        try:
            data = frontmatter(path)
        except (ValueError, yaml.YAMLError) as error:
            errors.append(f"{path}: {error}")
            continue
        name = data.get("name")
        if name != path.stem:
            errors.append(f"{path}: name {name!r} doesn't match the file name")
        elif not NAME.match(name):
            errors.append(f"{path}: name must be lowercase letters, digits and hyphens")
        if not isinstance(data.get("description"), str) or not data["description"].strip():
            errors.append(f"{path}: description is missing")
        skills = data.get("skills") or []
        if isinstance(skills, str):
            skills = [s.strip() for s in skills.split(",")]
        for skill in skills:
            if not any((d / skill / "SKILL.md").is_file() for d in skill_dirs):
                errors.append(f"{path}: preloads skill {skill!r}, which doesn't exist")
        if len(errors) == before:
            print(f"{path}: ok")
    return errors


def main():
    errors = check(pathlib.Path(sys.argv[1]))
    for error in errors:
        print(error, file=sys.stderr)
    sys.exit(1 if errors else 0)


if __name__ == "__main__":
    main()
