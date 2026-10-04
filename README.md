# Cursor port of Matt Pocock's skills

This repository adapts the skills from [mattpocock/skills](https://github.com/mattpocock/skills) (v1.3.1) so they run in Cursor. Matt Pocock wrote the upstream skills. He did not write the Cursor adaptations and does not maintain this repository. The upstream commit is pinned in [UPSTREAM.md](UPSTREAM.md). The Claude Code to Cursor map is [docs/harness.md](docs/harness.md).

The original skill text stays under his MIT copyright notice, which the license requires us to keep. The adaptations are also MIT and are not attributed to him. See [LICENSE](LICENSE).

Opening this repo loads the skills from `.cursor/skills/`. To use them in another project, copy them in:

```bash
/path/to/this-repo/scripts/install.sh /path/to/your/project
```

The script copies each skill this repo owns into `<project>/.cursor/skills/` and copies `.cursor/rules/engineering-session.mdc` into `<project>/.cursor/rules/`. Other skills and rules already in that project stay put. A refresh replaces the skill folders this repo owns, including files added inside those folders. Run it again after pulling this repo to refresh the copy. It will not install into this repo.

If the target has a `.gitignore` and does not already ignore `.scratch`, the script appends `.scratch/`. The engineering session file lives there and should stay uncommitted.

## Engineering mode

Grilling and the other multi-turn skills have to stay in context after you answer. Cursor keeps a skill for the whole chat when you use it as a Custom Mode.

1. In chat, type `/engineering`.
2. Press Option+Enter (Mac) or Alt+Enter (Windows), or choose Use as Mode.

The badge says **engineering**. You can also type `/engineering` once without Custom Mode. The always-on rule re-enters the skill on later turns while `.scratch/engineering/session.md` has `status: active`.

The grill gate applies only while the session phase is grilling. Triage, teaching, wayfinder, and diagnosing a bug are not under it. During a grill the agent does not edit production code. It may update `GLOSSARY.md`, ADRs, and a throwaway prototype. Naming another skill, or confirming a shared understanding and asking to build, leaves the gate. A phase boundary that discards context sets `status: closed` first, so the next chat does not reload the old design tree. Say you are leaving engineering and it sets `status: closed` too.

The other skills stay available as `/grill-me`, `/tdd`, and the rest. Custom Mode is what keeps a loop alive across turns. [ask-matt](.cursor/skills/engineering/ask-matt/SKILL.md) is the router for which skill to use.

Run `/setup-matt-pocock-skills` once in a project before the tracker-backed skills (triage, tickets, wayfinder). It writes an `## Agent skills` block to `AGENTS.md`, and to `CLAUDE.md` too when that file already exists.

## License

Upstream skill text: Copyright (c) 2026 Matt Pocock, MIT License. Cursor adaptations in this repository: MIT License, not attributed to him. Details are in [LICENSE](LICENSE).

## Checks

```bash
python3 scripts/validate-skills.py
```
