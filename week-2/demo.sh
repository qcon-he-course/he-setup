#!/usr/bin/env bash
# Week 2's experiments, e7 to e11: plain Claude Code in a container, on one
# PetClinic clone that every step works on in turn. README.md explains each step.
#
#   ./demo.sh build                 build the image (once; a few minutes)
#   ./demo.sh reset [ref]           fresh clone for the agent (default week-2-start)
#   ./demo.sh app [ref]             start PetClinic on localhost:8080 (default week-2-start)
#   ./demo.sh chrome                start Chrome with remote debugging, for the browser steps
#   ./demo.sh check                 preflight: token, image, clone, app, Chrome
#   ./demo.sh e7|e7b|e8|e9|e10|e11      a live run of that step, in the clone
#   ./demo.sh e11-shortcut          step 7(b): the shortcut, after ./demo.sh reset week-2-sensors
#   ./demo.sh show <step> [run]     what a run of a step did (default: the newest)
#   ./demo.sh apply <step> [run]    put the clone in the state that run left (default: the newest)
#   ./demo.sh stop                  stop PetClinic, the containers and the debugging Chrome
#   ./demo.sh help                  this list
#
# LADDER_BATCH=1 runs a step unattended with its prompt (stored runs, fallbacks).
# Each run is saved in <step folder>/runs/<date-time>-<model>/. The runs from class
# are kept in git; yours are ignored.
set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
skills="$(cd "$here/../skills" && pwd)"
W2_REMOTE="${W2_REMOTE:-https://github.com/qcon-he-course/he-petclinic.git}"
W2_WORK="${W2_WORK:-$HOME/.cache/qcon-he/week2}"
W2_APP_PORT="${W2_APP_PORT:-8080}"
W2_CHROME_PORT="${W2_CHROME_PORT:-9222}"
LADDER_MODEL="${LADDER_MODEL:-claude-opus-5-5}"
LADDER_TIME_CAP="${LADDER_TIME_CAP:-1200}"
export W2_WORK W2_APP_PORT W2_CHROME_PORT

usage() {  # the comment at the top of this file
  awk 'NR > 1 && /^#/ { sub(/^# ?/, ""); print; next } NR > 1 { exit }' "$0"
}

step_folder() {
  case "$1" in
    e7) echo e7-reproduce-the-bug ;;
    e7b) echo e7b-trace-the-slice ;;
    e8) echo e8-prove-the-bug ;;
    e9) echo e9-pin-what-exists ;;
    e10) echo e10-refactor-under-pins ;;
    e11|e11-shortcut) echo e11-fix-behind-the-sensor ;;
    *) return 1 ;;
  esac
}
step_layers() {
  case "$1" in
    e7) echo "w2-base w2-browser" ;;
    e7b) echo "w2-base w2-skills w2-archify" ;;
    e8|e9|e10) echo "w2-base w2-browser w2-skills" ;;
    e11|e11-shortcut) echo "w2-base w2-browser w2-skills w2-sensors" ;;
    *) return 1 ;;
  esac
}

clone() {  # clone <dest> <ref>
  rm -rf "$1"
  mkdir -p "$(dirname "$1")"
  git clone --quiet "$W2_REMOTE" "$1"
  git -C "$1" -c advice.detachedHead=false checkout --quiet "$2"
  # e7b's diagrams live in .harness/; keep them out of git status and every diff.
  echo ".harness/" >> "$1/.git/info/exclude"
}

latest_run() {  # latest_run <step>: the newest run folder of that step
  local folder pattern=("!" -name "*-shortcut")
  folder="$(step_folder "$1")" || return 1
  [ "$1" = e11-shortcut ] && pattern=(-name "*-shortcut")
  find "$here/$folder/runs" -mindepth 1 -maxdepth 1 -type d "${pattern[@]}" 2> /dev/null | sort | tail -1
}

snapshot() {  # snapshot <clone>: the diff against the checked-out commit, new files included
  git -C "$1" add --intent-to-add --all
  git -C "$1" diff
  git -C "$1" reset --quiet
}

