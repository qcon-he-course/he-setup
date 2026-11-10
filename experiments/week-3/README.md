# Week 3 experiments: e12 to e23

These are the experiments from the Week 3 session, set up so you can run them yourself. They use the same container, layers, prompts and sensors as in class. One PetClinic change, PC-301 (record a pet's microchip number), goes through every step: a baseline spec, the requirement refined, a review before code, the code, the sensors, an independent review, triage and the fixes. Two scripted experiments follow: e22 tests the reviewer on planted flaws, and e23 takes a smaller change, PC-303, to see whether it can merge without a person.

The last class run of each step is included: the one the next step started from. So you can start at any step with `./demo.sh apply`, and compare your run with ours.

All the steps work on one PetClinic clone. Each step starts from the state the previous one left, in this order:

| Step | What happens | Layers | Agent |
|---|---|---|---|
| e12 | Step 1: turn the Week 2 class pins into an OpenSpec baseline spec | w3-base | Claude |
| e13 | Step 2: `refine-requirement` interviews you about PC-301, and writes the decisions log and `GLOSSARY.md`. Always interactive: you answer | w3-base, w3-skills | Claude |
| e14 | Step 2: OpenSpec's `openspec-propose` writes the change (proposal, spec delta, design, tasks) from e13's decisions log | w3-base, w3-openspec | Claude |
| e15 | Step 3: `review-change` reviews the change before any code, in a fresh session that can't edit files | w3-base, w3-skills, w3-reviewer | Claude or Codex |
| e16 | Step 3, after the gate: the author revises the change from a person's answers (`e15-review-before-code/gate-*.md`) and the reviews they name | w3-base, w3-openspec | Claude |
| e17 | Step 4: OpenSpec's `openspec-apply-change` codes the change and `e17-code-the-change/handoff.md`'s extra tasks, then reviews its own diff. The checks that judge the change are mounted read-only | w3-base, w3-apply, w3-author, w2-sensors, w3-conventions | Claude |
| e18 | Step 5: the sensors, with no agent: risk floor, test-delta audit, glossary check, architecture rule, full suite, mutation testing, and the MySQL and Postgres tests on your machine's Docker | none | none |
| e19 | Step 6: `review-code` reviews the code with e18's `sensors.md`, never the author's self-review | w3-base, w3-skills, w3-reviewer | Claude or Codex |
| e20 | Step 7: a clerk (`triage-findings`) merges every open finding; `sensors/triage.py` audits the merge, applies the policy and writes `packet.md` for the person | w3-base, w3-skills, w3-reviewer | Claude |
| e21 | Back to step 4: the author works through a person's answers to the packet (`e20-triage/gate-*.md`) | as e17 | Claude |
| e22 | Step 8: a clean case and six planted flaws (`e22-test-the-reviewer/cases/`), each through e18 and e19, then scored | as e18 and e19 | Claude and Codex |
| e23 | Step 8: PC-303, a bounded change with its decisions made, from the author to the packet's "Merges without a person" row | as e14 to e21 | Claude and Codex |

## What you need

- **The setup from Week 1**, in the [README](../../README.md) of this repository, with JDK 17, git and Python 3. e18 runs the MySQL and Postgres tests with `./mvnw` on your machine.
- **Docker.** Docker Desktop, OrbStack or Colima on macOS; Docker Engine with the compose plugin on Linux. The image and Maven's cache need a few gigabytes of disk. The agent's containers never get the Docker socket.
- **Claude Code and a token.** The agent runs in the container with the token from `claude setup-token`, which needs a Pro, Max, Team or Enterprise plan. The runs use Claude Opus 5.5. To use another model, set `LADDER_MODEL`, for example `export LADDER_MODEL=claude-sonnet-5-5`.
- **An OpenAI API key, for the Codex reviewer only.** e15 and e19 can run on Codex CLI with `LADDER_AGENT=codex`, and e22 and e23 run one Codex review per case by default. Set `CODEX_API_KEY` in your shell. Without it, e22 and e23 run with `E22_CODEX_RUNS=0` or `E23_CODEX_RUNS=0`.
- **Time and money for e22 and e23.** e22 takes about 20 minutes and $6 a case, for seven cases. e23's clean case takes about 1.5 hours. Both bill your Claude plan and your OpenAI key.

You can read every class run without Docker or a token: `./demo.sh show` needs only Python and git.

**Where this has been checked.** In class, on macOS with Colima, from the course's own copy of these files. This copy differs only in its paths and in two fixes noted below; its image build hasn't been run from this repository yet. Linux and WSL haven't been checked. Tell us in Slack if something doesn't work.

## Set up, once

From this folder:

```bash
export CLAUDE_CODE_OAUTH_TOKEN=<your token>
export CODEX_API_KEY=<your OpenAI key>    # only for the Codex reviewer
./demo.sh build      # the image, he-week3: a few minutes the first time
./demo.sh reset      # the agent's clone of PetClinic, at week-3-start
./demo.sh check      # should end with "demo: ready"
```

`reset` puts the agent's clone in `~/.cache/qcon-he/week3/petclinic`. In a new terminal, export the token again before you run a step. `./demo.sh help` lists every command and setting.

## Run a step

```bash
./demo.sh e12                     # interactive: paste the prompt, approve, /exit
LADDER_BATCH=1 ./demo.sh e15      # unattended, with the step's prompt
LADDER_BATCH=1 LADDER_AGENT=codex ./demo.sh e15     # the same review on Codex
./demo.sh watch                   # in a second terminal: follow the newest run
```

Interactive runs work as in Week 2: `demo.sh` prints the step's layers and the clone's state, and starts Claude Code in the container. On macOS the prompt is on the clipboard; elsewhere, `demo.sh` prints where the prompt file is. Trust the folder, paste the prompt, and leave with `/exit` when the agent is done.

Each run is saved in the step's folder under `runs/<date-time>-<model>/`: the prompt, the transcript, the managed configuration it ran with, the diff before and after, and the step's output (`review.md`, `self-review.md`, `sensors.md` or `packet.md`). Git ignores your runs.

## Start from where class was

`./demo.sh apply <step>` puts the clone in the state the newest run of that step left. With the class runs, that is how to skip to any step:

| To run | First |
|---|---|
| e13 | `./demo.sh apply e12`, or `./demo.sh baseline` for the curated baseline spec the later steps used |
| e14 | `./demo.sh apply e13` |
| e15, e16 | `./demo.sh apply e14` for the first review; `./demo.sh apply e16` for the review of the final revision |
| e17 | `./demo.sh apply e16` |
| e18 | `./demo.sh apply e17`, or `./demo.sh apply e21` for step 8's base |
| e19 | e18 first: it reads the newest e18 run's `sensors.md` |
| e20 | e18 and e19 first: it reads the newest e18 run, the newest e19 run per model, and the last review before code (`W3_STEP3_RUN`) |
| e21 | `./demo.sh apply e17` |
| e22, e23 | nothing: their scripts set up the clone |

`apply` replaces the clone's own changes. `./demo.sh show <step> [run]` shows what a run did: its packet, its sensors, or the agent's steps and final answer.

The class runs included:

| Step | Run | What it is |
|---|---|---|
| e12 | `20261031-184816-claude-opus-5-5` | The baseline spec from the pins |
| e13 | `20261031-162158-claude-opus-5-5` | The refinement session e14 built on |
| e14 | `20261031-202942-claude-opus-5-5` | The change as first written |
| e15 | `20261101-053638-claude-opus-5-5` | The fourth review before code, which the newest gate answers |
| e15 | `20261101-055318-claude-opus-5-5` | The last review before code, which e20 takes |
| e16 | `20261101-055045-claude-opus-5-5` | The fourth and final revision |
| e17 | `20261101-074317-claude-opus-5-5` | The code and the self-review |
| e18 | `20261101-183519` | The sensors the last reviews read |
| e19 | `20261101-185243-claude-opus-5-5`, `20261101-190534-gpt-6.1-sol` | The last code reviews, Opus and Codex |
| e20 | `20261101-190659-claude-opus-5-5` | The last packet |
| e21 | `20261101-213833-claude-opus-5-5` | Step 8's base, which e22 starts from |

The change went through four rounds of review and revision before code, and two rounds of triage and fixes after it. The gate files hold every round's answers, and name the reviews they answer. Step 8's base came from two more e21 rounds, with `W3_GATE=e22-test-the-reviewer/base-gate.md` and then `base-gate-round2.md`. Only the last round's runs are included, so `W3_GATE` with an earlier gate stops with "the gate names … which has no review.md".

## e22 and e23

```bash
cd e22-test-the-reviewer && ./run.sh            # every case; or ./run.sh F6
cd e23-merge-without-a-person && ./run.sh       # the clean case
```

**e22** applies each case's patch to step 8's base, runs e18, three Opus reviews and one Codex review, and scores each review against `cases/README.md`, which says what each flaw breaks and who should catch it. A case whose folder already holds runs is skipped, so an interrupted set resumes. `results.md` is the class result: every review caught F2 to F6 with a BLOCK, none blocked the clean case, and F1, a test that can no longer fail, was only seen, as an AUTO-FIX.

**e23** writes, codes, senses and reviews PC-303 (`PC-303.md`) from its settled decisions (`seed/`). `run.sh resume <gate> <round>` continues after a person's gate, and `run.sh rebase <round>` re-runs the reviews over a base commit that holds the baseline spec. `results-clean-round1.md` to `results-clean.md` are the six class rounds: five refusals, then a yes. One yes shows the rung; it doesn't test it.

Neither folder includes the class runs, only their results.

## Start over, or stop

- `./demo.sh reset` gives a fresh clone at `week-3-start`.
- `./demo.sh stop` stops any container left behind. The clone, Maven's cache and the runs are kept.

## How it is put together

The agent is plain Claude Code 2.1.281 in the `he-week3` image, with the OpenSpec CLI 1.15.0 and Codex CLI 0.163.0. Claude Code is configured only through its managed settings, which the repository can't override; PetClinic's own agent files are ignored. `demo.sh` builds the managed settings for each step from Week 1's floor and the step's layers:

| Layer | What it adds |
|---|---|
| `w3-base` | Week 2's rules and permissions without the browser, where specifications live, and the glossary's terms |
| `w3-skills` | Week 3's skills, copied from [`../../skills`](../../skills): `refine-requirement`, `review-change`, `review-code`, `triage-findings` |
| `w3-reviewer` | Denies every edit tool, so a reviewer can read and run tests but change nothing. The read-only mount backs it up |
| `w3-openspec`, `w3-apply` | OpenSpec 1.15.0's own `openspec-propose` and `openspec-apply-change` skills, unchanged |
| `w3-author` | The coding agent's rules: the change's planning files are inputs, the protected checks are never edited, no new dependency |
| `w3-conventions` | A Stop hook: `./mvnw validate` before the coding agent finishes |
| `w2-sensors` | Week 2's architecture check after each production edit, from [`../week-2/layers`](../week-2/layers) |
| `w3-codex` | The Codex reviewer's configuration (`CODEX_HOME`), with the same rules and skills |
| `w3-egm` | Google's Elephant-Goldfish Model as e15's reviewer: `./demo.sh apply e14; LADDER_REVIEWER=egm ./demo.sh e15` |

Authority comes from the mounts in `compose.yaml`: reviewers get the clone read-only except `target/`, and the coding agent gets the protected checks read-only, except the ones a person approved a change to (`approvals.md`). The sensors and the policy are in [`sensors/`](sensors/README.md), and the baseline the reviewers are held to is in [`baseline/`](baseline/).

**Changed from the class copy:** the paths; the gate `e16` and `e21` take by default is the one with the highest round, since a clone gives every file the same time; and `E22_CODEX_RUNS=0` and `E23_CODEX_RUNS=0` run no Codex review on macOS too, where `seq 1 0` counts down.
