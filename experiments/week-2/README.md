# Week 2 experiments: e7 to e11

These are the experiments from the Week 2 session, set up so you can run them yourself. They use the same container, layers and prompts as in class. The runs from class are included, so you can compare your agent's work with what you saw.

All the steps work on one PetClinic clone. Each step starts from the state the previous one left, in this order:

| Step | What the agent is asked | Layers | Roughly |
|---|---|---|---|
| e7 | Reproduce the bug in the browser, without changing files | base, browser | 1 minute |
| e7b | Trace the edit request through the code, and draw it with archify | base, skills, archify | 5 minutes |
| step 3 | You write the ArchUnit rule and freeze its 8 violations: [step-3-write-the-rule.md](step-3-write-the-rule.md) | none | 10 minutes |
| e8 | Prove the bug with a failing test | base, browser, skills | 1 minute |
| e9 | Pin the current behavior before a restructuring | base, browser, skills | 6 to 15 minutes |
| e10 | Move the add form's date check into `PetValidator`, for new pets only | base, browser, skills | 4 minutes |
| e11 | Fix the bug | base, browser, skills, sensors | 3 minutes |
| e11-shortcut | Fix the bug from a fresh clone, "as small as you can" | base, browser, skills, sensors | 3 minutes |

## What you need

- **The setup from Week 1**, in the [README](../../README.md) of this repository, with JDK 17 and git.
- **Docker.** Docker Desktop, OrbStack or Colima on macOS; Docker Engine with the compose plugin on Linux. The image and Maven's cache need a few gigabytes of disk.
- **Claude Code and a token.** The agent runs in the container with the token from `claude setup-token`, which needs a Pro, Max, Team or Enterprise plan. Your token goes from Claude Code straight to Anthropic. The runs use Claude Opus 5.5. To use another model, set `LADDER_MODEL`, for example `export LADDER_MODEL=claude-sonnet-5-5`; your results will differ more from the class runs.
- **Google Chrome**, for the steps with the browser. `./demo.sh chrome` starts a separate Chrome with its own profile. Your usual Chrome is not touched.
- **Ports 8080 and 9222 free.** To use others, set `W2_APP_PORT` and `W2_CHROME_PORT`.

If you use Codex, you can't run the steps as they are: the container runs Claude Code. You can still read the class runs with `./demo.sh show`, and use the skills in [`../skills`](../../skills) with your own agent.

**Where this has been checked.** On macOS with Colima, during and before the session. On Linux, `./demo.sh chrome` starts `chromium` (set `CHROME` to use another browser), and the container reaches it through `host.docker.internal`; this hasn't been checked. WSL hasn't been checked either. Tell us in Slack if something doesn't work.

## Set up, once

From this folder:

```bash
export CLAUDE_CODE_OAUTH_TOKEN=<your token>
./demo.sh build      # the image: a few minutes the first time
./demo.sh reset      # the agent's clone of PetClinic, at week-2-start
./demo.sh app        # PetClinic on localhost:8080, from its own clone
./demo.sh chrome     # Chrome with remote debugging on port 9222
./demo.sh check      # should end with "demo: ready"
```

`reset` puts the agent's clone in `~/.cache/qcon-he/week2/petclinic`. `app` runs PetClinic from a second clone, in `~/.cache/qcon-he/week2/app`, so the agent's edits never touch the running application. In a new terminal, export the token again before you run a step.

`./demo.sh help` lists every command.

## Run a step

```bash
./demo.sh e7
```

1. `demo.sh` prints the step's layers and the clone's state, and starts Claude Code in the container. On macOS the prompt is on the clipboard. Elsewhere, it prints where the prompt file is.
2. Trust the folder. The status line at the bottom shows the layers loaded.
3. Paste the prompt. Approve what the step needs: the notes below say what that is.
4. When the agent is done, leave with `/exit`.

Each run is saved in the step's folder under `runs/<date-time>-<model>/`: the prompt, the session, the managed configuration it ran with, and the diff before and after. Git ignores your runs.

## The steps

**e7, reproduce the bug.** The agent drives the Chrome that `./demo.sh chrome` started. Put it beside the terminal. Watch whether it goes to the browser or to the code first. Approve nothing that writes files. The run changes a pet's birth date in the running application, so run `./demo.sh app` before e8 to put it back.

**e7b, trace the slice.** No browser this time. Watch for `trace-request` to load by itself, and for the labels: VERIFIED by reading, VERIFIED by running, INFERRED. The diagram opens in your browser when the agent writes it. The prompt carries the evidence from the class run of e7; if your e7 saw different values, edit the prompt before you paste it. Approve `./mvnw`, `archify`, writes under `.harness/` and temporary edits the agent says it will undo.

