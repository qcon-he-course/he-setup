#!/usr/bin/env bash
# The scoreboard from the stored runs: for each rung and model, the number of
# runs and the median of minutes, tokens sent, cache share, tool calls, files
# read and MCP calls, all as show-run.sh reports them. Quality comes from the
# score.txt in each run folder after marking it against the answer key: one
# line, "q1-5=4 q6=5". Runs without one show "-".
#
# Stored runs are the unattended ones, the folders with a prompt.txt; the
# dry-run and the live run are left out. The model is the one the run folder's
# name ends with.
#
#   ./scoreboard.sh                    every model and rung
#   ./scoreboard.sh claude-haiku-4-5   one model; e0 or another rung limits it too
#   ./scoreboard.sh --runs             one row per run instead of medians
#   ./scoreboard.sh --nearest claude-opus-5-5 e0
#                                      the folder of the run nearest the median:
#                                      right answers first, then tokens sent
#   ./scoreboard.sh --rigged e0 e1     for each rigged item, in how many runs
#                                      show-run.sh says yes: contained beside open
#   ./scoreboard.sh --json             every stored run's measures, for results.sh
#
# e1 is experiment 1's open run, saved by its open-run.sh.
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=settings.sh
. "$here/settings.sh"
exec python3 - "$EXPERIMENTS" "$@" <<'PY'
import glob, os, re, statistics, subprocess, sys

experiments = sys.argv[1]
args = sys.argv[2:]
per_run = "--runs" in args
nearest = "--nearest" in args
rigged = "--rigged" in args
RUNGS = [("e0", "e0-the-naked-agent"), ("e1", "e1-limit-what-it-can-do"), ("e2", "e2-tell-it-how-to-behave"), ("e3", "e3-give-it-navigation"),
         ("e4", "e4-give-it-code-knowledge"), ("e5", "e5-require-evidence"), ("e6", "e6-build-your-mental-model")]
only_rungs = [a for a in args if a in dict(RUNGS)]
only = [a for a in args if not a.startswith("--") and a not in only_rungs]
show = os.path.join(experiments, "e1-limit-what-it-can-do", "show-run.sh")

def num(s):
    s = s.strip()
    return float(s[:-1]) * 1000 if s.endswith("k") else float(s)

def measure(run):
    out = subprocess.run([show, run], capture_output=True, text=True).stdout
    m = {}
    if g := re.search(r"^Agent .*?model ([^,\s]+)", out, re.M): m["model"] = g.group(1)
    if g := re.search(r"^Time\s+(\d+)m (\d+)s", out, re.M): m["min"] = int(g.group(1)) + int(g.group(2)) / 60
    if g := re.search(r"^Sent\s+([\d.]+k?) tokens .*?(\d+)% served", out, re.M):
        m["sent"], m["cache"] = num(g.group(1)), int(g.group(2))
    if g := re.search(r"^Tool calls \((\d+)\)", out, re.M): m["calls"] = int(g.group(1))
    if g := re.search(r"^Files read \((\d+)\)", out, re.M): m["files"] = int(g.group(1))
    # "MCP calls: 6 serena (4 find_symbol, 2 get_symbols_overview)": servers outside the brackets, tools inside.
    mcp_line = (re.search(r"^MCP calls: (.*)$", out, re.M) or [None, ""])[1]
    m["mcp"] = sum(int(x) for x in re.findall(r"(\d+) [\w-]+", re.sub(r"\([^)]*\)", "", mcp_line)))
    m["mcp_tools"] = {}
    for inside in re.findall(r"\(([^)]*)\)", mcp_line):
        for n, tool in re.findall(r"(\d+) ([\w-]+)", inside):
            m["mcp_tools"][tool] = m["mcp_tools"].get(tool, 0) + int(n)
    # The rigged-items block: "      <label, 56 wide> <value>".
    block = out.split("\nRigged items\n", 1)[1].split("\n\n", 1)[0] if "\nRigged items\n" in out else ""
    m["rigged"] = {line[6:62].strip(): line[63:].strip() for line in block.splitlines() if line.strip()}
    score = os.path.join(run, "score.txt")
    if os.path.exists(score):
        text = open(score).read()
        if g := re.search(r"q1-5\s*=\s*(\d+)", text): m["q15"] = int(g.group(1))
        if g := re.search(r"q6\s*=\s*(\d+)", text): m["q6"] = int(g.group(1))
    return m

