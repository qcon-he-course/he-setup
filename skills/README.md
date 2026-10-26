# Skills from Week 2

Three portable skills, one job each. Each is a folder with a `SKILL.md`.

| Skill | Its one job | Use it |
|---|---|---|
| `trace-request` | Trace what one request goes through, from a captured or reproduced request to the code that handles it, labelling each step VERIFIED, INFERRED or UNKNOWN | Before changing code you did not write |
| `prove-bug` | Write a failing test that shows the reported symptom, and stop there | When a bug is reported and no test fails because of it yet |
| `pin-behavior` | Pin what the code does now with passing tests | Before refactoring, restructuring or moving logic |

## Install them in your Tollgate clone

```bash
cd ~/course/he-setup/skills
mkdir -p ~/course/tollgate/.claude/skills ~/course/tollgate/.agents/skills
cp -R trace-request prove-bug pin-behavior ~/course/tollgate/.claude/skills/   # Claude Code
cp -R trace-request prove-bug pin-behavior ~/course/tollgate/.agents/skills/   # Codex, OpenCode, Copilot CLI, pi
```

Start a new session and check that the skills are listed (in Claude Code, `/skills`).

The skills are a starting point. When one does something wrong on your code, edit its `SKILL.md`, run it again, and note what you changed.
