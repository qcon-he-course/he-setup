#!/usr/bin/env bash
# The stored runs' summary, for the slides: results/summary.md and
# results/summary.json at the top of the project. It reads every unattended
# run that scoreboard.sh counts, and the marks grade.sh wrote in each:
#
#   - per experiment and model: n, and the medians of quality and cost;
#   - the outcomes per question;
#   - the change from the rung below (e1 against e0: open against contained);
#   - each rigged item: in how many runs it happened;
#   - the marks flagged for review, with links to the run folders.
#
# Every quality figure is labelled model-marked until Prem confirms it.
# The run folders are git-ignored; these two files are not.
#
#   ./results.sh
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=settings.sh
. "$here/settings.sh"
out="$EXPERIMENTS/results"
mkdir -p "$out"
"$here/scoreboard.sh" --json > "$out/.runs.json"
python3 -I - "$out" <<'PY'
import json, os, statistics, sys
from datetime import datetime, timezone

out = sys.argv[1]
runs_path = os.path.join(out, ".runs.json")
with open(runs_path, encoding="utf-8") as fh:
    runs = json.load(fh)
os.remove(runs_path)

ORDER = ["e0", "e1", "e2", "e3", "e4", "e5", "e6"]
BELOW = {"e1": "e0", "e2": "e0", "e3": "e2", "e4": "e3", "e5": "e4", "e6": "e5"}
OUTCOMES = ["right_checked", "right_unchecked", "wrong_rigged", "wrong_other"]
SHORT = {"right_checked": "right", "right_unchecked": "right unchecked", "wrong_rigged": "rigged", "wrong_other": "wrong"}
# (key, heading, kind): quality first, then cost.
METRICS = [("q15", "Q1-5 right", "n"), ("q6", "Q6 steps", "n"), ("checked", "Right and checked", "n"),
           ("rigged_taken", "Took a rigged claim", "n"), ("cites", "Questions citing a line", "n"),
           ("flagged", "Questions flagging the README", "n"),
           ("labelled", "INFERRED or UNKNOWN", "n"), ("unsupported", "Unsupported claims", "n"),
           ("contradicted", "Contradicted", "n"), ("min", "Minutes", "min"), ("sent", "Tokens sent", "k"),
           ("cache", "Cached", "%"), ("calls", "Tool calls", "n"), ("files", "Files read", "n"), ("mcp", "MCP calls", "n")]

def rel(path):
    return os.path.relpath(path, out)

judges, rubrics, flags, unmarked = set(), set(), [], []
for r in runs:
    marks_path = os.path.join(r["path"], "marks.json")
    r["marked"] = False
    if not os.path.exists(marks_path):
        unmarked.append({"rung": r["rung"], "model": r["model"], "run": r["run"], "why": "not graded"})
        continue
    with open(marks_path, encoding="utf-8") as fh:
        m = json.load(fh)
    if m.get("status") != "marked":
        unmarked.append({"rung": r["rung"], "model": r["model"], "run": r["run"], "why": "; ".join(m.get("flags", []))})
        continue
    r["marked"] = True
    judges.add((m.get("judge") or {}).get("model") or "?")
    rubrics.add(m.get("rubric_sha256", "?"))
    s, qs = m["summary"], m["questions"]
    r.update(q15=s["right"], q6=s["q6_steps_found"], checked=s["right_checked"], rigged_taken=s["wrong_rigged"],
             unsupported=s["unsupported_claims"], contradicted=s["contradicted"], flagged=s.get("flags_readme"),
             cites=sum(bool(q.get("cites_file_line")) for q in qs.values()),
             labelled=sum(q.get("label") in ("INFERRED", "UNKNOWN", "mixed") for q in qs.values()),
             outcomes={qid: q["outcome"] for qid, q in qs.items()})
    for f in m.get("flags", []):
        flags.append({"rung": r["rung"], "model": r["model"], "run": r["run"], "marks": rel(marks_path), "flag": f})

groups = {}
for r in runs:
    groups.setdefault((r["rung"], r["model"]), []).append(r)
keys = sorted(groups, key=lambda k: (ORDER.index(k[0]) if k[0] in ORDER else 99, k[1]))

def median(values):
    values = [v for v in values if v is not None]
    return statistics.median(values) if values else None

summary_groups = []
for rung, model in keys:
    rs = groups[(rung, model)]
    # A run without marks has no quality figures, so those medians come from the marked runs only.
    medians = {k: median([r.get(k) for r in rs]) for k, _, _ in METRICS}
    outcomes = {qid: {o: sum(r["marked"] and r["outcomes"].get(qid) == o for r in rs) for o in OUTCOMES}
                for qid in ["q1", "q2", "q3", "q4", "q5"]}
    tools = {}
    for r in rs:
        for t, n in (r.get("mcp_tools") or {}).items():
            tools[t] = tools.get(t, 0) + n
    summary_groups.append({"rung": rung, "model": model, "n": len(rs), "marked": sum(r["marked"] for r in rs),
                           "medians": medians, "outcomes": outcomes, "runs": [r["run"] for r in rs],
                           "mcp_runs": sum((r.get("mcp") or 0) > 0 for r in rs), "mcp_tools": tools})
by_key = {(g["rung"], g["model"]): g for g in summary_groups}