summary() {  # summary <run folder>
  python3 - "$1" <<'PY'
import json, os, sys
run = sys.argv[1]
path = os.path.join(run, "transcript.jsonl")
if not os.path.exists(path):
    print("show: no transcript in this run")
    sys.exit(0)
steps, final, last_text, fired = [], "", "", 0
for line in open(path, encoding="utf-8"):
    if "Architecture check failed" in line:
        fired += 1
    try:
        ev = json.loads(line)
    except ValueError:
        continue
    if ev.get("type") == "assistant":
        for c in ev["message"].get("content", []):
            if c.get("type") != "tool_use":
                continue
            n, i = c["name"], c.get("input", {})
            if n == "Skill":
                steps.append("skill   " + str(i.get("skill") or i.get("command")))
            elif n in ("Edit", "Write", "MultiEdit"):
                steps.append("edit    " + i.get("file_path", "").split("/work/")[-1])
            elif n == "Bash":
                steps.append("shell   " + i.get("command", "").replace("\n", " ")[:110])
            elif n.startswith("mcp__"):
                steps.append("browser " + n.split("__")[-1])
        texts = [c.get("text", "") for c in ev["message"].get("content", []) if c.get("type") == "text"]
        if any(t.strip() for t in texts):
            last_text = "\n".join(texts)
    if ev.get("type") == "result":
        final = ev.get("result", "")
for k, s in enumerate(steps, 1):
    print(f"{k:3d} {s}")
print(f"\nsensor messages seen: {fired}")
print("\n--- final answer ---\n" + (final or last_text))
PY
}

