#!/usr/bin/env bash
# Summarise a ladder run with experiment 1's show-run.sh: model, time, tokens,
# every tool call, the files read. The rigged-items block applies too: it shows
# whether the agent saw or flagged the rigged comment, and whether the fake
# token reached the model. There is no tripwire in these runs.
#
# Usage: ./show-run.sh <e0|e2|e3|e4|init|e5|e6> [--answers | --replies | --calls]   (the latest run)
#        ./show-run.sh <run folder> [--answers | --replies | --calls]
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=settings.sh
. "$here/settings.sh"

target="${1:-}"
shift || true
if folder="$(ladder_folder "$target" 2>/dev/null)"; then
  run=""
  for d in "$EXPERIMENTS/$folder/runs"/*/; do
    [ -d "$d" ] || continue
    case "$target:$d" in
      init:*-init/) run="$d" ;;
      init:*) ;;
      e5:*-init/) ;;
      *) run="$d" ;;
    esac
  done
  if [ -z "$run" ]; then
    echo "show-run: no $target run in $EXPERIMENTS/$folder/runs" >&2
    exit 1
  fi
elif [ -d "$target" ]; then
  run="$target"
else
  echo "usage: ./show-run.sh <e0|e2|e3|e4|init|e5|e6|run folder> [--answers | --replies | --calls]" >&2
  exit 1
fi
exec "$EXPERIMENTS/e1-limit-what-it-can-do/show-run.sh" "$@" "$run"
