#!/usr/bin/env bash
# Step 8's runs (e22). For each case: the clone at step 8's base (./demo.sh apply e21),
# the case's flaw, the sensors (e18), Opus three times and Codex once (e19), each run in
# runs/<case>/ so the class runs stay untouched (W3_RUNS_ROOT). Then the score.
#
#   ./run.sh [case...]          default: clean F1 F2 F3 F4 F5 F6
#   E22_OPUS_RUNS=3 E22_CODEX_RUNS=1 ./run.sh F6
#
# A case whose folder already holds runs is skipped, so an interrupted set can be
# resumed; delete runs/<case>/ to redo it. Codex needs CODEX_API_KEY in this shell.
# At the end the clone is put back at the base. About 20 minutes and $6 a case.
set -uo pipefail
count() { local i=1; while [ "$i" -le "$1" ]; do echo "$i"; i=$((i + 1)); done; }  # 1..n; none for 0 (BSD seq 1 0 counts down)
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exp="$(dirname "$here")"
W3_WORK="${W3_WORK:-$HOME/.cache/qcon-he/week3}"
export W3_WORK
opus="${E22_OPUS_RUNS:-3}"
codex="${E22_CODEX_RUNS:-1}"
cases=("$@")
[ "${#cases[@]}" -gt 0 ] || cases=(clean F1 F2 F3 F4 F5 F6)
if [ "$codex" != 0 ] && [ -z "${CODEX_API_KEY:-}" ]; then
  echo "e22: set CODEX_API_KEY for the Codex runs, or E22_CODEX_RUNS=0" >&2; exit 1
fi
cd "$exp"
for c in "${cases[@]}"; do
  root="$here/runs/$c"
  if [ "$c" != clean ] && [ ! -f "$here/cases/$c.patch" ]; then echo "e22: no case $c" >&2; continue; fi
  if [ -d "$root" ] && [ -n "$(ls -A "$root" 2> /dev/null)" ]; then echo "e22: $c already has runs; skipped"; continue; fi
  echo "e22: case $c"
  ./demo.sh apply e21 || exit 1
  if [ "$c" != clean ]; then
    git -C "$W3_WORK/petclinic" apply --whitespace=nowarn "$here/cases/$c.patch" || { echo "e22: $c does not apply" >&2; exit 1; }
  fi
  mkdir -p "$root"
  W3_RUNS_ROOT="$root" ./demo.sh e18 > "$root/e18.out" 2>&1 || echo "e22: e18 for $c exited with an error" >&2
  for i in $(count "$opus"); do
    W3_RUNS_ROOT="$root" LADDER_BATCH=1 ./demo.sh e19 > "$root/e19-opus-$i.out" 2>&1 || echo "e22: Opus run $i for $c exited with an error" >&2
  done
  for i in $(count "$codex"); do
    W3_RUNS_ROOT="$root" LADDER_BATCH=1 LADDER_AGENT=codex ./demo.sh e19 > "$root/e19-codex-$i.out" 2>&1 || echo "e22: Codex run $i for $c exited with an error" >&2
  done
done
./demo.sh apply e21
python3 "$here/score.py" "$here"
