# Skills from class

Portable skills, one job each. Each is a folder with a `SKILL.md`.

## Week 2

| Skill | Its one job | Use it |
|---|---|---|
| `trace-request` | Trace what one request goes through, from a captured or reproduced request to the code that handles it, labelling each step VERIFIED, INFERRED or UNKNOWN | Before changing code you did not write |
| `prove-bug` | Write a failing test that shows the reported symptom, and stop there | When a bug is reported and no test fails because of it yet |
| `pin-behavior` | Pin what the code does now with passing tests | Before refactoring, restructuring or moving logic |

### Install them in your Tollgate clone

```bash
cd ~/course/he-setup/skills
mkdir -p ~/course/tollgate/.claude/skills ~/course/tollgate/.agents/skills
cp -R trace-request prove-bug pin-behavior ~/course/tollgate/.claude/skills/   # Claude Code
cp -R trace-request prove-bug pin-behavior ~/course/tollgate/.agents/skills/   # Codex, OpenCode, Copilot CLI, pi
```

## Week 3

| Skill | Its one job | Use it |
|---|---|---|
| `refine-requirement` | Interview you about a ticket before it is specified, one round of numbered questions at a time, and write down what is settled as it is settled: terms in `GLOSSARY.md`, decisions in the change's decisions log, hard-to-reverse trade-offs as ADRs | Before a change is specified, when you ask to be grilled on a ticket |
| `review-change` | Review a change before any code is written, as a reviewer that did not write it, and report findings with a disposition each, ending with the questions only a person can answer | On criteria, a proposal, a spec delta or a design |
| `review-code` | Review the code of a change after the sensors have run, with a verdict on every scenario before any overall view | On a finished change, with the sensor results |
| `triage-findings` | Merge the findings of several reviews and the sensor results into one list, dropping none and lowering no disposition | After the reviews, before a person decides |

The skills were written for an OpenSpec change on PetClinic. The Week 3 homework uses the three review skills on your CR-188 criteria and code: when one fails there, edit its `SKILL.md` and note what you changed. The review skills report and never edit: run each in a new session, and check afterwards that `git status` is clean. `refine-requirement` is adapted from Matt Pocock's `grilling`, `domain-modeling` and `grill-with-docs` skills (MIT, licence in its folder), and `review-change`'s check for missing work, added scope and wrong work comes from the Spec axis of his `code-review` skill.

### Install them in your Tollgate clone

```bash
cd ~/course/he-setup/skills
cp -R review-change review-code triage-findings ~/course/tollgate/.claude/skills/   # Claude Code
cp -R review-change review-code triage-findings ~/course/tollgate/.agents/skills/   # Codex, OpenCode, Copilot CLI, pi
```

The homework does not use `refine-requirement`. To try it, copy it the same way.

## After installing

Start a new session and check that the skills are listed (in Claude Code, `/skills`).

The skills are a starting point. When one does something wrong on your code, edit its `SKILL.md`, run it again, and note what you changed.
