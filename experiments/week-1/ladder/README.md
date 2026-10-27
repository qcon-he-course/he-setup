# The ladder: experiments 0 and 2 to 6 in a plain Claude Code container

Each run starts Claude Code 2.1.281 in a container on a fresh clone of seeded PetClinic at `b107a86`. What changes from rung to rung is what sits in `/etc/claude-code`, Claude Code's managed configuration, which the repository can't override:

| Rung | Command | Loads, on top of the rung below |
|---|---|---|
| 0 | `./run.sh e0` | The floor only: the repository's hooks, permission rules, skills and agents are ignored (PetClinic ships one hook); auto memory is off; bypass and auto modes are off |
| 2 | `./run.sh e2` | The instruction file, as the managed `CLAUDE.md` (`../e2-tell-it-how-to-behave/layer/rules.md`) |
| 3 | `./run.sh e3` | Serena (Java language server) as an MCP server, a routing rule, and permission to use its lookups without asking |
| 4 | `./run.sh e4` | code-graph-rag as an MCP server with Memgraph, a routing rule; its natural-language and write tools are denied |
| 5 | `./run.sh init`, then `./run.sh e5` | The evidence rule, and the audited `AGENTS.md`, committed in the clone |
| 6 | `./run.sh e6` | The `trace-journey` and `arch-map` skills, archify, CodeBoarding's output in `.harness/codeboarding/`, and permission to write under `.harness/` |

Experiment 1's open run has its own runner: `../e1-limit-what-it-can-do/`.

Each layer is a folder, `<experiment>/layer/`, holding any of `rules.md`, `mcp.json`, `settings.json` and `skills/`. At start-up the container's entrypoint, as root, builds `/etc/claude-code` from the floor (`image/floor/managed-settings.json`) and the layers, then starts Claude Code as the `node` user, so the agent can't change its own configuration. Edit a layer's files and the next run picks them up, with no rebuild.

## Before the first run

Set up as `../README.md` says: the token, the image and Memgraph. Then, for each rung, check what it loaded before you trust its answers:

| Rung | What to confirm |
|---|---|
| e0 | `/mcp` shows no servers; `/context` shows no memory files |
| e2 | `/context` lists `/etc/claude-code/CLAUDE.md` with the four lines |
| e3 | `prepare.log` in the run folder says "Serena index ready"; `/mcp` shows `serena` connected; `show-run.sh` lists Serena calls under "MCP calls" |
| e4 | "graph ready" in `prepare.log`; `/mcp` shows `code-graph-rag` connected |
| e5 | `/context` lists `AGENTS.md`; the answers carry VERIFIED, INFERRED or UNKNOWN labels |
| e6 | `/trace-journey an owner adds a new pet` writes `files/.harness/diagrams/journey-*.html` in the run folder |

If e3 or e4 fails, look at `prepare.log` and the first lines of the session. The other rungs don't depend on them.

## Unattended runs

```bash
LADDER_BATCH=1 ./run.sh e3          # one unattended run
./batch.sh claude-haiku-4-5 5       # five rounds of e0 e2 e3 e4 e5 e6
./batch.sh claude-opus-5-5 2 e4 e5  # two rounds of the rungs named
./batch.sh claude-opus-5-5 5 e1     # experiment 1's open run, through its open-run.sh
./scoreboard.sh                     # medians per rung and model
./scoreboard.sh --rigged e0 e1      # each rigged item, contained beside open
```

- **How a run works.** `batch.sh` runs `run.sh` with `LADDER_BATCH=1`, one run at a time, so the shared Memgraph and Serena caches never see two runs at once. Each run uses `claude -p`: the six questions for e0 to e5, and `/trace-journey an owner adds a new pet` for e6. The answer goes to `answer.txt` in the run folder.
- **Permissions.** Unattended runs use Claude Code's `dontAsk` mode (except `init`, whose `/init` has to write `CLAUDE.md`): a call that would ask for permission is refused, and read-only shell commands still run. There is no trust prompt.
- **Time cap.** An unattended run is stopped after `LADDER_TIME_CAP` seconds (1200 by default) and its folder gets `timed-out.txt`.
- **What counts.** `scoreboard.sh` counts only unattended runs, the folders with a `prompt.txt`, so interactive runs stay out of the medians.
- **Usage.** Every run counts against your Claude plan. Our runs sent 0.2M to 1.4M tokens each, mostly from cache. Run Haiku first; if a batch hits a usage limit part way, the finished runs are kept.

`grade.sh <run folder>` marks an unattended run against the keys and writes `marks.json` and `score.txt` in the run folder. `../README.md` says what it needs. `./scoreboard.sh` then adds the quality columns, and `./scoreboard.sh --runs` lists every run. `results.sh` writes `../results/summary.md` and `summary.json` from all the marked runs.

## Files

| File | What it does |
|---|---|
| `run.sh` | One run of a rung; interactive, or unattended with `LADDER_BATCH=1` |
| `batch.sh` | N unattended rounds of the ladder on one model; `e1` runs experiment 1's open run |
| `show-run.sh` | A run's summary: time, tokens, tool calls, files read, MCP calls and the rigged items. `--answers`, `--replies`, `--calls` |
| `scoreboard.sh` | Medians per rung and model from the unattended runs, with their scores; `--nearest` picks the run nearest the median |
| `grade.sh` | Marks one unattended run against `../reference/grading-keys.json`, with a judge model |
| `results.sh` | The summary of every marked run, in `../results/` |
| `demo.sh` | The presenter's live demo of a rung, beside the stored runs. It compares against runs you have made with `batch.sh` |
| `codeboarding.sh` | CodeBoarding's analysis for experiment 6, once, with a provider API key. Its output is already in `../e6-build-your-mental-model/codeboarding/` |
| `stop.sh` | Stops Memgraph. `--all` also removes the caches and the graph |
| `settings.sh` | Where PetClinic comes from, the pinned commit, the model, where clones go, and which layers each rung loads |
| `compose.yaml` | The session container and Memgraph, on their own network |
| `image/` | The Dockerfile, the floor, and the start-up scripts: `ladder-assemble` builds `/etc/claude-code`, `ladder-prepare` indexes for Serena and the graph, `cgr` and `ladder-cgr-mcp` start code-graph-rag outside the repository |

Each run is saved in `<experiment>/runs/<date-time>-<model>/`, which git ignores:

- `config/` holds the transcript;
- `etc-claude-code/` holds exactly what the run loaded;
- `layers/` holds the layer files as they were for the run;
- `prepare.log` holds the indexing output;
- `files/` holds whatever the agent wrote, `.harness/` included;
- `git-status.txt` records the clone's state when Claude Code exited;
- unattended runs add `prompt.txt` and `answer.txt`.

The clone itself lives in `~/.cache/qcon-he/ladder/` and is removed after the run; `LADDER_KEEP_CLONE=1` keeps it.

## Known gaps

- **No firewall.** The container reaches the network directly, as experiment 1's open run does.
- **Serena's index cache.** Serena keeps its index between runs in the `cache` volume. That is tool start-up, outside the agent's tokens. Its memories are removed before every run.
- **CodeBoarding.** Its component names come from a model, once. Every e6 run sees the same output.
