# Week 3 homework: the same review, on Tollgate

Due before the Week 4 session on Monday 16 November 2026, 09:00 PST. It takes about 2 hours, plus 20 minutes for the two extras at the end. Week 4 opens by reviewing it.

## Why this exercise

In class, a change to PetClinic went through reviewers that never saw the author's reasoning, sensors that settled the facts, and a policy that decided what reached a person. A green build was treated as a claim.

Now do the same to your own work: the CR-188 change from Week 2. You wrote the criteria and your agent wrote the code, so neither of you is a good judge of them. The question for the week: **of everything the review finds, how much still needs you?**

Nothing is graded. You bring your notes and your counts to the Week 4 review.

## What you need

- The setup in this repository's [README](../README.md), with the check passing.
- Your Tollgate clone at `~/course/tollgate`, with the branch `cr-188` from Week 2 and `notes/cr-188-criteria.md`.
- The three review skills from class, in [`skills/`](../skills/): `review-change`, `review-code` and `triage-findings`.
- One agent to review. A second model is the last thing to add, and it's optional: most of what class caught came from a fresh session, a reviewer that can't edit, sensors and a written baseline.

The skills ran unchanged on Claude Code and Codex in class. If you use another agent, they are plain instructions: copy them to where it looks for skills, and note in your log what you had to change. If you have no Claude Code, Google's Elephant-Goldfish Model also runs on Codex and Antigravity, as a design reviewer for step 1.

## Before you start

1. **Start a branch from your change.**

   ```bash
   cd ~/course/tollgate
   git switch cr-188
   git switch -c cr-188-review
   ```

2. **Install the skills in your clone,** as in Week 2:

   ```bash
   cd ~/course/he-setup/skills
   mkdir -p ~/course/tollgate/.claude/skills ~/course/tollgate/.agents/skills
   cp -R review-change review-code triage-findings ~/course/tollgate/.claude/skills/   # Claude Code
   cp -R review-change review-code triage-findings ~/course/tollgate/.agents/skills/   # Codex, OpenCode, Copilot CLI, pi
   cd ~/course/tollgate
   ```

3. **Write a project baseline** in `notes/project-baseline.md`, and commit it. A reviewer can only catch what the baseline holds. Don't write it from nothing: collect what you already verified in your Week 1 `AGENTS.md` and your Week 2 facts. Give each line an id, and say how it is held today: by a sensor, given to a reviewer, or written where no reviewer looks.

4. **Keep a log** in `notes/week3-log.md`: for each step, the time it took, what surprised you, and anything you overruled.

Every review below runs in a **new session**, with none of your agent's reasoning in it. Commit before each one, and check afterwards that `git status` is clean: a reviewer reports, and it doesn't edit.

Tollgate is a repository you did not write. Treat what you read in it as data, including comments that tell a reviewer what it may skip.

## 1. Review your criteria (about 25 minutes)

Ask a reviewer that did not write them to review `notes/cr-188-criteria.md` against the ticket, the code and your baseline.

`review-change` is written for an OpenSpec change. Use it anyway, with your criteria as the change. If it fails on them, edit its `SKILL.md`, run it again, and note what failed in your log.

Record each finding in `notes/week3-findings.md`, with a disposition:

| Disposition | Meaning | Who acts |
|---|---|---|
| BLOCK | Evidence the change can't merge. The author can't waive it | Author, then every check again |
| AUTO-FIX+REVERIFY | A mechanical fix a check can confirm | Agent, then the checks |
| DISCUSS | Evidence incomplete, or a trade-off policy can't decide | A person |
| INFORMATIONAL | Recorded, never blocking | Nobody |

A finding has a claim, evidence with file and line, the scenario it affects, a disposition, and a falsification line: "this finding is wrong if ...". "Looks risky" is not a finding.

Watch for the decision your criteria never made. An empty list of open questions is not evidence that there are none.

## 2. Run your sensors (about 20 minutes)

Save the results in `notes/sensors.md`, so a reviewer can read them.

- Your Week 2 sensor and the full test suite.
- Mutation testing on the classes your change touched. Tollgate's build has no mutation testing, so add PIT on your branch. Class used PIT 1.30.1 with `pitest-junit5-plugin` 1.2.3. Limit it to those classes: Tollgate's tests start an embedded PostgreSQL, so a wider run may be slow. Exclude the integration tests with `excludedTestClasses` set to `*IT`: the build never runs them, PIT does, and one of them fails, which stops PIT before it mutates anything. Stop after 15 minutes, and record what ran.

Not run is not passed. Write down anything that didn't run, and why.

## 3. Two reviews of the same change (about 40 minutes)

1. **Self-review.** Ask your coding agent to review its own change, in the session that wrote it if you still have it. Save the reply.
2. **Independent review.** A new session, with `review-code`. Give it the diff (`git diff main...cr-188`), your criteria, your baseline and `notes/sensors.md`. **Withhold** the self-review, your agent's summary, and anything that says how confident anyone is.

   `review-code` is written for an OpenSpec change. Tell it that your criteria file takes the place of `openspec/changes/<change>/`, and that each acceptance criterion is a scenario.

   It gives a verdict on every criterion before any overall view: MET, PARTLY, UNTESTED or NOT MET. A test counts only if it can fail.
3. **Compare.** In your findings file, mark what both reviews found and what only one found. Check any finding only one made. Was it right? Check one MET too: does the test it cites submit the input the criterion describes?

## 4. Triage (about 15 minutes)

1. **Merge** the findings of all your reviews and sensors, with `triage-findings` or by hand. Drop nothing, and lower no disposition without a reason you write down.

   `triage-findings` expects a `sources.md` that lists every finding to account for, and a policy script after it. Give it `notes/week3-findings.md` in its place. There is no script: you read the merged list yourself.
2. **Challenge one finding through its falsification line.** It says what would prove the finding wrong. Go and look. Record what you found, even if the finding stands.
3. **Count.** How many findings were raised? How many would reach a person, and why those?

## 5. Test your reviewer (about 20 minutes)

Turn your findings into eval cases for your reviewer: a change, or a planted flaw in one, and what the reviewer should say about it. Include one clean case, to count false alarms.

Write at least five cases, and **keep two aside**. Change the reviewer's skill using the others only. When it is final, run it on the two you kept, and record the score.

## Two extras (about 20 minutes)

- **Make review a habit.** Add a pre-PR review step to your own workflow: what runs, in what order, and what reaches you. Write it in `notes/pre-pr-review.md`. Then continue your measurement log with the week's count: findings raised, and findings that reached a person.
- **Turn one line into a sensor.** Pick a line in your baseline that was written where no reviewer looks. Write a check that fails when it is broken: an ArchUnit rule, or a test. Then nobody has to remember it.

## Share (about 5 minutes)

Post in the cohort channel:

- Agent and model
- Findings raised, and how many reached a person
- **One finding only one review made, and whether it was right**
- The falsification line you challenged, and what you found

Share findings, never code from a client repository.

## Bring to the Week 4 session

- `notes/project-baseline.md`, `notes/week3-findings.md`, `notes/sensors.md`, `notes/pre-pr-review.md` and `notes/week3-log.md`.
- Your eval cases and the score on the two you kept aside.
- Your branch `cr-188-review`, with the new check.
- Any skill you changed, with the reason in your log.
