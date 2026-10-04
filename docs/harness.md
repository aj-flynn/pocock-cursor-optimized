# Cursor harness map

This is the Claude Code to Cursor map for these skills. The same text ships with the skills at `.cursor/skills/engineering/HARNESS.md`, so a project that installed the skills can still read it. Keep the two files identical.

## Read a skill

Cursor has no Skill tool. A slash name in prose does not load a skill on later turns.

To run a skill, find the folder under `.cursor/skills/` whose `SKILL.md` frontmatter `name` matches, read that file, and carry out its instructions. Two skills means two reads, one skill each. Do this again at the start of each later turn while that skill is still active.

A user-invoked skill (`disable-model-invocation: true`) is for the human to start. Tell them to run it. Do not read it on their behalf, except `setup-matt-pocock-skills`, which the human runs once per repo.

## Task subagents

Where a skill says to dispatch a sub-agent, use Cursor's Task tool.

- Read-only fact-finding: `subagent_type` `explore`.
- Implementation, review, research, and design: `subagent_type` `generalPurpose`.
- The subagent does not see this conversation. Put the full brief in its prompt, including the path of any `SKILL.md` it must follow.
- Set `run_in_background` when this session should keep working. Research and implement-spec implementers are the usual case.
- Parallel reviews and design-it-twice alternatives are separate Task calls in one turn.
- Implement-spec uses one Task per ready ticket. When the environment supports git worktrees, one worktree per ticket. Otherwise one branch at a time, and serialize the merges.

## Questions

Ask in the skill's own format and wait for the next user message. Grilling uses numbered frontier questions with a recommended answer. Cursor's structured question UI belongs to Plan mode, not to this custom mode. If an AskQuestion tool is actually in the tool list, you may use it for that same frontier round.

## Phase changes

There is no `/clear` and no `/compact`.

- Continue when the next phase needs this conversation as a primary source.
- Start a new chat when the current context is disposable. Close `.scratch/engineering/session.md` first if the next chat should not resume engineering mode. The old chat stays in history.
- Read and follow the `handoff` skill when the work must travel: a new directory, a colleague, or a side task forked mid-phase.
- Use a Task subagent when the task can run without the user.
- Otherwise write a handoff that says what the next phase must keep, and start a new chat from that file. That is the lossy default, not the first reach.

The engineering session file is what survives a new chat. Conversation memory is not.

## Steering files

`setup-matt-pocock-skills` writes the `## Agent skills` block to `AGENTS.md`. If `CLAUDE.md` already exists, update that file too. Do not create `CLAUDE.md` when it is absent.

## What stays the same

`disable-model-invocation: true` still means the human must invoke the skill. These skills do not use Claude-only frontmatter (`context: fork`, `allowed-tools`, `hooks`, shell injection). Custom Mode cannot lock tools the way Plan mode can. The engineering skill's grill gate is an instruction: no product edits until understanding is confirmed. `GLOSSARY.md` and ADRs are allowed during that gate.