rows = []
for rung, folder in RUNGS:
    if only_rungs and rung not in only_rungs:
        continue
    for run in sorted(glob.glob(os.path.join(experiments, folder, "runs", "*", ""))):
        name = os.path.basename(run.rstrip("/"))
        # git-status.txt is written when Claude Code exits, so a run still going is left out.
        if (name.endswith("-init") or not os.path.exists(os.path.join(run, "prompt.txt"))
                or not os.path.exists(os.path.join(run, "git-status.txt"))
                or not glob.glob(os.path.join(run, "config", "projects", "**", "*.jsonl"), recursive=True)):
            continue
        # <date>-<time>-<model>: the transcript can name several models when a subagent used another.
        model = name.split("-", 2)[2] if name.count("-") >= 2 else "?"
        if only and model not in only:
            continue
        m = measure(run)
        m["model"] = model
        rows.append((rung, name, m, run))

if "--json" in args:
    import json
    print(json.dumps([dict(m, rung=rung, run=name, path=path.rstrip("/")) for rung, name, m, path in rows], indent=1))
    sys.exit(0)

if nearest:
    if len(only) != 1 or len(only_rungs) != 1:
        sys.exit("usage: ./scoreboard.sh --nearest <model> <rung>")
    if not rows:
        sys.exit(f"scoreboard: no stored {only[0]} runs for {only_rungs[0]}")
    pool = rows
    scored = [r for r in rows if r[2].get("q15") is not None]
    if scored:
        median_right = statistics.median(r[2]["q15"] for r in scored)
        gap = min(abs(r[2]["q15"] - median_right) for r in scored)
        pool = [r for r in scored if abs(r[2]["q15"] - median_right) == gap]
    sent = [r[2]["sent"] for r in rows if r[2].get("sent") is not None]
    median_sent = statistics.median(sent) if sent else 0
    print(min(pool, key=lambda r: abs(r[2].get("sent", 0) - median_sent))[3].rstrip("/"))
    sys.exit(0)

if rigged:
    groups = {}
    for rung, name, m, _ in rows:
        groups.setdefault((m["model"], rung), []).append(m)
    keys = sorted(groups, key=lambda k: (k[0], [r for r, _ in RUNGS].index(k[1])))
    labels = []
    for k in keys:
        for m in groups[k]:
            labels += [l for l in m["rigged"] if l not in labels]
    print("Rigged items: in how many runs show-run.sh says yes. \"-\" where it can't tell, as for the hook without a tripwire.\n")
    print("| Rigged item | " + " | ".join(f"{model} {rung} (n={len(groups[(model, rung)])})" for model, rung in keys) + " |")
    print("|---" * (len(keys) + 1) + "|")
    for label in labels:
        cells = []
        for k in keys:
            values = [m["rigged"].get(label) for m in groups[k] if m["rigged"].get(label) in ("yes", "no")]
            cells.append(f"{values.count('yes')} of {len(values)}" if values else "-")
        print(f"| {label} | " + " | ".join(cells) + " |")
    sys.exit(0)

def fmt(v, kind):
    if v is None: return "-"
    if kind == "min": return f"{v:.1f}"
    if kind == "sent": return f"{v/1000:.0f}k"
    if kind == "cache": return f"{v:.0f}%"
    return f"{v:g}"

cols = [("q15", "Q1-5 /5"), ("q6", "Q6 /6"), ("min", "Minutes"), ("sent", "Tokens sent"), ("cache", "Cached"),
        ("calls", "Tool calls"), ("files", "Files read"), ("mcp", "MCP calls")]
if per_run:
    print("| Rung | Run | Model | " + " | ".join(c[1] for c in cols) + " |")
    print("|---" * (len(cols) + 3) + "|")
    for rung, name, m, _ in rows:
        print(f"| {rung} | {name} | {m.get('model','?')} | " + " | ".join(fmt(m.get(k), k) for k, _ in cols) + " |")
    sys.exit(0)

groups = {}
for rung, name, m, _ in rows:
    groups.setdefault((m.get("model", "?"), rung), []).append(m)
print("Medians per rung and model. n is the number of runs; quality columns count only runs with a score.txt.\n")
print("| Model | Rung | n | " + " | ".join(c[1] for c in cols) + " |")
print("|---" * (len(cols) + 3) + "|")
for (model, rung) in sorted(groups, key=lambda k: (k[0], [r for r, _ in RUNGS].index(k[1]))):
    ms = groups[(model, rung)]
    cells = []
    for k, _ in cols:
        vals = [m[k] for m in ms if m.get(k) is not None]
        cells.append(fmt(statistics.median(vals), k) if vals else "-")
    print(f"| {model} | {rung} | {len(ms)} | " + " | ".join(cells) + " |")
PY
