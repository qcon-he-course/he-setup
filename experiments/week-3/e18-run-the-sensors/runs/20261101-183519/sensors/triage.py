#!/usr/bin/env python3
"""triage: the policy half of step 7. Models discover risk; this decides what it permits.

  triage.py prepare <inputs>                 list every finding the clerk must account for
  triage.py check <inputs> <clerk reply>     audit the clerk's merge, apply the policy, write the packet

<inputs> holds the reviews (review-*.md), the step 5 results (sensors.md) and,
after prepare, sources.md. A finding in a review is a bold line that starts with
its id (R1, C2, ...) and names its disposition. A sensor finding is a line of the
test-delta audit, numbered S1, S2, ... in order.

The clerk (an agent with the triage-findings skill) merges findings that say the
same thing and ends its reply with one JSON block:

  {"findings": [{"id": "T1", "title": "...", "sources": ["review-step6-x:C2", "sensors:S4"],
                 "disposition": "BLOCK", "consequence": "question|fix|task|logged|overruled",
                 "question": "...", "fix": "...", "reason": "...", "evidence": "..."}],
   "unverified": ["..."], "known_defects": ["..."]}

check refuses a merge that drops a source or names one that does not exist, and
never lets a merged finding sit below the strictest disposition of its sources.
It computes eligibility (no open BLOCK and no failing test, in the suite or in the
harness's MySQL and Postgres run on the host; the known-defect lane is shown and
not counted), the sign-off the risk floor needs, the
doubt-theater count, and writes <inputs>/../packet.md. Exit 0: written; 1: the
merge failed the audit (the packet says why); 2: usage.
"""

import json
import os
import re
import sys

ORDER = ["INFORMATIONAL", "AUTO-FIX+REVERIFY", "DISCUSS", "BLOCK"]
FINDING = re.compile(r"^\*\*([RC]\d+)\b(.*)$")
DISPOSITION = re.compile(r"BLOCK|AUTO-FIX\+REVERIFY|AUTO-FIX|DISCUSS|INFORMATIONAL")
SIGN_OFF = {"critical": "a named owner of each critical surface", "material": "the component owner",
            "bounded": "repository policy", "mechanical": "none", "none": "none"}


def norm_disp(d):
    return "AUTO-FIX+REVERIFY" if d == "AUTO-FIX" else d


def review_findings(path):
    out = {}
    for line in open(path, encoding="utf-8"):
        m = FINDING.match(line.strip())
        if not m:
            continue
        fid, rest = m.group(1), m.group(2)
        d = DISPOSITION.search(rest)
        title = re.sub(r"^[\s.:—-]+", "", rest)
        title = re.sub(r"^(BLOCK|AUTO-FIX\+REVERIFY|AUTO-FIX|DISCUSS|INFORMATIONAL)(\s*\([^)]*\))?", "", title)
        title = title.replace("**", "").strip(" .:—-")
        out.setdefault(fid, {"disposition": norm_disp(d.group(0)) if d else None, "title": title[:160]})
    return out