cmd="${1:-}"
case "$cmd" in
  build)
    cd "$here" && docker compose build session
    ;;

  reset)
    ref="${2:-week-2-start}"
    clone "$W2_WORK/petclinic" "$ref"
    echo "demo: the agent's clone is $W2_WORK/petclinic, at $ref ($(git -C "$W2_WORK/petclinic" rev-parse --short HEAD))"
    ;;

  app)
    ref="${2:-week-2-start}"
    cd "$here"
    docker compose stop app > /dev/null 2>&1 || true
    clone "$W2_WORK/app" "$ref"
    docker compose up -d app
    printf 'demo: starting PetClinic at %s on http://localhost:%s ' "$ref" "$W2_APP_PORT"
    for _ in $(seq 1 90); do
      if curl -fs -o /dev/null "http://localhost:$W2_APP_PORT/"; then echo "up"; exit 0; fi
      printf '.'; sleep 2
    done
    echo; echo "demo: not up after 3 minutes; see: docker compose logs app" >&2; exit 1
    ;;

  chrome)
    profile="$HOME/.cache/qcon-he/week2-chrome"
    mkdir -p "$profile"
    if [ "$(uname)" = Darwin ]; then
      open -na "Google Chrome" --args --remote-debugging-port="$W2_CHROME_PORT" \
        --user-data-dir="$profile" --no-first-run --no-default-browser-check "http://localhost:$W2_APP_PORT/"
    else
      "${CHROME:-chromium}" --remote-debugging-port="$W2_CHROME_PORT" --remote-debugging-address=0.0.0.0 \
        --user-data-dir="$profile" --no-first-run --no-default-browser-check "http://localhost:$W2_APP_PORT/" \
        > /dev/null 2>&1 &
    fi
    echo "demo: Chrome with remote debugging on port $W2_CHROME_PORT, profile $profile"
    ;;

  check)
    ok=1
    item() {  # item <label> <message if ok> <message if not> <command...>
      local label="$1" yes="$2" no="$3"; shift 3
      if "$@" > /dev/null 2>&1; then echo "$label $yes"; else echo "$label $no"; ok=0; fi
    }
    item "token  " "set" "CLAUDE_CODE_OAUTH_TOKEN is not set" test -n "${CLAUDE_CODE_OAUTH_TOKEN:-}"
    item "image  " "he-week2" "missing: ./demo.sh build" docker image inspect he-week2
    if [ -d "$W2_WORK/petclinic/.git" ]; then
      echo "clone   $(git -C "$W2_WORK/petclinic" log --oneline -1), $(git -C "$W2_WORK/petclinic" status --porcelain | wc -l | tr -d ' ') changed files"
    else
      echo "clone   missing: ./demo.sh reset"; ok=0
    fi
    item "app    " "up on localhost:$W2_APP_PORT" "down: ./demo.sh app" curl -fs "http://localhost:$W2_APP_PORT/"
    item "chrome " "remote debugging on port $W2_CHROME_PORT" "not reachable: ./demo.sh chrome" curl -fs "http://localhost:$W2_CHROME_PORT/json/version"
    if [ "$ok" = 1 ]; then echo "demo: ready"; else echo "demo: not ready"; exit 1; fi
    ;;

  stop)
    # Everything the demo started: PetClinic, any session container left behind,
    # the compose network, and the debugging Chrome (only the instance using its own
    # profile). The clones, the Maven cache volume and the stored runs are kept.
    cd "$here" && docker compose down --remove-orphans
    if pkill -f "user-data-dir=$HOME/.cache/qcon-he/week2-chrome" 2> /dev/null; then
      echo "demo: debugging Chrome closed"
    fi
    echo "demo: stopped. The clone, the Maven cache and the stored runs are kept; ./demo.sh reset starts over."
    ;;

  show)
    step_folder "${2:-}" > /dev/null || { echo "usage: ./demo.sh show e7|e7b|e8|e9|e10|e11|e11-shortcut [run]" >&2; exit 1; }
    latest="$(latest_run "$2")"
    [ -n "${3:-}" ] && latest="$here/$(step_folder "$2")/runs/$3"
    [ -n "$latest" ] && [ -d "$latest" ] || { echo "show: no run of ${2}${3:+ named $3}" >&2; exit 1; }
    echo "show: $latest"
    summary "$latest"
    [ -s "$latest/diff.patch" ] && { echo; echo "--- files changed ---"; git apply --stat "$latest/diff.patch" 2> /dev/null || true; }
    if [ -f "$latest/diagrams/edit-request.html" ]; then
      echo "show: diagram at $latest/diagrams/edit-request.html"
      opener="$(command -v open || command -v xdg-open || true)"
      [ -n "$opener" ] && "$opener" "$latest/diagrams/edit-request.html"
    fi
    ;;

  apply)
    step_folder "${2:-}" > /dev/null || { echo "usage: ./demo.sh apply e7|e7b|e8|e9|e10|e11|e11-shortcut [run]" >&2; exit 1; }
    latest="$(latest_run "$2")"
    [ -n "${3:-}" ] && latest="$here/$(step_folder "$2")/runs/$3"
    [ -n "$latest" ] && [ -f "$latest/diff.patch" ] || { echo "apply: no stored run of $2" >&2; exit 1; }
    work="$W2_WORK/petclinic"
    [ -d "$work/.git" ] || { echo "apply: no clone; run ./demo.sh reset first" >&2; exit 1; }
    commit="$(cut -d' ' -f1 "$latest/start-commit.txt")"
    echo "apply: the clone's own changes are replaced by the state after $(basename "$latest")"
    git -C "$work" checkout --quiet -- .
    git -C "$work" clean -fdq
    git -C "$work" -c advice.detachedHead=false checkout --quiet "$commit"
    git -C "$work" apply --whitespace=nowarn "$latest/diff.patch"
    echo "apply: clone at $(git -C "$work" log --oneline -1), $(git -C "$work" status --porcelain | wc -l | tr -d ' ') changed files"
    ;;

  e7|e7b|e8|e9|e10|e11|e11-shortcut)
    folder="$(step_folder "$cmd")"
    layers="$(step_layers "$cmd")"
    work="$W2_WORK/petclinic"
    [ -d "$work/.git" ] || { echo "demo: no clone; run ./demo.sh reset first" >&2; exit 1; }
    stamp="$(date +%Y%m%d-%H%M%S)-$LADDER_MODEL"
    [ "$cmd" = e11-shortcut ] && stamp="$stamp-shortcut"
    run="$here/$folder/runs/$stamp"
    mkdir -p "$run/config" "$run/layers"
    # Skip Claude Code's first-launch setup; the trust prompt still appears.
    echo '{"hasCompletedOnboarding": true}' > "$run/config/.claude.json"
    for l in $layers; do
      cp -R "$here/layers/$l" "$run/layers/$l"
    done
    if [ -d "$run/layers/w2-skills" ]; then
      rm -f "$run/layers/w2-skills/README.md"
      mkdir -p "$run/layers/w2-skills/skills"
      cp -R "$skills/." "$run/layers/w2-skills/skills/"
    fi
    chmod 0755 "$run"/layers/*/*.sh 2> /dev/null || true
    prompt="$(cat "$here/prompts/$cmd.txt")"
    printf '%s\n' "$prompt" > "$run/prompt.txt"
    git -C "$work" log --oneline -1 > "$run/start-commit.txt"
    snapshot "$work" > "$run/start-diff.patch"
    if command -v pbcopy > /dev/null; then printf '%s' "$prompt" | pbcopy; echo "demo: the prompt is on the clipboard"
    else echo "demo: the prompt is in $run/prompt.txt"; fi
    echo "demo: $cmd ($folder), layers: $layers, model $LADDER_MODEL"
    echo "demo: clone at $(cat "$run/start-commit.txt"), $(git -C "$work" status --porcelain | wc -l | tr -d ' ') changed files"

    # e7b draws its diagram under .harness/diagrams in the clone: start each e7b run without an old one.
    diagrams="$work/.harness/diagrams"
    [ "$cmd" = e7b ] && rm -rf "$diagrams"

    export LADDER_CONFIG="$run/config" LADDER_LAYERS="$layers" LADDER_LAYERS_DIR="$run/layers" LADDER_RECORD="$run"
    cd "$here"
    docker compose build -q session
    if [ "${LADDER_BATCH:-}" = 1 ]; then
      container="he-week2-run-$stamp"
      docker compose run --rm -T --name "$container" session \
        claude -p "$prompt" --model "$LADDER_MODEL" --permission-mode dontAsk \
          --output-format stream-json --verbose \
        < /dev/null > "$run/transcript.jsonl" 2> "$run/stderr.txt" &
      agent=$!
      ( sleep "$LADDER_TIME_CAP"; echo "stopped at the time cap, $LADDER_TIME_CAP s" > "$run/timed-out.txt"; docker stop "$container" ) > /dev/null 2>&1 &
      watchdog=$!
      wait "$agent" || echo "demo: claude exited with an error, see $run/stderr.txt" >&2
      kill "$watchdog" 2> /dev/null || true
      wait "$watchdog" 2> /dev/null || true
      summary "$run" > "$run/summary.txt"
    else
      if [ -f "$here/$folder/cue.md" ]; then
        echo; sed 's/^/  | /' "$here/$folder/cue.md"; echo
      fi
      echo "demo: paste the prompt when Claude Code is ready"
      # e7b: open the diagram in your browser as soon as the agent has written it.
      watcher=""
      opener="$(command -v open || command -v xdg-open || true)"
      if [ "$cmd" = e7b ] && [ -n "$opener" ]; then
        ( until [ -s "$diagrams/edit-request.html" ]; do sleep 2; done; sleep 1; "$opener" "$diagrams/edit-request.html" ) &
        watcher=$!
        # If the demo is interrupted, don't leave the watcher behind to open a page later.
        trap 'kill "$watcher" 2> /dev/null || true' EXIT
      fi
      docker compose run --rm session claude --model "$LADDER_MODEL" || true
      [ -n "$watcher" ] && { kill "$watcher" 2> /dev/null || true; }
      # Keep the session where show can read it.
      session="$(ls "$run"/config/projects/-work/*.jsonl 2> /dev/null | head -1 || true)"
      [ -n "$session" ] && cp "$session" "$run/transcript.jsonl"
    fi
    snapshot "$work" > "$run/diff.patch"
    git -C "$work" status --porcelain --untracked-files=all > "$run/end-status.txt"
    if [ "$cmd" = e7b ] && [ -d "$diagrams" ]; then cp -R "$diagrams" "$run/diagrams"; fi
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
