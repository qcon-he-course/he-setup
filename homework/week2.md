# Week 2 homework: a thin ticket on Tollgate

Due before the Week 3 session on Monday 9 November 2026, 09:00 PST. US clocks change on 1 November, so check the time in your own zone. Start by Sunday 1 November: step 2 explains why. It takes about 2 hours. Week 3 opens by reviewing it.

## Why this exercise

In class we fixed one PetClinic bug in nine steps. The bug report told us what should happen: the add form already rejected a future date, so the edit form had to do the same.

A feature ticket usually doesn't say what should happen. This one is CR-188 on Tollgate, and it gives no acceptance criteria. So the work starts one step earlier: turn the ticket into criteria you can test, keeping the facts you looked up apart from the decisions you made. Then do what we did in class: prove, pin, refactor if it helps, change behind a sensor.

Nothing is graded. You bring your notes, your tests and your diff to the Week 3 review.

## The ticket

> **CR-188 · Tollgate · consultation**
> Raised by customer operations
>
> **Add a holiday and extend open deadlines**
>
> The board has declared Friday 30 October 2026 a company day. Add it to the holiday calendar. Hauliers with an open query round must get the extra day.
>
> **Acceptance criteria:** none given.

## What you need

- The setup in this repository's [README](../README.md), with the check passing.
- Your Tollgate clone at `~/course/tollgate`, with the `AGENTS.md` you audited in Week 1 on the `context-draft` branch.
- The three skills from class, in [`skills/`](../skills/): `trace-request`, `prove-bug` and `pin-behavior`.
- One coding agent and one model for the whole exercise. Write down which ones.

## Before you start

1. **Start a branch from `main`, and bring your `AGENTS.md`.** The Week 1 audit left it on `context-draft`. Bring over only that file, so the CR-188 branch holds only CR-188 work.

   ```bash
   cd ~/course/tollgate
   git switch main
   git switch -c cr-188
   git checkout context-draft -- AGENTS.md
   git commit -m "AGENTS.md from Week 1"
   ```

   If your `AGENTS.md` is somewhere else, copy it into the clone and commit it instead.

2. **Reset Tollgate's demo data, on the day you start.** The demo data dates its query rounds from the day it is first loaded. The rounds from your Week 1 database have lapsed, so no round would be open on 30 October. Reset between Tuesday 27 October and Sunday 1 November, and some rounds will be open across 30 October. This deletes Tollgate's local database, which holds only demo data.

   ```bash
   docker compose down -v
   docker compose up -d
   scripts/db-update.sh
   ./mvnw -pl tollgate-app spring-boot:run -Dspring-boot.run.profiles=local
   ```

   The demo data loads on the first start. Leave the application running in its own terminal.

3. **Install the skills in your clone.** Copy each skill folder to where your agent looks for skills:

   ```bash
   cd ~/course/he-setup/skills
   mkdir -p ~/course/tollgate/.claude/skills ~/course/tollgate/.agents/skills
   cp -R trace-request prove-bug pin-behavior ~/course/tollgate/.claude/skills/   # Claude Code
   cp -R trace-request prove-bug pin-behavior ~/course/tollgate/.agents/skills/   # Codex, OpenCode, Copilot CLI, pi
   cd ~/course/tollgate
   ```

   Start a new session and check that the skills are listed (in Claude Code, `/skills`). [`skills/README.md`](../skills/README.md) says what each one does.

4. **Keep a log** in `notes/week2-log.md`: for each step, the time it took, what the agent did that you didn't expect, and anything you corrected.

## 1. Turn the ticket into criteria (about 30 minutes)

Write `notes/cr-188-criteria.md` with three parts.

- **Facts, each with evidence.** What the code does today, with a file and line or a tool result. For example: how a query round's deadline is computed, where holidays come from, when they are read, and what lapses a round. `trace-request` helps here: trace one query round's deadline from the moment the round is issued until it lapses.
- **Decisions, each with a reason.** What the ticket leaves open. For example: what "the extra day" means for a round whose window includes 30 October; what happens to a round issued on 30 October itself; whether a round that has already lapsed gets anything; where the new deadline must show. Customer operations isn't available, so you decide, and you write down why.
- **Acceptance criteria.** One per behavior, each with an expected value you could put in a test: a round, a date, a deadline.

Week 1's question 3 is relevant. Check when the holiday list is read, as well as where it is stored. Check your facts in the running application as well as in the code.

## 2. Prove, then pin (about 40 minutes)

1. **Prove: one failing test per criterion.** `prove-bug` is written for bugs. Use it anyway, with your criteria as the report: the expected value comes from your criteria, never from the code. Each test must fail for the reason the criterion gives. Its step 4 gives a PetClinic example of a good and a bad first failure line. Decide what a good one looks like on Tollgate.
2. **Pin what the change will touch.** Run `pin-behavior` on the code your change will edit. Your failing tests from the step above stay red; the skill leaves them alone.
3. **Change a skill where it fails on Tollgate.** When a skill does something wrong, or misses something, edit its `SKILL.md`, run it again, and note in your log what failed and what you changed. One known gap to start from: `pin-behavior` lets an agent call a pin VERIFIED for the running application when the test replaced part of the framework, for example with a mocked repository. Such a pin shows what the test's setup does, which can differ from what runs. Add a line that stops this, and check that it works.

## 3. Change behind a sensor (about 35 minutes)

1. **Refactor first, if it makes the change easy.** One behavior-preserving refactoring, with every pin green and your criteria tests still red. Skip it if the change is already easy.
2. **Make the change.** Your criteria tests turn green, every pin stays green, and the full suite passes.
3. **Add one Tollgate-specific sensor.** A check that runs and fails when the code is wrong, and that would have caught a mistake you saw in this exercise: a test, an ArchUnit rule, a linter rule. Run it after each change, and count in your log how often it fails and why.
4. **Check the change in the running application.** A test that passes is evidence for what it asserts. Look at a round whose window includes 30 October.

Optional, if you use Claude Code: run your sensor from an agent hook after each edit, as in class. Put the hook in your own settings, and remember Week 1: hooks in a repository's settings run when you trust the folder.

## 4. Share (about 15 minutes)

Post in the cohort channel:

- Agent and model
- Your criteria: how many facts, how many decisions
- **One place where a skill or the agent was wrong, and how you caught it**
- Your sensor, and how often it failed

Share findings, never code from a client repository.

## Bring to the Week 3 session

- `notes/cr-188-criteria.md` and `notes/week2-log.md`.
- Your branch `cr-188`: the failing tests that turned green, the pins, the change and the sensor.
- Any skill you changed, with the reason in your log.

## Optional: write a fourth skill

Class ended with three skills still to write, each with one job:

| Skill | Its one job |
|---|---|
| `fix-behind-tests` | The smallest change that turns the failing test green, then the full suite. |
| `refactor-under-pins` | One behavior-preserving refactoring, with every pin green and the failing test still red. |
| `prevent-bug-class` | After green: the check that stops the class of bug, and the cause, from the history. |

Write one. Test it the way we tested ours: the same task, with and without the skill, at least twice each, and a check you can repeat. Bring the results.
