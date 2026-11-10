#!/usr/bin/env bash
# Week 3's experiments: plain Claude Code in a container, as in Weeks 1 and 2,
# on one PetClinic clone that every step works on in turn.
#
#   ./demo.sh build                 build the image (once; a few minutes)
#   ./demo.sh reset [ref]           fresh clone for the agent (default week-3-start)
#   ./demo.sh baseline              put the curated baseline spec in the clone (instead of e12's)
#   ./demo.sh check                 preflight: token, image, clone
#   ./demo.sh e12|...|e17           a live run of that experiment, in the clone
#   ./demo.sh e18                   the step 5 sensors on the clone's change (no agent), with the
#                                   known-defect lane; then the
#                                   MySQL and Postgres tests on this machine's Docker
#   ./demo.sh e19                   step 6: independent code review, read-only, with e18's sensors.md
#   ./demo.sh e20                   step 7: a clerk merges every finding; triage.py applies the policy and writes packet.md
#   ./demo.sh e21                   back to step 4: the coding agent works through the gate after triage
#   ./demo.sh show <step> [run]     what a run of a step did (default: the newest)
#   ./demo.sh watch [step] [run]    follow a run as it goes, one line per reply or tool call
#                                   (default: the newest run of any step); ends with the run
#   ./demo.sh apply <step> [run]    put the clone in the state that run left (default: the newest)
#   ./demo.sh stop                  stop any session container left behind
#   ./demo.sh help                  this list
#
# e12 writes the baseline spec from the pins (step 1); e13 refines PC-301 with
# you answering (step 2), and always runs interactively; e14 writes the
# OpenSpec change from e13's decisions log (step 2); e15 reviews that change
# before code (step 3) and saves the review as review.md in its run. Every e15
# reviewer gets the clone read-only except target/ (compose service reviewer or codex).
# e16 revises the change from the gate's answers and the e15 reviews it names; they
# are put in the clone's .review-inputs/ for the run and removed after it, so a later
# review of the revised change never reads the earlier reviews.
# e17 codes the change (step 4) with handoff.md's extra tasks, then reviews its own
# diff; the reply is saved as self-review.md. The checks that judge the change are
# read-only (compose service author), and Week 2's w2-sensors hooks run the
# architecture check after each production edit and at stop; w3-conventions runs
# ./mvnw validate (formatting, http:// URLs) at stop. Time cap 3600 s.
# e21 runs the same author set-up on the coded change, with the newest gate file in
# e20-triage/ (or W3_GATE) and e21's approvals.md; its reply is saved as self-review.md.
# LADDER_MODEL picks the model, so two reviewers can run side by side:
#   LADDER_BATCH=1 LADDER_MODEL=claude-sonnet-5-5 ./demo.sh e15
# LADDER_AGENT=codex runs e15's reviewer on Codex CLI instead (batch only; needs
# CODEX_API_KEY; default model gpt-6.1-sol):
#   LADDER_BATCH=1 LADDER_AGENT=codex ./demo.sh e15
# Before e15's reviewer starts, the harness runs sensors/freeze-probe.sh on a copy
# of the clone and adds the result to the prompt (LADDER_PROBES=0 skips it).
# LADDER_REVIEWER=egm runs e15's review with Google's Elephant-Goldfish Model instead
# (layer w3-egm, prompt e15-egm.txt; batch; the probe goes in as a file):
#   ./demo.sh apply e14; LADDER_REVIEWER=egm ./demo.sh e15
# LADDER_BATCH=1 runs a step unattended with its prompt (stored runs, fallbacks).
# Each run is saved in <step folder>/runs/<date-time>-<model>/. The class runs are kept
# in git; yours are ignored.
# W3_RUNS_ROOT=<dir> saves every run in <dir>/<step folder>/ instead (e22's runner uses it).
# W3_STEP3_RUN=<e15 run> names the step 3 review that e20 takes (default: the last round before code).
# W3_E15_BASELINE=1 gives e15 the project baseline too (default: none, as in the stored class set).
# W3_TICKET=pc-303 runs e14, e17 and e19 on another change: the prompt is prompts/<step>-<ticket>.txt,
# the change is openspec/changes/<ticket>/, and PC-301's handoff and approvals are not used (e23).
set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
skills="$(cd "$here/../../skills" && pwd)"
# Week 3's skills, from this repository's skills/ folder.
w3_skills="refine-requirement review-change review-code triage-findings"
W3_REMOTE="${W3_REMOTE:-https://github.com/qcon-he-course/he-petclinic.git}"
W3_WORK="${W3_WORK:-$HOME/.cache/qcon-he/week3}"
LADDER_AGENT="${LADDER_AGENT:-claude}"
case "$LADDER_AGENT" in
  claude) LADDER_MODEL="${LADDER_MODEL:-claude-opus-5-5}" ;;
  codex) LADDER_MODEL="${LADDER_MODEL:-gpt-6.1-sol}" ;;
  *) echo "demo: LADDER_AGENT is claude or codex, not $LADDER_AGENT" >&2; exit 1 ;;
esac
LADDER_TIME_CAP="${LADDER_TIME_CAP:-}"
ticket="${W3_TICKET:-pc-301}"
export W3_WORK

usage() {  # the comment at the top of this file
  awk 'NR > 1 && /^#/ { sub(/^# ?/, ""); print; next } NR > 1 { exit }' "$0"
}

