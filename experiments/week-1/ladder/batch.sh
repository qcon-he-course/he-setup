#!/usr/bin/env bash
# Stored runs, unattended: N rounds of the ladder on one model, one run after
# another. Each round runs every rung once, in ladder order, so a slow hour or
# a provider hiccup spreads across rungs instead of landing on one.
#
#   ./batch.sh claude-haiku-4-5 5                  e0 e2 e3 e4 e5 e6, five rounds
#   ./batch.sh claude-sonnet-5-5 5 e2 e3           only those rungs
#   ./batch.sh claude-opus-5-5 5 e1                experiment 1's open run, by its open-run.sh
#
# Needs CLAUDE_CODE_OAUTH_TOKEN (or LADDER_ANTHROPIC_API_KEY), the audited
# e5-require-evidence/AGENTS.md for e5 and e6, and CodeBoarding's output for e6.
# Runs land in each experiment's runs/ folder; ./scoreboard.sh summarises them.
# The log of the batch is in LADDER_WORKDIR/batch-<date-time>.log.
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=settings.sh
. "$here/settings.sh"

model="${1:-}"; rounds="${2:-}"
if [ -z "$model" ] || ! [[ "$rounds" =~ ^[0-9]+$ ]]; then
  echo "usage: ./batch.sh <model> <rounds> [e0 e1 e2 e3 e4 e5 e6]" >&2
  exit 1
fi
shift 2
rungs=("$@")
[ "${#rungs[@]}" -gt 0 ] || rungs=(e0 e2 e3 e4 e5 e6)

for r in "${rungs[@]}"; do
  [ "$r" = e1 ] && continue
  ladder_folder "$r" >/dev/null || { echo "batch: unknown rung $r" >&2; exit 1; }
  if [ "$r" = e5 ] || [ "$r" = e6 ]; then
    [ -f "$EXPERIMENTS/e5-require-evidence/AGENTS.md" ] || { echo "batch: $r needs e5-require-evidence/AGENTS.md (./run.sh init, then audit)" >&2; exit 1; }
  fi
  if [ "$r" = e6 ] && [ ! -f "$EXPERIMENTS/e6-build-your-mental-model/codeboarding/analysis.json" ]; then
    echo "batch: e6 needs CodeBoarding's output (./codeboarding.sh)" >&2; exit 1
  fi
done
if [ -z "${CLAUDE_CODE_OAUTH_TOKEN:-}" ] && [ -z "${LADDER_ANTHROPIC_API_KEY:-}" ]; then
  echo "batch: export CLAUDE_CODE_OAUTH_TOKEN first (claude setup-token)" >&2
  exit 1
fi

mkdir -p "$LADDER_WORKDIR"
log="$LADDER_WORKDIR/batch-$(date +%Y%m%d-%H%M%S).log"
total=$(( rounds * ${#rungs[@]} )); n=0; failed=0
echo "batch: $total runs on $model: ${rounds} rounds of ${rungs[*]}. Log: $log"
for ((i = 1; i <= rounds; i++)); do
  for r in "${rungs[@]}"; do
    n=$((n + 1))
    start=$SECONDS
    printf 'batch: [%d/%d] round %d, %s ... ' "$n" "$total" "$i" "$r"
    if [ "$r" = e1 ]; then
      one_run=(env E1_BATCH=1 E1_MODEL="$model" "$EXPERIMENTS/e1-limit-what-it-can-do/open-run.sh")
    else
      one_run=(env LADDER_BATCH=1 LADDER_MODEL="$model" "$here/run.sh" "$r")
    fi
    if "${one_run[@]}" >>"$log" 2>&1; then
      echo "done in $((SECONDS - start)) s"
    else
      failed=$((failed + 1))
      echo "FAILED after $((SECONDS - start)) s (see the log)"
    fi
  done
done
echo "batch: finished, $failed of $total failed. ./scoreboard.sh summarises the runs."