deltas = []
for g in summary_groups:
    below = by_key.get((BELOW.get(g["rung"]), g["model"]))
    if below:
        change = {k: (None if g["medians"][k] is None or below["medians"][k] is None else g["medians"][k] - below["medians"][k])
                  for k, _, _ in METRICS}
        deltas.append({"rung": g["rung"], "below": below["rung"], "model": g["model"], "change": change})

labels = []
for r in runs:
    labels += [l for l in r.get("rigged", {}) if l not in labels]
rigged = {l: {f"{model} {rung}": [sum(r["rigged"].get(l) == "yes" for r in groups[(rung, model)]),
                                  sum(r["rigged"].get(l) in ("yes", "no") for r in groups[(rung, model)])]
              for rung, model in keys} for l in labels}

generated = datetime.now(timezone.utc).isoformat(timespec="seconds")
data = {"generated": generated, "label": "model-marked until Prem confirms", "judges": sorted(judges),
        "rubrics": sorted(rubrics), "groups": summary_groups, "deltas": deltas, "rigged": rigged,
        "flags": flags, "not_marked": unmarked}
with open(os.path.join(out, "summary.json"), "w", encoding="utf-8") as fh:
    json.dump(data, fh, indent=1)
    fh.write("\n")

def fmt(v, kind, signed=False):
    if v is None:
        return "-"
    sign = "+" if signed and v > 0 else ""
    if kind == "min":
        return f"{sign}{v:.1f}"
    if kind == "k":
        return f"{sign}{v / 1000:.0f}k"
    if kind == "%":
        return f"{sign}{v:.0f}%"
    return f"{sign}{v:g}"

lines = ["# Stored runs: summary", "",
         f"Generated {generated} by `experiments/ladder/results.sh` from the run folders. "
         f"Every quality figure is **model-marked** (judge: {', '.join(sorted(judges)) or 'none'}) until Prem confirms it. "
         "The runs are unattended (`claude -p`), in `dontAsk` mode. Medians; n is the number of runs.", ""]
if len(rubrics) > 1:
    lines += [f"**Warning:** the marks come from {len(rubrics)} different rubrics. Re-grade the older runs before using these figures.", ""]
lines += ["## Medians per experiment and model", "",
          "| Rung | Model | n | Marked | " + " | ".join(h for _, h, _ in METRICS) + " |",
          "|---" * (len(METRICS) + 4) + "|"]
for g in summary_groups:
    lines.append(f"| {g['rung']} | {g['model']} | {g['n']} | {g['marked']} | "
                 + " | ".join(fmt(g["medians"][k], kind) for k, _, kind in METRICS) + " |")
lines += ["", "## Outcomes per question", "", "Out of the marked runs in each row.", "",
          "| Rung | Model | Q1 | Q2 | Q3 | Q4 | Q5 |", "|---|---|---|---|---|---|---|"]
for g in summary_groups:
    cells = [", ".join(f"{n} {SHORT[o]}" for o, n in g["outcomes"][qid].items() if n) or "-" for qid in ["q1", "q2", "q3", "q4", "q5"]]
    lines.append(f"| {g['rung']} | {g['model']} | " + " | ".join(cells) + " |")
if any(g["rung"] not in ("e0", "e1", "e2") for g in summary_groups):
    lines += ["", "## MCP use", "", "Whether the agent used the tools it was given at all, and which.", "",
              "| Rung | Model | Runs using an MCP tool | Calls per tool, all runs |", "|---|---|---|---|"]
    for g in summary_groups:
        if g["rung"] in ("e0", "e1", "e2"):
            continue
        tools = ", ".join(f"{n} {t}" for t, n in sorted(g["mcp_tools"].items(), key=lambda x: -x[1])) or "none"
        lines.append(f"| {g['rung']} | {g['model']} | {g['mcp_runs']} of {g['n']} | {tools} |")
if deltas:
    lines += ["", "## Change from the rung below", "", "e1 is set against e0: the open run against the contained one.", "",
              "| Rung | Against | Model | " + " | ".join(h for _, h, _ in METRICS) + " |", "|---" * (len(METRICS) + 3) + "|"]
    for d in deltas:
        lines.append(f"| {d['rung']} | {d['below']} | {d['model']} | " + " | ".join(fmt(d["change"][k], kind, signed=True) for k, _, kind in METRICS) + " |")
lines += ["", "## Rigged items", "", "In how many runs `show-run.sh` says yes. \"-\" where it can't tell, as for the hook without a tripwire.", "",
          "| Rigged item | " + " | ".join(f"{model} {rung}" for rung, model in keys) + " |", "|---" * (len(keys) + 1) + "|"]
for l, cells in rigged.items():
    lines.append(f"| {l} | " + " | ".join(f"{y} of {n}" if n else "-" for y, n in cells.values()) + " |")
lines += ["", "## Marks to review", ""]
lines += [f"- {f['rung']} [{f['run']}]({f['marks']}): {f['flag']}" for f in flags] or ["None."]
if unmarked:
    lines += ["", "## Not marked", ""] + [f"- {u['rung']} {u['run']}: {u['why']}" for u in unmarked]
with open(os.path.join(out, "summary.md"), "w", encoding="utf-8") as fh:
    fh.write("\n".join(lines) + "\n")
print(f"results: wrote {rel(os.path.join(out, 'summary.md'))} and summary.json in {out}: "
      f"{len(runs)} runs, {sum(r['marked'] for r in runs)} marked, {len(flags)} flags")
PY
