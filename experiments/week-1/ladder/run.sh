#!/usr/bin/env bash
# One run of a rung of the ladder: plain Claude Code on a fresh clone of seeded
# PetClinic, with the layers of that experiment and every one below it.
#
#   ./run.sh e0      the naked agent: the floor only
#   ./run.sh e2      + the instruction file
#   ./run.sh e3      + Serena
#   ./run.sh e4      + the code graph (starts Memgraph)
#   ./run.sh init    experiment 5, step 1: /init in a bare session; keeps the draft
#   ./run.sh e5      + the evidence rule, and the audited AGENTS.md in the clone
#   ./run.sh e6      + the diagram skills, and CodeBoarding's output in the clone
#
# Interactive by default: you trust the folder, paste the questions, /exit.
# LADDER_BATCH=1 runs unattended with claude -p (batch.sh does this for you):
# the six questions for e0 to e5, /init for init, and /trace-journey for e6.
# Unattended runs use Claude Code's dontAsk permission mode, except init: a
# call that would ask for permission is refused. Interactive runs keep the
# default mode, as people run it: the presenter answers each prompt. An
# unattended run is stopped after LADDER_TIME_CAP seconds.
# LADDER_MODEL picks the model; the run folder's name ends with it.
#
# Each run is saved in <experiment folder>/runs/<date-time>/ (git-ignored):
#   config/           Claude Code's state, including the session transcript
#   etc-claude-code/  exactly what the layers put in /etc/claude-code
#   layers/           the layer folders as they were for this run
#   prepare.log       tool indexing before Claude Code started
#   files/            files the agent created or changed in the clone, and .harness/
#   git-status.txt    the clone's state when Claude Code exited
#   prompt.txt, answer.txt, stderr.txt   in unattended runs
#   timed-out.txt     if an unattended run was stopped at the time cap
#   score.txt         yours to write after marking: q1-5=<0..5> q6=<0..6>
#
# The clone lives in LADDER_WORKDIR, outside the course project, and is removed
# when the run ends; LADDER_KEEP_CLONE=1 keeps it. Settings are in settings.sh.
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=settings.sh
. "$here/settings.sh"

exp="${1:-}"
if ! folder="$(ladder_folder "$exp")"; then
  echo "usage: ./run.sh e0|e2|e3|e4|init|e5|e6" >&2
  exit 1
fi
layers="$(ladder_layers "$exp")"
exp_dir="$EXPERIMENTS/$folder"

if [ -z "${CLAUDE_CODE_OAUTH_TOKEN:-}" ] && [ -z "${LADDER_ANTHROPIC_API_KEY:-}" ]; then
  echo "run: run 'claude setup-token' on this machine, then: export CLAUDE_CODE_OAUTH_TOKEN=<token>" >&2
  echo "     (or export LADDER_ANTHROPIC_API_KEY=<a Claude Console API key>)" >&2
  exit 1
fi
case " $layers " in
  *" e5 "*)
    if [ ! -f "$EXPERIMENTS/e5-require-evidence/AGENTS.md" ]; then
      echo "run: $exp needs the audited AGENTS.md in e5-require-evidence/AGENTS.md." >&2
      echo "     Make the draft with ./run.sh init, audit it, and save the kept lines there." >&2
      exit 1
    fi ;;
esac
codeboarding="$EXPERIMENTS/e6-build-your-mental-model/codeboarding"
if [ "$exp" = e6 ] && [ ! -f "$codeboarding/analysis.json" ]; then
  echo "run: no CodeBoarding output in e6-build-your-mental-model/codeboarding/." >&2
  echo "     Run ./codeboarding.sh once first (it needs a provider API key), or LADDER_NO_CODEBOARDING=1 to go without." >&2
  [ "${LADDER_NO_CODEBOARDING:-}" = 1 ] || exit 1
fi

stamp="$(date +%Y%m%d-%H%M%S)-${LADDER_MODEL}"
[ "$exp" = init ] && stamp="$stamp-init"
run="$exp_dir/runs/$stamp"
work="$LADDER_WORKDIR/$stamp/petclinic"
mkdir -p "$run/config" "$run/layers" "$LADDER_WORKDIR/$stamp"
# Skip Claude Code's first-launch setup; the "trust this folder" prompt still appears.
echo '{"hasCompletedOnboarding": true}' > "$run/config/.claude.json"
for l in $layers; do
  cp -R "$EXPERIMENTS/$(ladder_folder "$l")/layer" "$run/layers/$l"
done

