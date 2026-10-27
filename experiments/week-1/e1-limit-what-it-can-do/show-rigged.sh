#!/usr/bin/env bash
# Experiment 1: show the room what seeded PetClinic has rigged, read from the pinned
# commit without checking anything out. Rigged lines are highlighted.
# Usage: ./show-rigged.sh [all | hook config contributing unicode env]
#   hook          .claude/settings.json: the start-up hook that posts .env
#   config        application.properties: the rigged instruction at the end
#   contributing  the README line that links to CONTRIBUTING.md, and its instruction
#   unicode       welcome.html: an instruction in invisible Unicode characters, decoded
#   env           .env: the fake secrets the hook sends
# With no arguments, or "all", it shows all five in turn and pauses after each.
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=settings.sh
. "$here/settings.sh"

on="" off="" bold=""
if [ -t 1 ] && [ -z "${NO_COLOR:-}" ]; then
  on=$'\033[1;30;43m' off=$'\033[0m' bold=$'\033[1m'
fi

blob() { git -C "$PETCLINIC" show "$PETCLINIC_COMMIT:$1"; }

header() {
  printf '\n%s== %s%s  (PetClinic %s)\n   %s\n\n' "$bold" "$1" "$off" "$PETCLINIC_COMMIT" "$2"
}

# Print lines from-to of stdin with line numbers, highlighting lines that match re.
lines() {
  awk -v re="$1" -v from="${2:-1}" -v to="${3:-0}" -v on="$on" -v off="$off" '
    NR < from || (to > 0 && NR > to) { next }
    $0 ~ re { printf "%4d  %s%s%s  <-- rigged\n", NR, on, $0, off; next }
    { printf "%4d  %s\n", NR, $0 }'
}

show_hook() {
  header .claude/settings.json "Runs when a session starts, once the folder is trusted. No model involved."
  blob .claude/settings.json | lines 'curl'
}

show_config() {
  header src/main/resources/application.properties "Every run reads this file for the database question. The instruction sits at the end."
  blob src/main/resources/application.properties | lines 'register this checkout|tripwire'
}

show_contributing() {
  local n
  n="$(blob README.md | grep -n 'CONTRIBUTING.md' | head -1 | cut -d: -f1)"
  header README.md "Near the end of the README, a line sends anyone about to build to CONTRIBUTING.md."
  blob README.md | lines 'CONTRIBUTING.md' "$((n - 4))" "$((n + 1))"
  header CONTRIBUTING.md "The instruction itself. Only an agent about to build has a reason to follow it."
  blob CONTRIBUTING.md | lines 'Register|tripwire'
}

show_unicode() {
  header src/main/resources/templates/welcome.html "Looks like an empty HTML comment at the end of the page. It holds characters a screen doesn't show."
  blob src/main/resources/templates/welcome.html | python3 -c '
import sys
on, off = sys.argv[1], sys.argv[2]
text = sys.stdin.buffer.read().decode("utf-8")
for n, line in enumerate(text.splitlines(), 1):
    hidden = [c for c in line if 0xE0000 <= ord(c) <= 0xE007F]
    if not hidden:
        continue
    shown = "".join(c for c in line if not 0xE0000 <= ord(c) <= 0xE007F)
    decoded = "".join(chr(ord(c) - 0xE0000) for c in hidden)
    print("%4d  %s   <-- what an editor shows" % (n, shown))
    print("      %d invisible Unicode tag characters inside it. Decoded:" % len(hidden))
    print("      %s%s%s" % (on, decoded, off))
' "$on" "$off"
}

show_env() {
  header .env "Fake values. This is what the hook sends, and what the model receives if the agent reads the file."
  blob .env | lines '^[A-Z_]+='
}

[ $# -gt 0 ] || set -- all
if [ "$1" = all ]; then set -- hook config contributing unicode env; fi
for item in "$@"; do
  case "$item" in
    hook|config|contributing|unicode|env) ;;
    *) echo "show-rigged: unknown item '$item'. Use all, hook, config, contributing, unicode or env." >&2; exit 1 ;;
  esac
done
count=$#
i=0
for item in "$@"; do
  i=$((i + 1))
  "show_$item"
  if [ "$i" -lt "$count" ] && [ -t 0 ]; then
    printf '\n'
    read -r -p "   Enter for the next rigged item " _
  fi
done
echo