def sensors(path):
    text = open(path, encoding="utf-8").read()
    floor = re.search(r"\| Risk floor \| \*\*(\w+)\*\*", text)
    block = re.search(r"## Test-delta audit\s+```\n(.*?)```", text, re.S)
    lines = [l for l in (block.group(1).splitlines() if block else []) if l and not l.startswith("summary:")]
    suite = re.search(r"\| Full test suite[^|]*\| ([^|]+) \|", text)
    not_run = re.search(r"Not run \(no Docker\): (.*?)\. Not run is not passed", text)
    failed = re.search(r"^Failed: (.*)$", text, re.M)
    # The harness's Docker run on the host (step5-docker.sh): one table per test order.
    host = {}  # class -> [(run, passed, failed)] per order
    orders = 0
    docker = re.search(r"^## Docker tests \(host\)\n(.*)", text, re.S | re.M)
    if docker:
        orders = len(re.findall(r"^\*\*\w+\*\* \(", docker.group(1), re.M))
        for c, r, p, f, _ in re.findall(r"^\| (\w+) \| (\d+) \| (\d+) \| (\d+) \| (\d+) \|$", docker.group(1), re.M):
            host.setdefault(c, []).append((int(r), int(p), int(f)))
    host_passed = {c for c, rs in host.items() if len(rs) == orders and all(r > 0 and p == r and f == 0 for r, p, f in rs)}
    host_failed = sorted(c for c, rs in host.items() if any(f > 0 for _, _, f in rs))
    items = [i for i in (not_run.group(1).split(", ") if not_run else []) if i.split(" ")[0] not in host_passed]
    # The known-defect lane (step5.sh): tests tied to an open ticket, shown and not counted.
    lane = []
    sec = re.search(r"^## Known-defect tests\n(.*?)(?=^## |\Z)", text, re.S | re.M)
    if sec:
        for t, k, n, f, p, m in re.findall(r"^\| `([^`]+)` \| (\S+) \| (\d+) \| (\d+) \| (\d+) \| (\d+) \|$", sec.group(1), re.M):
            lane.append({"test": t, "ticket": k, "runs": int(n), "failed": int(f), "passed": int(p), "missing": int(m)})
    b1 = re.search(r"^\| Build checks[^|]*\| ([^|]+) \|", text, re.M)
    return {"floor": floor.group(1) if floor else "none",
            "b1_failed": bool(b1 and "FAIL" in b1.group(1)),
            "lane": lane,
            "host": (f"{len(host_passed)} classes passed on the host in {orders} test orders" if host_passed else "")
                    + (("; " if host_passed else "") + "failed on the host: " + ", ".join(host_failed) if host_failed else ""),
            "host_failed": host_failed,
            "findings": {f"S{i}": {"disposition": None, "title": l} for i, l in enumerate(lines, 1)},
            "suite": suite.group(1).strip() if suite else "unknown",
            "not_run": ", ".join(items),
            "failed": failed.group(1) if failed else ""}


def load_sources(inputs):
    src = {}
    for f in sorted(os.listdir(inputs)):
        if f.startswith("review-") and f.endswith(".md"):
            for fid, v in review_findings(os.path.join(inputs, f)).items():
                src[f"{f[:-3]}:{fid}"] = v
    sens = sensors(os.path.join(inputs, "sensors.md"))
    for sid, v in sens["findings"].items():
        src[f"sensors:{sid}"] = v
    return src, sens


def prepare(inputs):
    src, sens = load_sources(inputs)
    L = ["# Every finding to account for", "",
         "Each id below must appear in the `sources` of exactly one merged finding. A disposition shown here is the reviewer's; a merged finding may not go below the strictest of its sources. Sensor findings have none: give each one, with a reason.", "",
         "| Source | Disposition | Title |", "|---|---|---|"]
    for k, v in src.items():
        L.append(f"| `{k}` | {v['disposition'] or '(sensor)'} | {v['title'].replace('|', '/')} |")
    L += ["", f"Risk floor: {sens['floor']}. Suite: {sens['suite']}." + (f" Not run: {sens['not_run']}." if sens["not_run"] else "")]
    open(os.path.join(inputs, "sources.md"), "w", encoding="utf-8").write("\n".join(L) + "\n")
    print(f"triage: {len(src)} findings to account for, listed in {os.path.join(inputs, 'sources.md')}")
    return 0


def clerk_json(path):
    text = open(path, encoding="utf-8").read()
    blocks = re.findall(r"```json\s*\n(.*?)```", text, re.S)
    if not blocks:
        raise ValueError("no ```json block in the clerk's reply")
    return json.loads(blocks[-1])


def requirements(clone):
    """ADDED and MODIFIED requirement names from the change's spec deltas: what the change does, from the spec."""
    out = []
    root = os.path.join(clone, "openspec", "changes")
    for dirpath, _, files in os.walk(root):
        if "archive" in dirpath:
            continue
        for f in files:
            if f == "spec.md":
                section = None
                for line in open(os.path.join(dirpath, f), encoding="utf-8"):
                    h = re.match(r"^## (ADDED|MODIFIED|REMOVED) Requirements", line)
                    if h:
                        section = h.group(1)
                    r = re.match(r"^### Requirement: (.*)", line)
                    if r and section:
                        out.append((os.path.basename(dirpath), section, r.group(1).strip()))
    return out


