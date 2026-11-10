#!/usr/bin/env bash
# Week 3 sensor probe: does the frozen ArchUnit rule catch a new rejectValue call
# in a PetController method that already has frozen calls?
#
# The harness runs this before a review (demo.sh e15), on a throwaway copy of the
# clone, and gives the result to the reviewer as evidence. The clone itself is
# never changed. Output is Markdown on stdout; progress goes to stderr.
#
#   bash freeze-probe.sh [clone]      default /work
set -uo pipefail

src="${1:-/work}"
copy="$(mktemp -d)/probe"
controller="src/main/java/org/springframework/samples/petclinic/owner/PetController.java"

log() { echo "probe: $*" >&2; }

run_rule() {  # run_rule <dir>: prints PASS or FAIL, and the rule's message on failure
  local out status
  out="$(cd "$1" && ./mvnw -q test -Dtest=ArchitectureTests 2>&1)"
  status=$?
  if [ "$status" = 0 ]; then
    echo PASS
  else
    echo FAIL
    printf '%s\n' "$out" | grep -E "^(Architecture Violation|Method <)" | awk '!seen[$0]++' | head -6 | sed 's/^/    /'
  fi
}

log "copying $src (without target/)"
mkdir -p "$copy"
( cd "$src" && tar --exclude=./target -cf - . ) | ( cd "$copy" && tar -xf - )

log "control: ArchitectureTests on the copy as it is"
control="$(run_rule "$copy")"

log "probe: one more rejectValue call in processCreationForm"
python3 - "$copy/$controller" <<'PY'
import re, sys
path = sys.argv[1]
src = open(path, encoding="utf-8").read()
start = src.index("public String processCreationForm(")
anchor = re.compile(r'^(\s*)result\.rejectValue\("name", "duplicate", "already exists"\);\n', re.M)
m = anchor.search(src, start)
if not m:
    sys.exit("probe: no frozen rejectValue call found in processCreationForm")
line = f'{m.group(1)}result.rejectValue("microchipNumber", "duplicate", "is already in use");\n'
open(path, "w", encoding="utf-8").write(src[:m.end()] + line + src[m.end():])
PY
probe="$(run_rule "$copy")"
rm -rf "$(dirname "$copy")"

cat <<EOF
## Probe: does the frozen architecture rule catch a new controller call?

The harness ran \`./mvnw -q test -Dtest=ArchitectureTests\` twice, on a copy of the clone that was then deleted.

| Run | What the copy held | Result |
|---|---|---|
| Control | The clone as it is | $(head -1 <<< "$control") |
| Probe | One added line in \`PetController.processCreationForm\`, after its first frozen call: \`result.rejectValue("microchipNumber", "duplicate", "is already in use");\` | $(head -1 <<< "$probe") |

EOF
if [ "$(tail -n +2 <<< "$probe")" != "" ]; then
  echo "The probe run's output:"
  echo
  echo '```'
  tail -n +2 <<< "$probe" | sed 's/^    //'
  echo '```'
  echo
fi
case "$(head -1 <<< "$control")/$(head -1 <<< "$probe")" in
  PASS/FAIL) echo "Reading: the rule passes today and fails when one call is added to a method that already has frozen calls. A new \`rejectValue\` call in the controller fails the build." ;;
  PASS/PASS) echo "Reading: the rule passes with the added call. The freeze store lets a new call through in a method that already has frozen calls." ;;
  *) echo "Reading: the control run did not pass, so the probe says nothing about the rule. Check the build first." ;;
esac
