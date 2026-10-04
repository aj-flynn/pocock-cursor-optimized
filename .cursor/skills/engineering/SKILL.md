---
name: engineering
description: Persistent engineering session for these skills. Keeps the design tree on disk and re-reads the active child skill every turn. Use as a Custom Mode, or invoke /engineering, when grilling, triage, wayfinder, diagnosing bugs, or another multi-turn skill must survive later turns.
disable-model-invocation: true
icon: code
color: orange
---

# Engineering

This is the Cursor session mode for these skills. Custom Mode keeps this file in context on every turn. Typing `/engineering` once does not, so the session file and the always-apply rule re-enter this skill on later turns.

Harness differences from Claude Code are in [HARNESS.md](HARNESS.md). Follow that file when you dispatch a Task subagent, read another skill, or change phase.

## Every turn

Before you answer:

1. Read `.scratch/engineering/session.md`. If it is missing, or `status` is not `active`, this invocation is entry: create it as specified below.
2. Re-read the `SKILL.md` for every skill listed in `active_skills`. Find each folder under `.cursor/skills/` whose frontmatter `name` matches.
3. Do the work for this turn.
4. Write the session file again before the reply. It is the source of truth for the design tree. Conversation memory is not.

## Session file

```markdown
---
status: active
phase: grilling
active_skills:
  - grilling
  - domain-modeling
confirmed_understanding: false
---

## Settled

- 

## Frontier

- 

## Notes

```

- `status` is `active` or `closed`.
- `phase` is `grilling`, `building`, `diagnosing`, `wayfinding`, or `idle`.
- `active_skills` is the list of child skills to re-read. One name per line.
- `confirmed_understanding` is `true` or `false`.
- `Settled` is every decision already made, in the user's words where you have them.
- `Frontier` is every open decision whose prerequisites are settled. Recompute it after each reply.

## Entry

If the user named a skill, set `active_skills` to that skill and set `phase` to match:

- `diagnosing-bugs` sets `diagnosing`
- `wayfinder` sets `wayfinding`
- `implement`, `implement-spec`, or `tdd` sets `building`
- otherwise `grilling`

If they did not name a skill:

- In a repo, start grill-with-docs. `active_skills` is `grilling` and `domain-modeling`. `phase` is `grilling`.
- Outside a repo, start grill-me. `active_skills` is `grilling` only. `phase` is `grilling`.

## Grill gate

While `phase` is `grilling` and `confirmed_understanding` is `false`:

- Do not edit product code.
- You may edit `GLOSSARY.md` and ADRs. Grill-with-docs writes those inline.
- Ask the frontier in the grilling format, record settled decisions and the new frontier in the session file, then wait.
- Set `confirmed_understanding: true` only when the frontier is empty and the user has confirmed a shared understanding.

Leave the gate when the user explicitly starts `implement`, `tdd`, or `diagnosing-bugs`, or confirms understanding and asks you to build. Set `phase` and `active_skills` to that work, then read and follow those skills.

## Leaving

When the user says to leave engineering, set `status: closed` and stop following this skill.