def check(inputs, reply, clone=None):
    src, sens = load_sources(inputs)
    problems, notes = [], []
    try:
        data = clerk_json(reply)
        merged = data.get("findings", [])
    except (ValueError, OSError) as e:
        data, merged = {}, []
        problems.append(f"The clerk's reply could not be read: {e}")
    seen = {}
    for t in merged:
        for s in t.get("sources", []):
            if s not in src:
                problems.append(f"{t.get('id')}: names `{s}`, which no review or sensor reported")
            seen.setdefault(s, []).append(t.get("id"))
        strictest = max((src[s]["disposition"] for s in t.get("sources", []) if s in src and src[s]["disposition"]),
                        key=ORDER.index, default=None)
        d = norm_disp(t.get("disposition") or "")
        if d not in ORDER:
            problems.append(f"{t.get('id')}: no valid disposition")
            d = strictest or "DISCUSS"
        if strictest and ORDER.index(d) < ORDER.index(strictest):
            notes.append(f"{t.get('id')}: the clerk gave {d}; raised to {strictest}, the strictest of its sources")
            d = strictest
        t["disposition"] = d
        if t.get("consequence") in ("logged", "overruled") and not t.get("reason") and (
                d != "INFORMATIONAL" or any(s.startswith("sensors:") for s in t.get("sources", []))):
            problems.append(f"{t.get('id')}: {d} {t.get('consequence')} without a recorded reason")
    for s in src:
        if s not in seen:
            problems.append(f"`{s}` ({src[s]['title'][:70]}) is in no merged finding")
        elif len(seen[s]) > 1:
            problems.append(f"`{s}` is in more than one merged finding: {', '.join(seen[s])}")

    floor = sens["floor"]
    blocks = [t for t in merged if t["disposition"] == "BLOCK" and t.get("status", "open") == "open"]
    # No merge on a red build (plan, 1 November): a failing test in the suite or on the host.
    red = [x for x in ([sens["failed"]] if sens["failed"] else []) + sens["host_failed"]]
    if "BUILD FAILED" in sens["suite"] and not red:
        red = ["the build"]
    if not re.match(r"\d+ run", sens["suite"]):
        red.append(f"the test suite has no result ({sens['suite']})")
    if sens["b1_failed"]:
        red.append("the build checks (`./mvnw validate`)")
    why = [f"{len(blocks)} open BLOCK"] if blocks else []
    why += ["failing: " + ", ".join(red)] if red else []
    questions = [t for t in merged if t.get("question") and t["disposition"] in ("BLOCK", "DISCUSS")]
    fixes = [t for t in merged if t.get("fix") and t["disposition"] in ("BLOCK", "AUTO-FIX+REVERIFY")]
    substantial = [t for t in merged if t["disposition"] != "INFORMATIONAL"]
    acted = [t for t in substantial if t.get("consequence") in ("question", "fix", "task")]
    overruled = [t for t in substantial if t.get("consequence") == "overruled"]

    L = ["# For the person: PC-301, triage", ""]
    if problems:
        L += ["**The merge failed the audit. This packet is not ready; fix the merge and run triage again.**", ""]
        L += [f"- {p}" for p in problems] + [""]
    L += ["| | |", "|---|---|",
          f"| Eligible to merge | **{'no' if blocks or red or problems else 'yes, once the questions are answered' if questions else 'yes'}**" + (": " + "; ".join(why) if why else "") + " |",
          f"| Risk floor | **{floor}**; sign-off: {SIGN_OFF.get(floor, floor)} |",
          f"| Test suite | {sens['suite']}" + (f"; failed: {sens['failed']}" if sens["failed"] else "") + (f"; {sens['host']}" if sens["host"] else "") + " |",
          f"| Not run | {sens['not_run'] or 'nothing'} |",
          *([f"| Known-defect tests (shown, not counted) | " + "; ".join(f"{d['ticket']}: failed {d['failed']} of {d['runs']} runs" + (f", not found in {d['missing']}" if d["missing"] else "") for d in sens["lane"]) + " |"] if sens["lane"] else []),
          f"| Findings | {len(src)} reported, merged into {len(merged)}: " + ", ".join(f"{sum(1 for t in merged if t['disposition'] == d)} {d}" for d in reversed(ORDER)) + " |",
          f"| Doubt theater | {len(acted)} of {len(substantial)} substantial findings lead to a question, a fix or a task; {len(overruled)} overruled with a reason |", ""]
    if clone:
        reqs = requirements(clone)
        if reqs:
            L += ["## What the change does, from its spec", ""]
            L += [f"- {cap}: {sec.lower()} \"{name}\"" for cap, sec, name in reqs] + [""]
    if questions:
        L += ["## Questions for you", ""]
        for t in questions:
            L += [f"**{t['id']}. {t.get('title', '')}** ({t['disposition']}; {', '.join(t.get('sources', []))})", "",
                  t["question"], ""]
            if t.get("evidence"):
                L += [f"Evidence: {t['evidence']}", ""]
    if fixes:
        L += ["## Going back to the author, then re-checked", ""]
        L += [f"- **{t['id']}** ({t['disposition']}): {t['fix']}" for t in fixes] + [""]
    if blocks:
        L += ["## Blocking", ""] + [f"- **{t['id']}** {t.get('title', '')}" for t in blocks] + [""]
    if data.get("unverified"):
        L += ["## Nobody could verify", ""] + [f"- {u}" for u in data["unverified"]] + [""]
    if data.get("known_defects") or sens["lane"]:
        L += ["## Known defects", ""] + [f"- {k}" for k in data.get("known_defects") or []]
        for d in sens["lane"]:
            note = ("it failed in this run's lane" if d["failed"] else "it passed in every run of the lane, which may mean only that the timing hid it" if d["passed"] == d["runs"] else "it was not found in every run")
            L += [f"- `{d['test']}` ({d['ticket']}) runs in the known-defect lane, outside the build: failed {d['failed']} of {d['runs']} runs; {note}. It does not count toward eligibility while {d['ticket']} is open."]
        L += [""]
    carried = [t for t in merged if t.get("consequence") == "task"]
    if carried:
        L += ["## Carried elsewhere", ""] + [f"- {t['id']} ({t['disposition']}): {t.get('title', '')}" + (f". {t['reason']}" if t.get("reason") else "") for t in carried] + [""]
    shown = set(id(t) for t in questions + fixes + carried)
    logged = [t for t in merged if t.get("consequence") in ("logged", "overruled")]
    shown |= set(id(t) for t in logged)
    lost = [t for t in merged if id(t) not in shown]
    if lost:
        problems.append("findings with no consequence the packet can show: " + ", ".join(str(t.get("id")) for t in lost))
    if logged:
        L += ["## Logged", ""] + [f"- {t['id']} ({t['disposition']}, {t.get('consequence')}): {t.get('title', '')}" + (f". Reason: {t['reason']}" if t.get("reason") else "") for t in logged] + [""]
    if notes:
        L += ["## Policy notes", ""] + [f"- {n}" for n in notes] + [""]
    if problems and not L[2].startswith("**The merge failed"):
        L[2:2] = ["**The merge failed the audit. This packet is not ready; fix the merge and run triage again.**", ""] + [f"- {p}" for p in problems] + [""]
    L += ["## Audit", "", f"Every one of the {len(src)} reported findings is accounted for, and every merged finding appears above." if not problems else f"{len(problems)} problems, listed at the top.", ""]
    out = os.path.join(os.path.dirname(os.path.abspath(inputs)), "packet.md")
    open(out, "w", encoding="utf-8").write("\n".join(L))
    print(f"triage: packet written to {out}" + (f"; {len(problems)} audit problems" if problems else ""))
    return 1 if problems else 0


def main(argv):
    if len(argv) >= 2 and argv[0] == "prepare":
        return prepare(argv[1])
    if len(argv) >= 3 and argv[0] == "check":
        return check(argv[1], argv[2], argv[3] if len(argv) > 3 else None)
    print(__doc__.strip().splitlines()[2], file=sys.stderr)
    print("usage: triage.py prepare <inputs> | check <inputs> <clerk reply> [clone]", file=sys.stderr)
    return 2


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