step_folder() {
  case "$1" in
    e12) echo e12-write-the-baseline ;;
    e13) echo e13-refine-the-ticket ;;
    e14) echo e14-write-the-change ;;
    e15) echo e15-review-before-code ;;
    e16) echo e16-revise-the-change ;;
    e17) echo e17-code-the-change ;;
    e18) echo e18-run-the-sensors ;;
    e19) echo e19-review-the-code ;;
    e20) echo e20-triage ;;
    e21) echo e21-fix-the-findings ;;
    *) return 1 ;;
  esac
}
step_layers() {
  case "$1" in
    e12) echo "w3-base" ;;
    e13) echo "w3-base w3-skills" ;;
    e14) echo "w3-base w3-openspec" ;;
    e15) echo "w3-base w3-skills w3-reviewer" ;;
    e16) echo "w3-base w3-openspec" ;;
    e17) echo "w3-base w3-apply w3-author w2-sensors w3-conventions" ;;
    e19) echo "w3-base w3-skills w3-reviewer" ;;
    e20) echo "w3-base w3-skills w3-reviewer" ;;
    e21) echo "w3-base w3-apply w3-author w2-sensors w3-conventions" ;;
    *) return 1 ;;
  esac
}

clone() {  # clone <dest> <ref>
  rm -rf "$1"
  mkdir -p "$(dirname "$1")"
  git clone --quiet "$W3_REMOTE" "$1"
  git -C "$1" -c advice.detachedHead=false checkout --quiet "$2"
}

runs_dir() {  # runs_dir <step folder>: where its runs go; W3_RUNS_ROOT keeps a set apart (e22)
  if [ -n "${W3_RUNS_ROOT:-}" ]; then echo "$W3_RUNS_ROOT/$1"; else echo "$here/$1/runs"; fi
}

latest_run() {  # latest_run <step>: the newest run folder of that step
  local folder
  folder="$(step_folder "$1")" || return 1
  find "$(runs_dir "$folder")" -mindepth 1 -maxdepth 1 -type d 2> /dev/null | sort | tail -1
}

snapshot() {  # snapshot <clone>: the diff against the checked-out commit, new files included
  git -C "$1" add --intent-to-add --all
  git -C "$1" diff
  git -C "$1" reset --quiet
}

summary() {  # summary <run folder>: works on a batch transcript and on an interactive session
  python3 - "$1" <<'PY'
import json, os, sys
run = sys.argv[1]
path = os.path.join(run, "transcript.jsonl")
if not os.path.exists(path):
    print("show: no transcript")
    sys.exit(0)
steps, final, last_text, turns = [], "", "", 0
for line in open(path, encoding="utf-8"):
    try:
        ev = json.loads(line)
    except ValueError:
        continue
    if ev.get("type") == "user" and isinstance(ev.get("message", {}).get("content"), str):
        turns += 1
    if ev.get("type") == "assistant":
        for c in ev.get("message", {}).get("content", []) or []:
            if c.get("type") == "text" and c.get("text", "").strip():
                last_text = c["text"]
            if c.get("type") != "tool_use":
                continue
            n, i = c["name"], c.get("input", {})
            if n == "Skill":
                steps.append("skill   " + str(i.get("skill") or i.get("command")))
            elif n in ("Edit", "Write", "MultiEdit"):
                steps.append("edit    " + i.get("file_path", "").split("/work/")[-1])
            elif n == "Bash":
                steps.append("shell   " + i.get("command", "").replace("\n", " ")[:110])
            elif n == "Agent" or n == "Task":
                steps.append("agent   " + str(i.get("description", ""))[:110])
    if ev.get("type") == "result":
        final = ev.get("result", "")
    # Codex CLI's exec --json events
    if ev.get("type") == "item.completed":
        it = ev.get("item", {})
        t = it.get("type")
        if t == "command_execution":
            steps.append("shell   " + str(it.get("command", "")).replace("\n", " ")[:110])
        elif t == "file_change":
            steps.append("edit    " + ", ".join(c.get("path", "").split("/work/")[-1] for c in it.get("changes", [])))
        elif t == "mcp_tool_call":
            steps.append("tool    " + str(it.get("tool", "")))
        elif t == "agent_message" and str(it.get("text", "")).strip():
            last_text = it["text"]
for k, s in enumerate(steps, 1):
    print(f"{k:3d} {s}")
if turns:
    print(f"\nmessages typed by the person: {turns}")
print("\n--- final answer ---\n" + (final or last_text))
PY
}

final_reply() {  # final_reply <run folder>: the agent's last answer, from either kind of transcript
  python3 - "$1" <<'PY'
import json, os, sys
path = os.path.join(sys.argv[1], "transcript.jsonl")
final, last = "", ""
if os.path.exists(path):
    for line in open(path, encoding="utf-8"):
        try:
            ev = json.loads(line)
        except ValueError:
            continue
        if ev.get("type") == "result":
            final = ev.get("result", "")
        if ev.get("type") == "assistant":
            for c in ev.get("message", {}).get("content", []) or []:
                if c.get("type") == "text" and c.get("text", "").strip():
                    last = c["text"]
print(final or last)
PY
}

newest_gate() {  # newest_gate <folder>: its gate file with the highest round (no -roundN is round 1)
  local f n
  for f in "$1"/gate-*.md; do
    [ -f "$f" ] || continue
    n="$(basename "$f" .md | sed -n 's/.*-round\([0-9][0-9]*\)$/\1/p')"
    echo "${n:-1} $f"
  done | sort -n | tail -1 | cut -d' ' -f2-
}

