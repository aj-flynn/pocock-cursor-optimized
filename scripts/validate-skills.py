#!/usr/bin/env python3
"""Check skill frontmatter and the Cursor harness rewrite."""

from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[1]
SKILLS = ROOT / ".cursor" / "skills"

USER_INVOKED = {
    "ask-matt",
    "engineering",
    "grill-me",
    "grill-with-docs",
    "handoff",
    "implement",
    "implement-spec",
    "improve-codebase-architecture",
    "retro",
    "setup-matt-pocock-skills",
    "teach",
    "to-questionnaire",
    "to-spec",
    "to-tickets",
    "triage",
    "wait-what",
    "wayfinder",
}

MODEL_INVOKED = {
    "code-review",
    "codebase-design",
    "diagnosing-bugs",
    "domain-modeling",
    "grilling",
    "pr",
    "prototype",
    "research",
    "tdd",
    "wizard",
    "writing-for-agents",
}

FORBIDDEN = ("Skill tool", "/compact", "/clear", "beside the engineering skill", "argument-hint")


def frontmatter(text: str, path: Path) -> tuple[dict[str, str], str]:
    if not text.startswith("---\n"):
        raise SystemExit(f"{path}: missing frontmatter")
    end = text.find("\n---\n", 4)
    if end < 0:
        raise SystemExit(f"{path}: unclosed frontmatter")
    data: dict[str, str] = {}
    for line in text[4:end].splitlines():
        if not line or line[0].isspace() or line.startswith("#"):
            continue
        if ":" not in line:
            continue
        key, value = line.split(":", 1)
        data[key.strip()] = value.strip().strip('"')
    return data, text[end + 5 :]


def main() -> int:
    errors: list[str] = []
    found: set[str] = set()
    for path in sorted(SKILLS.rglob("SKILL.md")):
        data, body = frontmatter(path.read_text(), path)
        name = data.get("name", "")
        folder = path.parent.name
        found.add(name)
        if name != folder:
            errors.append(f"{path}: name {name!r} does not match folder {folder!r}")
        if not data.get("description"):
            errors.append(f"{path}: missing description")
        disabled = data.get("disable-model-invocation") == "true"
        if name in USER_INVOKED and not disabled:
            errors.append(f"{path}: user-invoked skill must set disable-model-invocation: true")
        if name in MODEL_INVOKED and disabled:
            errors.append(f"{path}: model-invoked skill must not set disable-model-invocation: true")
        if name not in USER_INVOKED and name not in MODEL_INVOKED:
            errors.append(f"{path}: {name!r} is not in the user-invoked or model-invoked set")
        if name != "engineering" and ("icon" in data or "color" in data):
            errors.append(f"{path}: icon and color belong only on the engineering skill")
        if name == "engineering" and (data.get("icon") != "code" or data.get("color") != "orange"):
            errors.append(f"{path}: engineering mode badge must be icon code and color orange")
        raw_front = path.read_text().split("\n---\n", 1)[0]
        for token in FORBIDDEN:
            if token in body or token in raw_front:
                errors.append(f"{path}: still contains {token!r}")

    expected = USER_INVOKED | MODEL_INVOKED
    missing = expected - found
    extra = found - expected
    if missing:
        errors.append(f"missing skills: {', '.join(sorted(missing))}")
    if extra:
        errors.append(f"unexpected skills: {', '.join(sorted(extra))}")

    harness = ROOT / "docs" / "harness.md"
    installed = SKILLS / "engineering" / "HARNESS.md"
    if harness.read_text() != installed.read_text():
        errors.append("docs/harness.md and .cursor/skills/engineering/HARNESS.md differ")

    if errors:
        print("\n".join(errors), file=sys.stderr)
        return 1
    print(f"ok: {len(found)} skills")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