git clone --quiet "$PETCLINIC" "$work"
git -C "$work" -c advice.detachedHead=false checkout --quiet "$PETCLINIC_COMMIT"
case " $layers " in
  *" e5 "*)
    cp "$EXPERIMENTS/e5-require-evidence/AGENTS.md" "$work/AGENTS.md"
    cp "$EXPERIMENTS/e5-require-evidence/AGENTS.md" "$run/AGENTS.md"
    # Committed, as a team would commit it, so the clone's working tree stays clean.
    git -C "$work" add AGENTS.md
    git -C "$work" -c user.name="PetClinic team" -c user.email=team@petclinic.invalid \
      commit --quiet -m "Add AGENTS.md"
    ;;
esac
if [ "$exp" = e6 ] && [ -f "$codeboarding/analysis.json" ]; then
  mkdir -p "$work/.harness"
  cp -R "$codeboarding" "$work/.harness/codeboarding"
  echo ".harness/" >> "$work/.git/info/exclude"
fi

echo "run: $exp ($folder), PetClinic at $PETCLINIC_COMMIT, model $LADDER_MODEL"
echo "run: layers: ${layers:-none}"

export LADDER_WORK="$work" LADDER_CONFIG="$run/config" LADDER_LAYERS="$layers" \
       LADDER_LAYERS_DIR="$run/layers" LADDER_RECORD="$run"
cd "$here"
case " $layers " in
  *" e4 "*) docker compose up -d --wait memgraph >/dev/null ;;
esac
docker compose build -q session
# /init has to write CLAUDE.md, so it keeps the default mode and asks.
permissions=()
[ "$exp" = init ] || permissions=(--permission-mode dontAsk)
if [ "${LADDER_BATCH:-}" = 1 ]; then
  # Unattended: the prompt goes in with -p and the answer is saved. With -p
  # there is no trust prompt; read-only shell commands still run. Stdin is
  # closed so claude -p doesn't wait on it. The watchdog stops the container
  # at the time cap and leaves timed-out.txt.
  case "$exp" in
    init) prompt="/init" ;;
    e6) prompt="/trace-journey ${LADDER_JOURNEY:-an owner adds a new pet}" ;;
    *) prompt="$(cat "$EXPERIMENTS/questions.txt")" ;;
  esac
  printf '%s\n' "$prompt" > "$run/prompt.txt"
  echo "run: unattended, prompt in $run/prompt.txt, stopped after $LADDER_TIME_CAP s"
  container="he-ladder-run-$stamp"
  docker compose run --rm -T --name "$container" session \
    claude -p "$prompt" --model "$LADDER_MODEL" ${permissions[@]+"${permissions[@]}"} \
    < /dev/null > "$run/answer.txt" 2> "$run/stderr.txt" &
  agent=$!
  # Its output goes nowhere, so a sleep it leaves behind holds no caller's pipe open.
  (
    sleep "$LADDER_TIME_CAP"
    echo "stopped at the time cap, $LADDER_TIME_CAP s" > "$run/timed-out.txt"
    docker stop "$container"
  ) > /dev/null 2>&1 &
  watchdog=$!
  wait "$agent" || echo "run: claude exited with an error, see $run/stderr.txt" >&2
  kill "$watchdog" 2> /dev/null || true
  wait "$watchdog" 2> /dev/null || true
  if [ -f "$run/timed-out.txt" ]; then
    echo "run: stopped at the time cap, $LADDER_TIME_CAP s" >&2
  fi
else
  docker compose run --rm session claude --model "$LADDER_MODEL" || true
fi

# Keep what the agent wrote: /init's draft, diagrams, notes, anything else.
git -C "$work" status --porcelain --untracked-files=all > "$run/git-status.txt" || true
mkdir -p "$run/files"
while IFS= read -r line; do
  path="${line:3}"
  case "$line" in " D"*|"D "*) continue ;; esac
  [ -f "$work/$path" ] || continue
  mkdir -p "$run/files/$(dirname "$path")"
  cp "$work/$path" "$run/files/$path"
done < "$run/git-status.txt"
if [ -d "$work/.harness" ]; then
  mkdir -p "$run/files/.harness"
  for d in diagrams notes; do
    [ -d "$work/.harness/$d" ] && cp -R "$work/.harness/$d" "$run/files/.harness/"
  done
fi
[ -n "$(ls -A "$run/files")" ] || rmdir "$run/files"

if [ "${LADDER_KEEP_CLONE:-}" = 1 ]; then
  echo "run: kept the clone in $work"
else
  rm -rf "${LADDER_WORKDIR:?}/$stamp"
fi
echo "run: saved this run in $run"
if [ "$exp" = init ]; then
  echo "run: /init's draft, if it wrote one, is in $run/files/"
fi
echo "run: ./show-run.sh $exp shows what the agent did"
