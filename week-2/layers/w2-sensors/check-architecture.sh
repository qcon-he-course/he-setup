#!/usr/bin/env bash
# Runs the architecture rules after an agent edits production code.
# Wired as a Claude Code hook in the w2-sensors layer, which demo.sh loads
# into Claude Code's managed settings for e11.
# Exit 2 sends the message on stderr back to the agent.
set -u
input=$(cat)
event=$(printf '%s' "$input" | python3 -c 'import json,sys; print(json.load(sys.stdin).get("hook_event_name",""))')
active=$(printf '%s' "$input" | python3 -c 'import json,sys; print(json.load(sys.stdin).get("stop_hook_active", False))')
cd "${CLAUDE_PROJECT_DIR:-.}" || exit 0

if [ "$event" = "PostToolUse" ]; then
  path=$(printf '%s' "$input" | python3 -c 'import json,sys; print(json.load(sys.stdin).get("tool_input",{}).get("file_path",""))')
  case "$path" in
    */src/main/java/*.java) ;;
    *) exit 0 ;;
  esac
fi

if [ "$event" = "Stop" ] && git diff --quiet -- src/main && [ -z "$(git ls-files --others --exclude-standard src/main)" ]; then
  exit 0
fi

if out=$(./mvnw -B -q test -Dtest=ArchitectureTests -Dsurefire.failIfNoSpecifiedTests=false \
      -Dspring-javaformat.skip=true -Dcheckstyle.skip=true 2>&1); then
  exit 0
fi

# A compile error between two edits of one change is not the rule's business.
# Stay quiet after an edit; the Stop hook still reports it if it is still there.
if [ "$event" = "PostToolUse" ] && printf '%s' "$out" | grep -q 'COMPILATION ERROR'; then
  exit 0
fi

message=$(printf '%s\n' "$out" | python3 -c '
import re, sys
text = sys.stdin.read()
because = re.search(r"because (.*?)\x27 was violated", text)
lines = sorted({re.sub(r"\b(?:[a-z_]+\.)+([A-Z])", r"\1", l.strip())
                for l in text.splitlines() if l.startswith(("Method <", "Constructor <"))})
if not lines:
    sys.exit(1)
print("Architecture check failed: controllers must not call rejectValue.")
if because:
    print("Why: " + because.group(1) + ".")
print("New violations:")
print("\n".join("  " + l for l in lines))
print("Fix the production code. Do not edit ArchitectureTests, archunit.properties or src/test/resources/archunit_store.")
')
if [ -z "$message" ]; then
  message=$(printf 'The architecture check did not run cleanly:\n%s' "$(printf '%s\n' "$out" | grep -E 'ERROR' | head -5)")
fi

# Stop, after this hook already blocked once: let the agent stop, and tell the person.
# Exit 1 is a non-blocking error: Claude Code shows it to the user, not the agent.
if [ "$active" = "True" ]; then
  printf '%s\n' "$message" >&2
  exit 1
fi
printf '%s\n' "$message" >&2
exit 2
