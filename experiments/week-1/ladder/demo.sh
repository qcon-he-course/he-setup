#!/usr/bin/env bash
# The live demo of an experiment, for the presenter: a preflight, the
# interactive run on the live model (LADDER_MODEL), then this run beside the
# stored runs. The live run isn't graded; the comparison is counts only.
#
#   ./demo.sh e0              the live run
#   ./demo.sh e1              experiment 1's open run; ./tripwire.sh runs in the other window
#   ./demo.sh e2              a ladder rung, shown beside the rung below's stored runs and its own
#   ./demo.sh e3              the same, against e2; e4 against e3; e5 against e4
#   ./demo.sh e6              experiment 6: no stored runs; opens the journey diagram and the stored component view
#   ./demo.sh e0 --fallback   the stored run nearest the median, in summary
#                             and with its answers, when the live run fails
#
# Each experiment's README, section 3, is the agreed script of its demo.
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=settings.sh
. "$here/settings.sh"
e1="$EXPERIMENTS/e1-limit-what-it-can-do"

exp="${1:-}"; option="${2:-}"
case "$exp:$option" in
  e0:|e0:--fallback|e1:|e1:--fallback|e2:|e2:--fallback|e3:|e3:--fallback|e4:|e4:--fallback|e5:|e5:--fallback|e6:) ;;
  *) echo "usage: ./demo.sh e0|e1|e2|e3|e4|e5 [--fallback], or ./demo.sh e6" >&2; exit 1 ;;
esac
e6="$EXPERIMENTS/e6-build-your-mental-model"

if [ "$option" = --fallback ]; then
  run="$("$here/scoreboard.sh" --nearest "$LADDER_MODEL" "$exp")"
  echo "demo: the stored $LADDER_MODEL run nearest the median"
  echo
  "$here/show-run.sh" "$run"
  echo
  "$here/show-run.sh" "$run" --answers
  exit 0
fi

failed=0
ok() { echo "demo: ok    $1"; }
bad() { echo "demo: FAIL  $1" >&2; failed=1; }
if [ -n "${CLAUDE_CODE_OAUTH_TOKEN:-}" ]; then ok "CLAUDE_CODE_OAUTH_TOKEN is exported"; else bad "export CLAUDE_CODE_OAUTH_TOKEN in this window"; fi
if docker info > /dev/null 2>&1; then ok "Docker is running"; else bad "start Docker"; fi
if [ "$exp" = e1 ]; then
  if docker image inspect he-e1-open-run > /dev/null 2>&1; then ok "the he-e1-open-run image is built"; else bad "build it: (cd $e1 && docker compose build claude)"; fi
  if docker compose -f "$e1/compose.yaml" ps --status running tripwire | grep -q tripwire; then
    ok "the tripwire is running"
  else
    bad "start ./tripwire.sh in the other window, from $e1"
  fi
else
  if docker image inspect he-ladder > /dev/null 2>&1; then ok "the he-ladder image is built"; else bad "build it: docker compose build session"; fi
  if [ "$exp" = e5 ] || [ "$exp" = e6 ]; then
    if [ -s "$EXPERIMENTS/e5-require-evidence/AGENTS.md" ]; then ok "the curated AGENTS.md is in place"; else bad "no e5-require-evidence/AGENTS.md"; fi
  fi
  if [ "$exp" = e6 ]; then
    if [ -f "$e6/codeboarding/analysis.json" ]; then ok "CodeBoarding's output is in place"; else bad "run ./codeboarding.sh once"; fi
  fi
fi
if [ "$exp" = e6 ]; then
  # Experiment 6 has no stored runs and its prompt is typed: /trace-journey an owner adds a new pet
  ok "experiment 6: type /trace-journey an owner adds a new pet"
elif pbcopy < "$EXPERIMENTS/questions.txt"; then ok "the six questions are on the clipboard"; else bad "pbcopy < ../questions.txt"; fi
if [ "$exp" = e6 ]; then
  :
elif [ -n "$("$here/scoreboard.sh" "$LADDER_MODEL" "$exp" --runs | sed -n '3p')" ]; then
  ok "stored $LADDER_MODEL runs exist for the comparison and the fallback"
else
  echo "demo: note  no stored $LADDER_MODEL runs for $exp yet: nothing to compare with, no fallback"
fi
[ "$failed" = 0 ] || exit 1

# The cue card is section 3 of the experiment's README, on a second screen or
# on paper: Claude Code takes over this terminal, and the room sees it.
read -r -p "demo: press Enter to start the run " _

if [ "$exp" = e1 ]; then
  E1_MODEL="$LADDER_MODEL" "$e1/open-run.sh"
  echo
  echo "demo: this run"
  echo
  "$e1/show-run.sh"
  echo
  echo "demo: the stored runs, contained (e0) beside open (e1)"
  echo
  "$here/scoreboard.sh" --rigged e0 e1
  echo
  "$here/scoreboard.sh" e0 e1
elif [ "$exp" = e6 ]; then
  "$here/run.sh" e6
  echo
  echo "demo: this run"
  echo
  "$here/show-run.sh" e6
  # The diagrams reach the run folder only after Claude Code exits. Run
  # folders sort by date and time, so the last one is this run.
  runs=("$e6"/runs/*/)
  run="${runs[${#runs[@]}-1]%/}"
  # The component view comes from the /arch-map run made before class: the newest
  # one. It opens first, so the browser shows the journey on top.
  architecture=""
  for f in "$e6"/runs/*/files/.harness/diagrams/architecture.html; do
    [ -f "$f" ] && architecture="$f"
  done
  if [ -n "$architecture" ]; then
    echo; echo "demo: the stored component view, opening: $architecture"; open "$architecture"
  else
    echo; echo "demo: no stored component view yet: run /arch-map once before class" >&2
  fi
  journeys=("$run"/files/.harness/diagrams/journey-*.html)
  if [ -f "${journeys[0]}" ]; then
    echo "demo: the journey diagram, opening: ${journeys[0]}"; open "${journeys[0]}"
  else
    echo "demo: no journey diagram in $run/files/.harness/diagrams/" >&2
  fi
else
  "$here/run.sh" "$exp"
  echo
  echo "demo: this run"
  echo
  "$here/show-run.sh" "$exp"
  # A rung is shown beside the rung it is measured against: e2 against e0, then each against the one below.
  case "$exp" in
    e0) rungs=(e0) ;;
    e2) rungs=(e0 e2) ;;
    e3) rungs=(e2 e3) ;;
    e4) rungs=(e3 e4) ;;
    e5) rungs=(e4 e5) ;;
  esac
  echo
  echo "demo: stored runs, medians for ${rungs[*]}"
  echo
  "$here/scoreboard.sh" "${rungs[@]}"
fi