cmd="${1:-}"
case "$cmd" in
  build)
    cd "$here" && docker compose build session
    ;;

  reset)
    ref="${2:-week-3-start}"
    clone "$W3_WORK/petclinic" "$ref"
    echo "demo: the agent's clone is $W3_WORK/petclinic, at $ref ($(git -C "$W3_WORK/petclinic" rev-parse --short HEAD))"
    ;;

  baseline)
    work="$W3_WORK/petclinic"
    [ -d "$work/.git" ] || { echo "baseline: no clone; run ./demo.sh reset first" >&2; exit 1; }
    mkdir -p "$work/openspec/specs/pets"
    cp "$here/baseline/pets-spec.md" "$work/openspec/specs/pets/spec.md"
    echo "baseline: the curated spec is at openspec/specs/pets/spec.md in the clone"
    ;;

  check)
    ok=1
    item() {  # item <label> <message if ok> <message if not> <command...>
      local label="$1" yes="$2" no="$3"; shift 3
      if "$@" > /dev/null 2>&1; then echo "$label $yes"; else echo "$label $no"; ok=0; fi
    }
    item "token  " "set" "CLAUDE_CODE_OAUTH_TOKEN is not set" test -n "${CLAUDE_CODE_OAUTH_TOKEN:-}"
    if [ -n "${CODEX_API_KEY:-}" ]; then echo "codex   CODEX_API_KEY set"; else echo "codex   CODEX_API_KEY not set (needed only for LADDER_AGENT=codex)"; fi
    item "image  " "he-week3" "missing: ./demo.sh build" docker image inspect he-week3
    if [ -d "$W3_WORK/petclinic/.git" ]; then
      echo "clone   $(git -C "$W3_WORK/petclinic" log --oneline -1), $(git -C "$W3_WORK/petclinic" status --porcelain | wc -l | tr -d ' ') changed files"
      if [ -f "$W3_WORK/petclinic/openspec/specs/pets/spec.md" ]; then echo "spec    openspec/specs/pets/spec.md present"; else echo "spec    none yet (e12 writes it; ./demo.sh baseline puts the curated one)"; fi
    else
      echo "clone   missing: ./demo.sh reset"; ok=0
    fi
    if [ "$ok" = 1 ]; then echo "demo: ready"; else echo "demo: not ready"; exit 1; fi
    ;;

  stop)
    cd "$here" && docker compose down --remove-orphans
    echo "demo: stopped. The clone, the Maven cache and the stored runs are kept; ./demo.sh reset starts over."
    ;;

  show)
    step_folder "${2:-}" > /dev/null || { echo "usage: ./demo.sh show e12|...|e17 [run]" >&2; exit 1; }
    latest="$(latest_run "$2")"
    [ -n "${3:-}" ] && latest="$(runs_dir "$(step_folder "$2")")/$3"
    [ -n "$latest" ] && [ -d "$latest" ] || { echo "show: no run of ${2}${3:+ named $3}" >&2; exit 1; }
    echo "show: $latest"
    if [ -f "$latest/packet.md" ]; then cat "$latest/packet.md"
    elif [ -f "$latest/sensors.md" ]; then cat "$latest/sensors.md"
    else summary "$latest"; fi
    [ -s "$latest/diff.patch" ] && { echo; echo "--- files changed ---"; git apply --stat "$latest/diff.patch" 2> /dev/null || true; }
    ;;

  watch)
    # Follow a run's transcript (Claude Code stream-json or Codex --json); e18 has none, so
    # its sensor log instead. Ends when demo.sh writes the run's summary, or on Ctrl-C,
    # which stops the view and leaves the run alone.
    if [ -n "${2:-}" ]; then
      step_folder "$2" > /dev/null || { echo "usage: ./demo.sh watch [e12|...|e21] [run]" >&2; exit 1; }
      latest="$(latest_run "$2")"
      [ -n "${3:-}" ] && latest="$(runs_dir "$(step_folder "$2")")/$3"
    else
      roots="$here/e*/runs"; [ -n "${W3_RUNS_ROOT:-}" ] && roots="$W3_RUNS_ROOT/*"
      latest="$(find $roots -mindepth 1 -maxdepth 1 -type d 2> /dev/null |
        awk -F/ '{ print $NF "\t" $0 }' | sort | tail -1 | cut -f2)"
    fi
    [ -n "$latest" ] && [ -d "$latest" ] || { echo "watch: no run${2:+ of $2}${3:+ named $3}" >&2; exit 1; }
    echo "watch: $latest (Ctrl-C stops the view, not the run)"
    python3 - "$latest" <<'PY'
import json, os, sys, time
run = sys.argv[1]
done = lambda: os.path.exists(os.path.join(run, "summary.txt")) or os.path.exists(os.path.join(run, "diff.patch"))
path = os.path.join(run, "transcript.jsonl")
raw = os.path.exists(os.path.join(run, "sensors")) and not os.path.exists(path)  # e18: the sensor log
if raw:
    path = os.path.join(run, "stderr.txt")
def short(x, n):
    return " ".join(str(x).split())[:n]
def lines(e):
    t = e.get("type")
    if t == "assistant":  # Claude Code
        for c in e.get("message", {}).get("content", []):
            if c.get("type") == "text" and c.get("text", "").strip():
                yield "SAY  " + short(c["text"], 200)
            elif c.get("type") == "tool_use":
                i = c.get("input", {})
                what = i.get("command") or i.get("file_path") or i.get("skill") or i.get("pattern") or i.get("description") or ""
                yield f"TOOL {c.get('name')}  {short(what, 140)}"
    elif t == "user":
        content = e.get("message", {}).get("content")
        for c in content if isinstance(content, list) else []:
            if c.get("type") == "tool_result" and c.get("is_error"):
                body = c.get("content")
                body = body if isinstance(body, str) else " ".join(x.get("text", "") for x in body or [] if isinstance(x, dict))
                yield "  ERR " + short(body, 160)
    elif t == "result":
        secs = (e.get("duration_ms") or 0) // 1000
        yield f"DONE {e.get('subtype', '')}, {e.get('num_turns', '?')} turns, {secs} s, ${e.get('total_cost_usd') or 0:.2f}"
    elif t == "item.completed":  # Codex
        it = e.get("item", {})
        k = it.get("type")
        if k == "agent_message":
            yield "SAY  " + short(it.get("text", ""), 200)
        elif k == "command_execution":
            yield "TOOL shell  " + short(it.get("command", ""), 140) + ("" if it.get("exit_code") in (0, None) else f"  (exit {it.get('exit_code')})")
        elif k == "file_change":
            yield "TOOL edit  " + ", ".join(c.get("path", "") for c in it.get("changes", []))
    elif t == "turn.completed":
        u = e.get("usage", {})
        yield f"DONE turn, {u.get('input_tokens', '?')} tokens in, {u.get('output_tokens', '?')} out"
