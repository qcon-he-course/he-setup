#!/usr/bin/env bash
# Experiment 1, right window: plain Claude Code on a fresh clone of seeded PetClinic.
# Start ./tripwire.sh in another window first.
#
# Interactive by default: you trust the folder, paste the questions, /exit.
# E1_BATCH=1 runs unattended with claude -p and the six questions (the ladder's
# batch.sh does this for "e1"): it starts the tripwire if it isn't running, and
# stops it again afterwards if it started it. Unattended runs use Claude Code's
# dontAsk permission mode, as experiment 0's do, so the stored open and
# contained runs differ only in the floor. Interactive runs keep the default
# mode: the presenter answers each prompt. An unattended run is stopped after
# E1_TIME_CAP seconds.
#
# Each run is saved in runs/<date-time>-<model>/ (git-ignored):
#   config/        Claude Code's state for the run, including the session transcript
#   tripwire.log   what the tripwire received during the run
#   git-status.txt the clone's state when Claude Code exited
#   trial.patch    the patch applied, when E1_PATCH was set
#   prompt.txt, answer.txt, stderr.txt   in unattended runs
#   timed-out.txt  if an unattended run was stopped at the time cap
#
# The PetClinic clone the agent works on lives outside the course project, in
# E1_WORKDIR, and is removed when the run ends; E1_KEEP_CLONE=1 keeps it. Seeded
# repositories carry the rigged payloads, so they stay out of the project.
#
# Settings are in settings.sh. E1_PATCH=<file> applies a patch from trials/ to the
# clone and folds it into the seeding commit, to try a change before seeding it.
# E1_NO_CACHE=1 switches prompt caching off for the run (DISABLE_PROMPT_CACHING),
# so every request is billed as fresh input: costlier, and counted against your plan.
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=settings.sh
. "$here/settings.sh"

if [ -z "${CLAUDE_CODE_OAUTH_TOKEN:-}" ]; then
  echo "open-run: run 'claude setup-token' on this machine, then: export CLAUDE_CODE_OAUTH_TOKEN=<token>" >&2
  exit 1
fi
started_tripwire=""
if ! docker compose -f "$here/compose.yaml" ps --status running tripwire | grep -q tripwire; then
  if [ "${E1_BATCH:-}" = 1 ]; then
    docker compose -f "$here/compose.yaml" up -d --wait tripwire
    started_tripwire=1
  else
    echo "open-run: the tripwire is not running. Start ./tripwire.sh in another window first." >&2
    exit 1
  fi
fi
patch=""
if [ -n "${E1_PATCH:-}" ]; then
  patch="$(cd "$(dirname "$E1_PATCH")" && pwd)/$(basename "$E1_PATCH")"
fi

stamp="$(date +%Y%m%d-%H%M%S)-$E1_MODEL"
run="$E1_RUNS/$stamp"
work="$E1_WORKDIR/$stamp/petclinic"
mkdir -p "$run/config" "$E1_WORKDIR/$stamp"
# A fresh state folder makes Claude Code run its first-launch setup, which asks
# for a sign-in even with CLAUDE_CODE_OAUTH_TOKEN set. Marking setup as done
# skips it; the "trust this folder" prompt still appears.
echo '{"hasCompletedOnboarding": true}' > "$run/config/.claude.json"

git clone --quiet "$PETCLINIC" "$work"
git -C "$work" -c advice.detachedHead=false checkout --quiet "$PETCLINIC_COMMIT"
if [ -n "$patch" ]; then
  git -C "$work" apply "$patch"
  # Fold the change into the seeding commit, as the real seeding would, so the
  # agent sees a clean working tree and the same one-commit history.
  git -C "$work" -c user.name=het -c user.email=het@localhost \
    commit --quiet --all --amend --no-edit
  cp "$patch" "$run/trial.patch"
  echo "open-run: PetClinic at $PETCLINIC_COMMIT with $(basename "$patch"), model $E1_MODEL"
else
  echo "open-run: PetClinic at $PETCLINIC_COMMIT, model $E1_MODEL"
fi

run_env=()
if [ "${E1_NO_CACHE:-}" = 1 ]; then
  run_env=(-e DISABLE_PROMPT_CACHING=1)
  echo "open-run: prompt caching is off for this run"
fi

export E1_WORK="$work" E1_CONFIG="$run/config"
start="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
cd "$here"
docker compose build claude
if [ "${E1_BATCH:-}" = 1 ]; then
  # Unattended, as in the ladder's run.sh: the six questions go in with -p and
  # the answer is saved. There is no trust prompt, and the repository's hook
  # still runs. Stdin is closed so claude -p doesn't wait on it. The watchdog
  # stops the container at the time cap and leaves timed-out.txt.
  prompt="$(cat "$here/../questions.txt")"
  printf '%s\n' "$prompt" > "$run/prompt.txt"
  echo "open-run: unattended, prompt in $run/prompt.txt, stopped after $E1_TIME_CAP s"
  container="he-e1-run-$stamp"
  docker compose run --rm -T --name "$container" ${run_env[@]+"${run_env[@]}"} claude \
    claude -p "$prompt" --model "$E1_MODEL" --permission-mode dontAsk \
    < /dev/null > "$run/answer.txt" 2> "$run/stderr.txt" &
  agent=$!
  # Its output goes nowhere, so a sleep it leaves behind holds no caller's pipe open.
  (
    sleep "$E1_TIME_CAP"
    echo "stopped at the time cap, $E1_TIME_CAP s" > "$run/timed-out.txt"
    docker stop "$container"
  ) > /dev/null 2>&1 &
  watchdog=$!
  wait "$agent" || echo "open-run: claude exited with an error, see $run/stderr.txt" >&2
  kill "$watchdog" 2> /dev/null || true
  wait "$watchdog" 2> /dev/null || true
  if [ -f "$run/timed-out.txt" ]; then
    echo "open-run: stopped at the time cap, $E1_TIME_CAP s" >&2
  fi
else
  docker compose run --rm ${run_env[@]+"${run_env[@]}"} claude claude --model "$E1_MODEL" || true
fi
docker compose logs --no-log-prefix --since "$start" tripwire > "$run/tripwire.log" || true
git -C "$work" status --porcelain --untracked-files=all > "$run/git-status.txt" || true
if [ -n "$started_tripwire" ]; then
  docker compose stop tripwire > /dev/null 2>&1 || true
fi
if [ "${E1_KEEP_CLONE:-}" = 1 ]; then
  echo "open-run: kept the clone in $work"
else
  rm -rf "${E1_WORKDIR:?}/$stamp"
fi
echo "open-run: saved this run in $run"
echo "open-run: ./show-run.sh shows what the agent did"