**Step 3, write the rule.** You do this one by hand: [step-3-write-the-rule.md](step-3-write-the-rule.md). To skip it, run `./demo.sh reset week-2-sensors`, which gives a fresh clone with the rule and the store already committed.

**e8, prove the bug.** The prompt names no skill. Watch for `prove-bug` to load by itself, and read the first failure line: does it name the symptom in the bug report? The diff should touch test files only. Approve `./mvnw` and edits to test files.

**e9, pin what exists.** Watch for `pin-behavior` to load, and for what it does with e8's red test: it should leave it red. Read the pins table at the end. Did it pin the case-insensitive duplicate name, Week 1's question 4? The number of pins varies from run to run. Production code must be unchanged at the end: `git -C ~/.cache/qcon-he/week2/petclinic diff --stat -- src/main` prints nothing. This is the longest step.

**e10, refactor under pins.** The date check moves from `PetController` into `PetValidator`, behind `pet.isNew()`. Every pin should stay green, and the bug test red. Then look at the store: `git -C ~/.cache/qcon-he/week2/petclinic diff -- src/test/resources/archunit_store`. One line has gone, and the prompt didn't ask for that. Approve `./mvnw` and edits to production code; deny edits to the pins and the bug test.

**e11, fix it.** One more layer, `w2-sensors`, adds three hooks: one stops edits to the sensor's own files, one runs `ArchitectureTests` after each edit to production code (about 20 seconds), and one runs it again before the agent finishes. After e10, the fix is one condition. Read the agent's "Cause": is it right, and how does it know?

**e11-shortcut, the same fix without the preparation.** From a fresh clone with the bug and the rule only:

```bash
./demo.sh reset week-2-sensors
./demo.sh e11-shortcut
```

The hooks come with the layer, so the reset keeps them. The smallest fix copies the date check into the edit handler, which breaks the rule. Watch which happens: the agent takes that shortcut and the hook sends it back, or it reads the rule's commit first and goes straight to `PetValidator`. Both happened in our runs. At the end, the full suite is green and the store has 7 lines instead of 8. Deny edits to `ArchitectureTests`, the store and `archunit.properties`; the hook blocks them anyway.

## Compare with the class runs

```bash
./demo.sh show e9          # the steps the agent took and its final answer
./demo.sh apply e9         # put the clone in the state that run left
```

`show` and `apply` use the newest run of a step: yours if you have one, otherwise the class run. To pick a run, add its folder name. These are the runs from class:

| Step | Run |
|---|---|
| e7 | `20261026-124547-claude-opus-5-5` |
| e7b | `20261026-131013-claude-opus-5-5` (its diagram is in `diagrams/`) |
| e8 | `20261026-135650-claude-opus-5-5` |
| e9 | `20261026-142703-claude-opus-5-5` (29 pins) |
| e10 | `20261026-144710-claude-opus-5-5` |
| e11 | `20261026-151413-claude-opus-5-5` |
| e11-shortcut | `20261026-152941-claude-opus-5-5-shortcut`: it read the rule first |
| e11-shortcut | `20261022-1900-claude-opus-5-5-cloudtest-shortcut`: it took the shortcut, and the hook fired |

For example, `./demo.sh show e11-shortcut 20261022-1900-claude-opus-5-5-cloudtest-shortcut` shows "sensor messages seen: 1" and the agent's account of being sent back.

`apply` is also how you skip a step: `./demo.sh apply e9` puts the class run's pins in your clone, and you can go on to e10. It replaces the clone's own changes.

## Start over, or stop

- `./demo.sh reset` gives a fresh clone at `week-2-start`. `./demo.sh reset week-2-sensors` gives the state after step 3.
- `./demo.sh stop` stops PetClinic, any container left behind and the debugging Chrome. The clones, Maven's cache and the runs are kept.

## How it is put together

The agent is plain Claude Code 2.1.281 in the `he-week2` image, configured only through Claude Code's managed settings, which the repository can't override. PetClinic's own agent files are ignored. `demo.sh` builds the managed settings for each step from a floor and the step's layers:

| Layer | What it adds |
|---|---|
| `w2-base` | The rules in `rules.md` (build with `./mvnw`, edit with the edit tools, label claims VERIFIED or INFERRED), the permissions, and the status line |
| `w2-browser` | The Chrome DevTools MCP server, which drives the Chrome on your machine |
| `w2-skills` | `trace-request`, `prove-bug` and `pin-behavior`, copied from [`../skills`](../../skills) |
| `w2-archify` | archify's skill and command, for e7b's diagram |
| `w2-sensors` | The three hooks: `protect-sensors.sh` and `check-architecture.sh` |

The rule and its store are in the PetClinic repository, on the branch `week-2-sensors`, because people and CI run them too. The hooks are agent configuration, so they live in the layer.