def follow():
    while not os.path.exists(path):
        if done():
            return
        time.sleep(1)
    with open(path, encoding="utf-8", errors="replace") as f:
        buf = ""
        while True:
            chunk = f.readline()
            if chunk:
                buf += chunk
                if not buf.endswith("\n"):
                    continue
                line, buf = buf.rstrip("\n"), ""
                if raw:
                    print(line, flush=True)
                    continue
                try:
                    e = json.loads(line)
                except ValueError:
                    continue
                for out in lines(e):
                    print(out, flush=True)
            elif done():
                return
            else:
                time.sleep(0.5)
try:
    follow()
    print("watch: the run has ended" + (", at the time cap" if os.path.exists(os.path.join(run, "timed-out.txt")) else ""))
except KeyboardInterrupt:
    print()
PY
    ;;

  apply)
    step_folder "${2:-}" > /dev/null || { echo "usage: ./demo.sh apply e12|...|e17 [run]" >&2; exit 1; }
    latest="$(latest_run "$2")"
    [ -n "${3:-}" ] && latest="$(runs_dir "$(step_folder "$2")")/$3"
    [ -n "$latest" ] && [ -s "$latest/diff.patch" ] || { echo "apply: no stored run of $2 with changes${3:+ named $3}" >&2; exit 1; }
    work="$W3_WORK/petclinic"
    [ -d "$work/.git" ] || { echo "apply: no clone; run ./demo.sh reset first" >&2; exit 1; }
    commit="$(cut -d' ' -f1 "$latest/start-commit.txt")"
    echo "apply: the clone's own changes are replaced by the state after $(basename "$latest")"
    git -C "$work" checkout --quiet -- .
    git -C "$work" clean -fdq
    git -C "$work" -c advice.detachedHead=false checkout --quiet "$commit"
    git -C "$work" apply --whitespace=nowarn "$latest/diff.patch"
    echo "apply: clone at $(git -C "$work" log --oneline -1), $(git -C "$work" status --porcelain | wc -l | tr -d ' ') changed files"
    ;;

  e18)
    # Step 5: deterministic sensors on the change the clone holds, in the container.
    # No agent and no Claude token; the build runs the change's code.
    work="$W3_WORK/petclinic"
    [ -d "$work/.git" ] || { echo "demo: no clone; run ./demo.sh reset first" >&2; exit 1; }
    [ -n "$(git -C "$work" status --porcelain -- src)" ] || { echo "demo: e18 needs a code change in the clone; run ./demo.sh apply e17 first" >&2; exit 1; }
    run="$(runs_dir e18-run-the-sensors)/$(date +%Y%m%d-%H%M%S)"
    mkdir -p "$run/sensors" "$run/config" "$run/layers"
    cp "$here/sensors/"*.py "$here/sensors/"*.sh "$here/sensors/risk-rules.txt" "$run/sensors/"
    rm -f "$run/sensors/"*.test.sh
    # Tests tied to an open known-defect ticket run in a lane of their own; a closed or
    # missing ticket stops the run, so the list cannot hide a failure.
    python3 "$here/sensors/known-defects.py" check "$here/baseline/known-defect-tests.txt" "$here" \
      > "$run/sensors/known-defect-tests.txt" || { echo "demo: fix baseline/known-defect-tests.txt first" >&2; exit 1; }
    [ -s "$run/sensors/known-defect-tests.txt" ] && echo "demo: known-defect lane: $(cut -d' ' -f2 "$run/sensors/known-defect-tests.txt" | sort -u | tr '\n' ' ')"
    git -C "$work" log --oneline -1 > "$run/start-commit.txt"
    snapshot "$work" > "$run/start-diff.patch"
    echo "demo: e18 (step 5 sensors) on $(cat "$run/start-commit.txt") plus $(git -C "$work" status --porcelain | wc -l | tr -d ' ') changed files; a few minutes"
    export LADDER_CONFIG="$run/config" LADDER_LAYERS="" LADDER_LAYERS_DIR="$run/layers" LADDER_RECORD="$run"
    cd "$here"
    docker compose build -q session
    docker compose run --rm -T --user node --entrypoint bash session /record/sensors/step5.sh /work /record \
      < /dev/null > "$run/stdout.txt" 2> "$run/stderr.txt" || echo "demo: the sensor run exited with an error, see $run/stderr.txt" >&2
    # The MySQL and Postgres tests need Docker, which no agent container has: the harness
    # runs them here on the host (W3_DOCKER_TESTS=0 skips them).
    if [ "${W3_DOCKER_TESTS:-1}" != 0 ] && [ -f "$run/sensors.md" ]; then
      bash "$here/sensors/step5-docker.sh" "$work" "$run" 2>> "$run/stderr.txt"
    fi
    # Scenario coverage last, so it reads the suite's, the lane's and the host's reports.
    if [ -f "$run/sensors.md" ]; then
      python3 "$here/sensors/scenario-coverage.py" --into "$run/sensors.md" "$work" \
        "$run/suite-reports" "$run"/known-reports-* "$run"/docker-reports-* || true
    fi
    snapshot "$work" > "$run/diff.patch"
    cmp -s "$run/start-diff.patch" "$run/diff.patch" || echo "demo: the clone changed during the sensor run; see $run/diff.patch" >&2
    [ -f "$run/sensors.md" ] && cat "$run/sensors.md"
    echo "demo: saved in $run"
    ;;

  e12|e13|e14|e15|e16|e17|e19|e20|e21)
    folder="$(step_folder "$cmd")"
    layers="$(step_layers "$cmd")"
    work="$W3_WORK/petclinic"
    [ -d "$work/.git" ] || { echo "demo: no clone; run ./demo.sh reset first" >&2; exit 1; }
    if [ "$cmd" = e13 ] && [ ! -f "$work/openspec/specs/pets/spec.md" ]; then
      echo "demo: e13 needs a baseline spec; run ./demo.sh apply e12 or ./demo.sh baseline first" >&2; exit 1
    fi
    if [ "$cmd" = e14 ] && [ ! -f "$work/openspec/changes/$ticket/decisions.md" ]; then
      echo "demo: e14 needs the decisions log; run ./demo.sh apply e13 first" >&2; exit 1
    fi
    if [ "$cmd" = e15 ] && [ ! -f "$work/openspec/changes/pc-301/proposal.md" ]; then
      echo "demo: e15 needs the change; run ./demo.sh apply e14 first" >&2; exit 1
    fi
    if [ "$cmd" = e20 ]; then
      sensors_run="$(latest_run e18)"
      # The last review of the change before code. Not the newest e15 run: a live class run
      # and the EGM comparison are newer, and both review e14's change before the gates.
      step3_run="$here/e15-review-before-code/runs/${W3_STEP3_RUN:-20261101-055318-claude-opus-5-5}"
      [ -f "$step3_run/review.md" ] || { echo "demo: e20 needs the step 3 review; no review.md in $step3_run" >&2; exit 1; }
      [ -n "$sensors_run" ] && [ -n "$(latest_run e19)" ] || { echo "demo: e20 needs runs of e18 and e19" >&2; exit 1; }
    fi
    if [ "$cmd" = e19 ]; then
      sensors_run="$(latest_run e18)"
      [ -n "$sensors_run" ] && [ -f "$sensors_run/sensors.md" ] || { echo "demo: e19 needs the step 5 sensors; run ./demo.sh e18 first" >&2; exit 1; }
      [ -n "$(git -C "$work" status --porcelain -- src)" ] || { echo "demo: e19 needs the coded change; run ./demo.sh apply e17 first" >&2; exit 1; }
    fi
    if [ "$cmd" = e17 ]; then
      [ -f "$work/openspec/changes/$ticket/tasks.md" ] || { echo "demo: e17 needs the change; run ./demo.sh apply e16 first" >&2; exit 1; }
      if [ "$ticket" = pc-301 ]; then
        [ -f "$here/e17-code-the-change/handoff.md" ] || { echo "demo: e17 needs e17-code-the-change/handoff.md" >&2; exit 1; }
      fi
    fi
    if [ "$cmd" = e21 ]; then
      # The newest gate after triage, or the one W3_GATE names.
      gate="${W3_GATE:-$(newest_gate "$here/e20-triage")}"
      [ -n "$gate" ] || { echo "demo: e21 needs a gate file in e20-triage/" >&2; exit 1; }
      [ -n "$(git -C "$work" status --porcelain -- src)" ] || { echo "demo: e21 needs the coded change; run ./demo.sh apply e17 first" >&2; exit 1; }
    fi
    if [ "$cmd" = e16 ]; then
      # The newest gate file, or the one W3_GATE names.
      gate="${W3_GATE:-$(newest_gate "$here/e15-review-before-code")}"
      [ -f "$work/openspec/changes/pc-301/proposal.md" ] || { echo "demo: e16 needs the change; run ./demo.sh apply e14 first" >&2; exit 1; }
      [ -n "$gate" ] || { echo "demo: e16 needs a gate file in e15-review-before-code/" >&2; exit 1; }
    fi
    cap="${LADDER_TIME_CAP:-1200}"
    case "$cmd" in e17|e21) cap="${LADDER_TIME_CAP:-3600}" ;; esac
    batch="${LADDER_BATCH:-}"
    [ "$cmd" = e13 ] && batch=""
    if [ "$LADDER_AGENT" = codex ]; then
      case "$cmd" in e15|e19) ;; *) echo "demo: LADDER_AGENT=codex is for the reviewers, e15 and e19" >&2; exit 1 ;; esac
      [ -n "${CODEX_API_KEY:-}" ] || { echo "demo: set CODEX_API_KEY in your shell for a Codex reviewer" >&2; exit 1; }
      batch=1
      layers="w3-codex"
    fi
    # LADDER_REVIEWER=egm: e15's review by Google's Elephant-Goldfish Model (layer w3-egm).
    reviewer="${LADDER_REVIEWER:-}"
    if [ "$reviewer" = egm ]; then
      [ "$cmd" = e15 ] && [ "$LADDER_AGENT" = claude ] || { echo "demo: LADDER_REVIEWER=egm is for e15 on Claude" >&2; exit 1; }
      batch=1
      layers="w3-base w3-egm"
      cap="${LADDER_TIME_CAP:-3600}"
    elif [ -n "$reviewer" ]; then
      echo "demo: LADDER_REVIEWER is egm or unset, not $reviewer" >&2; exit 1
    fi
    stamp="$(date +%Y%m%d-%H%M%S)-$LADDER_MODEL${reviewer:+-$reviewer}"
    run="$(runs_dir "$folder")/$stamp"
    mkdir -p "$run/config" "$run/layers"
    # Skip Claude Code's first-launch setup; the trust prompt still appears.
    echo '{"hasCompletedOnboarding": true}' > "$run/config/.claude.json"
    for l in $layers; do
      # Week 3's layers, or a Week 2 layer reused unchanged (w2-sensors).
      src="$here/layers/$l"
      [ -d "$src" ] || src="$here/../week-2/layers/$l"
      [ -d "$src" ] || { echo "demo: no layer $l" >&2; exit 1; }
      cp -R "$src" "$run/layers/$l"
    done
    if [ -d "$run/layers/w3-skills" ]; then
      rm -f "$run/layers/w3-skills/README.md"
      mkdir -p "$run/layers/w3-skills/skills"
      for name in $w3_skills; do
        mkdir -p "$run/layers/w3-skills/skills/$name"
        cp "$skills/$name/SKILL.md" "$run/layers/w3-skills/skills/$name/"
      done
    fi
    chmod 0755 "$run"/layers/*/*.sh 2> /dev/null || true
    if [ "$LADDER_AGENT" = codex ]; then
      # The run's CODEX_HOME: config, AGENTS.md from the same rules Claude gets, the skills.
      home="$run/codex-home"
      mkdir -p "$home/skills"
      cp "$here/layers/w3-codex/config.toml" "$home/config.toml"
      { grep -v '^- Batch runs deny' "$here/layers/w3-base/rules.md"; echo
        cat "$here/layers/w3-reviewer/rules.md"; } > "$home/AGENTS.md"
      for name in $w3_skills; do
        mkdir -p "$home/skills/$name"
        cp "$skills/$name/SKILL.md" "$home/skills/$name/"
      done
      export LADDER_CODEX_HOME="$home"
    fi
    # e15's reviewers run in a service with the clone read-only except target/.
    service=session
    case "$cmd" in e15|e19|e20) service=reviewer; mkdir -p "$work/target" ;; esac
    compose_files=(-f "$here/compose.yaml")
    if [ "$cmd" = e17 ] || [ "$cmd" = e21 ]; then
      service=author
      approvals=""
      # A person's approvals belong to PC-301's runs; another ticket gets none.
      [ "$ticket" = pc-301 ] && [ -f "$here/$folder/approvals.md" ] && approvals="$here/$folder/approvals.md"
      # Read-only mounts over the protected checks, minus any a person approved a change to.
      protect="$run/compose.protect.yaml"
      { echo "services:"; echo "  author:"; echo "    volumes:"
        python3 "$here/sensors/protected-paths.py" ${approvals:+--approvals "$approvals"} "$work" |
          while IFS= read -r p; do echo "      - \"$work/$p:/work/$p:ro\""; done; } > "$protect"
      compose_files+=(-f "$protect")
      echo "demo: protected checks read-only: $(grep -c ':ro"' "$protect")${approvals:+, approved for change: $(grep -cE '^[[:space:]]*[-*][[:space:]]+`' "$approvals")}"
    fi
    if [ "$cmd" = e16 ]; then
      # The gate's answers and the reviews it names, for this run only.
      inputs="$work/.review-inputs"
      rm -rf "$inputs"; mkdir -p "$inputs"
      cp "$gate" "$inputs/gate.md"
      echo "demo: e16 inputs from $(basename "$gate")"
      for r in $(grep -oE 'runs/[0-9]{8}-[0-9]{6}-[A-Za-z0-9.-]+' "$gate" | sort -u); do
        name="$(basename "$r")"
        [ -f "$here/e15-review-before-code/$r/review.md" ] || { echo "demo: the gate names $r, which has no review.md" >&2; exit 1; }
        cp "$here/e15-review-before-code/$r/review.md" "$inputs/review-${name#*-*-}.md"
      done
      grep -qx '.review-inputs/' "$work/.git/info/exclude" 2> /dev/null || echo '.review-inputs/' >> "$work/.git/info/exclude"
      cp -R "$inputs" "$run/inputs"
    fi
    if [ "$cmd" = e15 ] && [ "$reviewer" = egm ]; then
      # EGM reviews one design document: the proposed change assembled in order, with the
      # tasks under the "## Detailed Implementation Plan" boundary its review looks for.
      # Its reports go to target/egm, the one writable folder. No project baseline: the
      # step-3 class set had none.
      rm -rf "$work/target/egm"; mkdir -p "$work/target/egm"
      python3 - "$work/openspec/changes/pc-301" "$work/target/egm/pc-301-design.md" <<'PY'
import os, re, sys
change, out = sys.argv[1:]
demote = lambda t: re.sub(r"^(#+) ", r"##\1 ", t, flags=re.M)
read = lambda p: open(os.path.join(change, p), encoding="utf-8").read().strip()
parts = ["# PC-301: record a pet's microchip number", "",
         "The proposed OpenSpec change `openspec/changes/pc-301/`, assembled into one document for review: the proposal, the spec deltas, the design, then the tasks as the implementation plan. Its decisions log is `openspec/changes/pc-301/decisions.md`.", "",
         "## Proposal", "", demote(read("proposal.md")), ""]
for d in sorted(os.listdir(os.path.join(change, "specs"))):
    parts += [f"## Spec delta: {d}", "", demote(read(os.path.join("specs", d, "spec.md"))), ""]
parts += ["## Design", "", demote(read("design.md")), "", "## Detailed Implementation Plan", "", demote(read("tasks.md")), ""]
open(out, "w", encoding="utf-8").write("\n".join(parts))
PY
      echo "demo: EGM target $(wc -l < "$work/target/egm/pc-301-design.md" | tr -d ' ') lines in target/egm/pc-301-design.md"
    elif [ "$cmd" = e15 ]; then
      # No project baseline by default: the stored class set had none, and step 1's prediction
      # rests on that. Clear any left by an earlier run: `git clean` keeps excluded files.
      inputs="$work/.review-inputs"
      rm -rf "$inputs"
      if [ -n "${W3_E15_BASELINE:-}" ]; then
        mkdir -p "$inputs"
        cp "$here/baseline/project-baseline.md" "$inputs/project-baseline.md"
        grep -qx '.review-inputs/' "$work/.git/info/exclude" 2> /dev/null || echo '.review-inputs/' >> "$work/.git/info/exclude"
        cp -R "$inputs" "$run/inputs"
      fi
    fi
    if [ "$cmd" = e20 ]; then
      # Every review still open: the last review of the change (step 3), the newest code
      # review per model (step 6), the sensors (step 5), and the project baseline.
      inputs="$work/.review-inputs"
      rm -rf "$inputs"; mkdir -p "$inputs"
      cp "$step3_run/review.md" "$inputs/review-step3-$(basename "$step3_run" | cut -d- -f3-).md"
      for m in $(find "$(runs_dir e19-review-the-code)" -mindepth 1 -maxdepth 1 -type d -exec basename {} \; | cut -d- -f3- | sort -u); do
        r="$(find "$(runs_dir e19-review-the-code)" -mindepth 1 -maxdepth 1 -type d -name "*-$m" | sort | tail -1)"
        [ -f "$r/review.md" ] && cp "$r/review.md" "$inputs/review-step6-$m.md"
      done
      cp "$sensors_run/sensors.md" "$inputs/sensors.md"
      cp "$here/baseline/project-baseline.md" "$inputs/project-baseline.md"
      python3 "$here/sensors/triage.py" prepare "$inputs" > /dev/null
      echo "demo: e20 inputs: $(cd "$inputs" && ls review-*.md | tr '\n' ' ')and sensors from $(basename "$sensors_run"); $(grep -c '^| `' "$inputs/sources.md") findings to account for"
      grep -qx '.review-inputs/' "$work/.git/info/exclude" 2> /dev/null || echo '.review-inputs/' >> "$work/.git/info/exclude"
      cp -R "$inputs" "$run/inputs"
    fi
    if [ "$cmd" = e19 ]; then
      # The sensor results and the project baseline only: never the coding agent's self-review or handoff.
      inputs="$work/.review-inputs"
      rm -rf "$inputs"; mkdir -p "$inputs"
      cp "$sensors_run/sensors.md" "$inputs/sensors.md"
      cp "$here/baseline/project-baseline.md" "$inputs/project-baseline.md"
      echo "demo: e19 inputs: sensors from $(basename "$sensors_run")"
      grep -qx '.review-inputs/' "$work/.git/info/exclude" 2> /dev/null || echo '.review-inputs/' >> "$work/.git/info/exclude"
      cp -R "$inputs" "$run/inputs"
    fi
    if [ "$cmd" = e17 ]; then
      inputs="$work/.review-inputs"
      rm -rf "$inputs"; mkdir -p "$inputs"
      [ "$ticket" = pc-301 ] && cp "$here/e17-code-the-change/handoff.md" "$inputs/handoff.md"
      if [ -n "$approvals" ]; then cp "$approvals" "$inputs/approvals.md"; fi
      grep -qx '.review-inputs/' "$work/.git/info/exclude" 2> /dev/null || echo '.review-inputs/' >> "$work/.git/info/exclude"
      cp -R "$inputs" "$run/inputs"
    fi
    if [ "$cmd" = e21 ]; then
      # The gate after triage and its approvals only: never the reviews or the packet.
      inputs="$work/.review-inputs"
      rm -rf "$inputs"; mkdir -p "$inputs"
      cp "$gate" "$inputs/gate.md"
      if [ -n "$approvals" ]; then cp "$approvals" "$inputs/approvals.md"; fi
      echo "demo: e21 inputs from $(basename "$gate")"
      grep -qx '.review-inputs/' "$work/.git/info/exclude" 2> /dev/null || echo '.review-inputs/' >> "$work/.git/info/exclude"
      cp -R "$inputs" "$run/inputs"
    fi
    pfile="$here/prompts/$cmd${reviewer:+-$reviewer}.txt"
    [ "$ticket" != pc-301 ] && pfile="$here/prompts/$cmd-$ticket.txt"
    [ -f "$pfile" ] || { echo "demo: no prompt $pfile for $cmd on $ticket" >&2; exit 1; }
    prompt="$(cat "$pfile")"
    if [ "$cmd" = e15 ] && [ -z "$reviewer" ] && [ -n "${W3_E15_BASELINE:-}" ]; then
      prompt="$prompt The project's architecture and conventions, which every change is held to, are in .review-inputs/project-baseline.md."
    fi
    git -C "$work" log --oneline -1 > "$run/start-commit.txt"
    snapshot "$work" > "$run/start-diff.patch"
    echo "demo: $cmd ($folder), layers: $layers, agent $LADDER_AGENT, model $LADDER_MODEL"
    echo "demo: clone at $(cat "$run/start-commit.txt"), $(git -C "$work" status --porcelain | wc -l | tr -d ' ') changed files"

    export LADDER_CONFIG="$run/config" LADDER_LAYERS="$layers" LADDER_LAYERS_DIR="$run/layers" LADDER_RECORD="$run"
    cd "$here"
    docker compose build -q session
    # e15: a deterministic probe of a sensor, run by the harness on a copy of the
    # clone. The reviewer gets the result; it cannot run the probe itself.
    if [ "$cmd" = e15 ] && [ "${LADDER_PROBES:-1}" != 0 ]; then
      echo "demo: probing the architecture rule on a copy of the clone (about a minute)"
      if docker compose run --rm -T --user node --entrypoint bash reviewer -s \
           < "$here/sensors/freeze-probe.sh" > "$run/probes.md" 2> "$run/probes.log"; then
        if [ "$reviewer" = egm ]; then
          # For EGM the probe is a file in its reading list (GoldfishContext), not a prompt line.
          cp "$run/probes.md" "$work/target/egm/probe.md"
        else
        prompt="$prompt

Before your review, the harness ran this probe on a throwaway copy of the code. You may cite it as evidence.

$(cat "$run/probes.md")"
        fi
      else
        echo "demo: the probe failed, see $run/probes.log; the review runs without it" >&2
      fi
    fi
    printf '%s\n' "$prompt" > "$run/prompt.txt"
    if command -v pbcopy > /dev/null; then printf '%s' "$prompt" | pbcopy; echo "demo: the prompt is on the clipboard"
    else echo "demo: the prompt is in $run/prompt.txt"; fi
    if [ "$LADDER_AGENT" = codex ]; then
      container="he-week3-run-$stamp"
      docker compose run --rm -T --name "$container" codex \
        exec --json -o /record/review.md -m "$LADDER_MODEL" \
          --dangerously-bypass-approvals-and-sandbox -C /work "$prompt" \
        < /dev/null > "$run/transcript.jsonl" 2> "$run/stderr.txt" &
      agent=$!
      ( sleep "$cap"; echo "stopped at the time cap, $cap s" > "$run/timed-out.txt"; docker stop "$container" ) > /dev/null 2>&1 &
      watchdog=$!
      wait "$agent" || echo "demo: codex exited with an error, see $run/stderr.txt" >&2
      kill "$watchdog" 2> /dev/null || true
      wait "$watchdog" 2> /dev/null || true
    elif [ "$batch" = 1 ]; then
      container="he-week3-run-$stamp"
      docker compose "${compose_files[@]}" run --rm -T --name "$container" "$service" \
        claude -p "$prompt" --model "$LADDER_MODEL" --permission-mode dontAsk \
          --output-format stream-json --verbose \
        < /dev/null > "$run/transcript.jsonl" 2> "$run/stderr.txt" &
      agent=$!
      ( sleep "$cap"; echo "stopped at the time cap, $cap s" > "$run/timed-out.txt"; docker stop "$container" ) > /dev/null 2>&1 &
      watchdog=$!
      wait "$agent" || echo "demo: claude exited with an error, see $run/stderr.txt" >&2
      kill "$watchdog" 2> /dev/null || true
      wait "$watchdog" 2> /dev/null || true
    else
      if [ -f "$here/$folder/cue.md" ]; then
        echo; sed 's/^/  | /' "$here/$folder/cue.md"; echo
      fi
      echo "demo: paste the prompt when Claude Code is ready"
      docker compose "${compose_files[@]}" run --rm "$service" claude --model "$LADDER_MODEL" || true
      # An interactive run keeps its session under config/projects/; keep the newest as the transcript.
      session="$(find "$run/config/projects" -name '*.jsonl' -type f -exec ls -t {} + 2> /dev/null | head -1 || true)"
      if [ -n "$session" ]; then cp "$session" "$run/transcript.jsonl"; fi
    fi
    summary "$run" > "$run/summary.txt"
    # e15: the reviewer's final reply is the review. It stays in the run folder, so a
    # second reviewer working on the same clone never reads the first one's review.
    # Codex writes review.md itself (exec -o).
    if [ "$reviewer" = egm ]; then
      # EGM's reports, from target/egm; its consolidated report is the review.
      mkdir -p "$run/egm"
      cp "$work"/target/egm/*.md "$run/egm/" 2> /dev/null || true
      final_reply "$run" > "$run/reply.md"
      if [ -f "$run/egm/consolidated_review_report.md" ]; then cp "$run/egm/consolidated_review_report.md" "$run/review.md"
      else cp "$run/reply.md" "$run/review.md"; echo "demo: EGM wrote no consolidated report; review.md is its final reply" >&2; fi
      rm -rf "$work/target/egm"
    else
    case "$cmd" in e15|e19) [ "$LADDER_AGENT" = claude ] && final_reply "$run" > "$run/review.md" ;; esac
    fi
    # e20: the clerk's reply goes to the policy script, which audits it and writes the packet.
    if [ "$cmd" = e20 ]; then
      final_reply "$run" > "$run/clerk-reply.md"
      python3 "$here/sensors/triage.py" check "$run/inputs" "$run/clerk-reply.md" "$work" || echo "demo: the merge failed triage's audit; see $run/packet.md" >&2
    fi
    # e17: the coding agent's last reply is its self-review. Step 6's reviewer never gets it.
    case "$cmd" in e17|e21) final_reply "$run" > "$run/self-review.md" ;; esac
    case "$cmd" in e15|e16|e17|e19|e20|e21) rm -rf "$work/.review-inputs" ;; esac
    snapshot "$work" > "$run/diff.patch"
    git -C "$work" status --porcelain --untracked-files=all > "$run/end-status.txt"
    echo "demo: saved in $run"
    ;;

  help|-h|--help)
    usage
    ;;

  *)
    usage
    exit 1
    ;;
esac
