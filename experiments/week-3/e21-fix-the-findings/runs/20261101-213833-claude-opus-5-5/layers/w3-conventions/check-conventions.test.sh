#!/usr/bin/env bash
# Tests for check-conventions.sh, with a stub mvnw. Run: ./check-conventions.test.sh
set -uo pipefail
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
t="$(mktemp -d)"; trap 'rm -rf "$t"' EXIT
fails=0
repo="$t/repo"; mkdir -p "$repo/src"; cd "$repo"
git init -q; git config user.email t@t; git config user.name t
echo a > src/A.java; git add .; git commit -qm start
cat > mvnw <<'STUB'
#!/usr/bin/env bash
case "$2" in
  validate) case "$SCENARIO" in pass) exit 0 ;; enforcer) echo "[ERROR] Rule 0: RequireJavaVersion failed with message:"; echo "[ERROR]"; echo "[ERROR] This build requires at least Java 99"; exit 1 ;; *) echo "[ERROR] Failed"; exit 1 ;; esac ;;
  spring-javaformat:validate) case "$SCENARIO" in format|both) echo "[ERROR] Formatting violations found in the following files:"; echo "[ERROR]  * $PWD/src/A.java"; exit 1 ;; esac; exit 0 ;;
  checkstyle:check@nohttp-checkstyle-validation) case "$SCENARIO" in url|both) echo "[ERROR] src/b.html:[3,5] (extension) NoHttp: http:// URLs are not allowed but got 'http://x.org'. Use https:// instead."; exit 1 ;; esac; exit 0 ;;
esac
exit 0
STUB
chmod +x mvnw; git add mvnw; git commit -qm stub
hook() { # hook <event> <stop_hook_active> <scenario>: prints the exit code; stderr to $t/err
  printf '{"hook_event_name": "%s", "stop_hook_active": %s}' "$1" "$2" |
    SCENARIO="$3" CLAUDE_PROJECT_DIR="$repo" bash "$here/check-conventions.sh" 2> "$t/err"; echo $?
}
expect() { # expect <name> <got exit> <want exit> <grep pattern on stderr or ->
  if [ "$2" != "$3" ]; then echo "FAIL $1: exit $2, wanted $3"; cat "$t/err"; fails=$((fails + 1)); return; fi
  if [ "$4" != - ] && ! grep -qE -- "$4" "$t/err"; then echo "FAIL $1: no match for $4"; cat "$t/err"; fails=$((fails + 1)); return; fi
  echo "ok   $1"
}
expect "no change: quiet" "$(hook Stop false both)" 0 -
echo b >> src/A.java
expect "after an edit (not Stop): quiet" "$(hook PostToolUse false both)" 0 -
expect "validate passes: quiet" "$(hook Stop false pass)" 0 -
expect "unformatted code goes back to the agent" "$(hook Stop false format)" 2 '^  Unformatted: src/A.java$'
expect "the message says what to do" "$(hook Stop false format)" 2 'What to do instead: run ./mvnw spring-javaformat:apply\.'
expect "an http URL goes back with file and line" "$(hook Stop false url)" 2 '^  http:// URL: src/b.html:3: http://x.org$'
expect "both problems in one message" "$(hook Stop false both)" 2 'run ./mvnw spring-javaformat:apply; change each http:// URL below to https://'
expect "the message says what not to do" "$(hook Stop false both)" 2 '^Do not edit src/checkstyle/'
expect "another validate failure is quoted" "$(hook Stop false enforcer)" 2 'This build requires at least Java 99'
expect "second stop: the agent may stop, the person is told" "$(hook Stop true both)" 1 'Build checks failed'
echo c > src/new.txt; git checkout -q -- src/A.java
expect "an untracked file counts as a change" "$(hook Stop false url)" 2 'http:// URL'
if [ "$fails" = 0 ]; then echo "all passed"; else echo "$fails failed"; exit 1; fi
