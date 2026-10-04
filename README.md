# Cursor port of Matt Pocock's skills

These are [Matt Pocock's agent skills](https://github.com/mattpocock/skills) (v1.3.1, MIT), adapted so they run in Cursor. The upstream commit is pinned in [UPSTREAM.md](UPSTREAM.md). The Claude Code to Cursor map is [docs/harness.md](docs/harness.md).

Opening this repo loads the skills from `.cursor/skills/`. To use them in another project, copy them in:

```bash
/path/to/this-repo/scripts/install.sh /path/to/your/project
```

The script copies each skill this repo owns into `<project>/.cursor/skills/` and copies `.cursor/rules/engineering-session.mdc` into `<project>/.cursor/rules/`. Other skills and rules already in that project stay put. Run it again after pulling this repo to refresh the copy. It will not install into this repo.

If the target has a `.gitignore` and does not already ignore `.scratch`, the script appends `.scratch/`. The engineering session file lives there and should stay uncommitted.

## Engineering mode

Grilling and the other multi-turn skills have to stay in context after you answer. Cursor keeps a skill for the whole chat when you use it as a Custom Mode.

1. In chat, type `/engineering`.
2. Press Option+Enter (Mac) or Alt+Enter (Windows), or choose Use as Mode.

The badge says **engineering**. You can also type `/engineering` once without Custom Mode. The always-on rule re-enters the skill on later turns while `.scratch/engineering/session.md` has `status: active`.

While the session is grilling and you have not confirmed a shared understanding, the agent does not edit product code. It may update `GLOSSARY.md` and ADRs. Say you want to implement, or that you are done, and it leaves that gate. Say you are leaving engineering and it sets `status: closed`.

The other skills stay available as `/grill-me`, `/tdd`, and the rest. Custom Mode is what keeps a loop alive across turns. [ask-matt](.cursor/skills/engineering/ask-matt/SKILL.md) is the router for which skill to use.

Run `/setup-matt-pocock-skills` once in a project before the tracker-backed skills (triage, tickets, wayfinder). It writes an `## Agent skills` block to `AGENTS.md`, and to `CLAUDE.md` too when that file already exists.

## Checks

```bash
python3 scripts/validate-skills.py
```
