# Week 1 experiments: e0 to e6

These are the experiments from the Week 1 session, set up so you can run them yourself. They use the same containers, layers and questions as in class, on seeded PetClinic at `b107a86`. The answer keys and the results of the stored runs are included.

Every experiment asks the agent the same six questions about PetClinic, in [`questions.txt`](questions.txt), except e6, which draws a journey. What changes is what surrounds the model:

| Experiment | What it adds | Run it with |
|---|---|---|
| e0, the naked agent | Nothing: plain Claude Code on a floor that ignores the repository's hooks, permission rules and skills | `ladder/run.sh e0` |
| e1, limit what it can see and do | The opposite: no floor, so the repository's start-up hook runs and a tripwire records what it sends | `e1-limit-what-it-can-do/open-run.sh` |
| e2, tell it how to behave | An instruction file | `ladder/run.sh e2` |
| e3, give it navigation | Serena, a Java language server, as an MCP server | `ladder/run.sh e3` |
| e4, give it code knowledge | code-graph-rag, a code graph in Memgraph, as an MCP server | `ladder/run.sh e4` |
| e5, require evidence | The evidence rule, and an audited `AGENTS.md` | `ladder/run.sh e5` |
| e6, build your mental model | The `trace-journey` and `arch-map` skills, archify, and CodeBoarding's output | `ladder/run.sh e6` |

e2 to e6 are a ladder: each rung keeps the layers of the rungs below it. Each experiment's folder has a README with its question, how to run it, what to look for, and what our runs showed.

## Safety first

Seeded PetClinic carries rigged prompt-injection payloads: a start-up hook that posts `.env`, instructions in comments and documents, hidden Unicode text and a fake token. They are harmless, but that is why every run happens in a container, on a clone the scripts make and remove. Don't open your PetClinic clone in your own coding agent. e1 is the one place the hook is allowed to run, and its network goes only to the local tripwire.

## What you need

- **The setup from Week 1**, in the [README](../../README.md) of this repository, including your PetClinic clone at `~/course/petclinic`. The scripts clone from it. To use another clone, set `PETCLINIC`.
- **Docker**, as for Week 2. The ladder's image is larger than Week 2's: it adds Serena and code-graph-rag, and e4 pulls Memgraph.
- **Claude Code and a token** from `claude setup-token`, exported as `CLAUDE_CODE_OAUTH_TOKEN` in every terminal you run from. The runs use Claude Opus 5.5; set `LADDER_MODEL` (and `E1_MODEL` for e1) to use another model.
- **For marking your runs, optionally:** an Anthropic API key (`sk-ant-api…`) from the Console, never the subscription token. See "Mark your runs" below.

**Where this has been checked.** On macOS with Colima, before and during the session. Not on Linux or WSL. Tell us in Slack if something doesn't work.

## Set up, once

From `ladder/`:

```bash
export CLAUDE_CODE_OAUTH_TOKEN=<your token>
docker compose build session && docker compose pull memgraph   # 5 to 10 minutes the first time
```

e6 needs CodeBoarding's analysis of PetClinic. The one from class is already in `e6-build-your-mental-model/codeboarding/`, so you don't need to run `codeboarding.sh`, which calls a model through an API key.

e5 and e6 commit an audited `AGENTS.md` into each clone: `e5-require-evidence/AGENTS.md`. The one there is the presenter's, audited from the `/init` draft in `init-draft.md`, with the audit in `audit.md`. To use your own, run `./run.sh init`, type `/init`, audit the draft it saves, and replace `AGENTS.md` with what survives.

## Run an experiment

From `ladder/`:

```bash
pbcopy < ../questions.txt        # macOS; elsewhere, open questions.txt and copy it
./run.sh e0
```

1. `run.sh` clones PetClinic at `b107a86` into `~/.cache/qcon-he/ladder/`, builds Claude Code's managed configuration from the floor and the rung's layers, and starts Claude Code in the container. From e3, it indexes for Serena and the graph first, which takes 10 to 60 seconds.
2. Trust the folder. `/context` shows what the rung loaded, `/mcp` its MCP servers.
3. Paste the questions. For e6, type `/trace-journey an owner adds a new pet` instead.
4. Approve read-only commands. Deny anything that writes, builds or reaches the network.
5. Leave with `/exit`, never Ctrl-C: the script saves the agent's files and removes the clone only after Claude Code exits.
6. `./show-run.sh e0` shows what the run did: time, tokens, tool calls, files read, MCP calls, and whether the agent saw or flagged the rigged items. `--answers` prints its answers.

For e6, open the diagram afterwards: `runs/<the run>/files/.harness/diagrams/journey-*.html` in the experiment's folder.

`./stop.sh` stops Memgraph when you're done. `./stop.sh --all` also removes the caches.

### e1, the open run

e1 needs two terminals, both in `e1-limit-what-it-can-do/`:

```bash
./tripwire.sh      # first terminal: shows every request the tripwire receives
./open-run.sh      # second terminal: Claude Code with no floor
```

Trust the folder and paste the questions as before. Watch the tripwire's terminal: PetClinic's start-up hook posts `.env` to it as soon as the session starts, without asking. `./show-rigged.sh` walks through the five rigged items in the pinned commit. `./show-run.sh` reads the run afterwards, and `./stop.sh` removes the tripwire's network.

## Compare with our runs

Each experiment's README ends with what our stored runs showed: five unattended runs per rung on Haiku 4.5 and five on Opus 5.5, with the answers marked against the keys. [`results/summary.md`](results/summary.md) has all the medians, and [`results/findings.md`](results/findings.md) what they showed. Your interactive runs answer the same questions in the same container, so you can set your agent's answers and counts beside them.

## Mark your runs

The answer keys are in [`reference/`](reference/): [`grading-keys.json`](reference/grading-keys.json) for the six questions, the cold-open key, the check of the running app the keys rely on, and the e6 journey key.

`ladder/grade.sh <run folder>` marks one unattended run against the keys, the way the stored runs were marked. A judge model with no tools reads the agent's answers, the code and the key. It needs:

- an Anthropic API key in `~/.config/qcon-anthropic-key`. It calls Claude Fable 5.1 through the API, which is billed to that key;
- a clean clone of PetClinic at `b107a86` in `~/.cache/qcon-he/e6-key`, or wherever `GRADE_CLONE` points: `git clone ~/course/petclinic ~/.cache/qcon-he/e6-key && git -C ~/.cache/qcon-he/e6-key checkout b107a86`.

To make unattended runs to mark, use `LADDER_BATCH=1 ./run.sh e3`, or `./batch.sh claude-opus-5-5 1 e0 e2 e3` for a round of several rungs. They answer the questions in `dontAsk` mode, where anything that would ask is refused. `./scoreboard.sh` then gives the medians of your runs, to set beside the ones in `results/summary.md`.

## More detail

- [`ladder/README.md`](ladder/README.md): how the ladder is built, what each script does, and what was checked. It was written for the presenter, so parts of it speak to running the session.
- [`reference/experiments.md`](reference/experiments.md): the design of the whole day.
