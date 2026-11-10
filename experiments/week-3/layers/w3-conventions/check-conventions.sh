#!/usr/bin/env bash
# Stop hook: the build's own checks, ./mvnw validate, before the coding agent finishes.
# Week 3's sensor for baseline B1 (formatting and http:// URLs), built like Week 2's
# check-architecture.sh: quiet until the agent tries to stop, a message written for the
# agent, and exit 2 to send it back. Wired by the w3-conventions layer (e17, e21).
# Step 5 runs the same checks again afterwards, outside the agent's session.
set -u
input=$(cat)
field() { printf '%s' "$input" | python3 -c "import json,sys; print(json.load(sys.stdin).get('$1', ''))"; }
event=$(field hook_event_name)
active=$(field stop_hook_active)
cd "${CLAUDE_PROJECT_DIR:-.}" || exit 0

# Only when the agent tries to stop, and only if something changed. After every edit it
# would cry wolf: code is unformatted until the agent runs the formatter.
[ "$event" = "Stop" ] || exit 0
[ -n "$(git status --porcelain 2> /dev/null)" ] || exit 0

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
./mvnw -B validate > "$tmp/validate.log" 2>&1 && exit 0

# validate stops at its first failure; run B1's two checks on their own so the message
# can name every problem.
./mvnw -B spring-javaformat:validate > "$tmp/format.log" 2>&1
format_exit=$?
./mvnw -B checkstyle:check@nohttp-checkstyle-validation > "$tmp/nohttp.log" 2>&1
nohttp_exit=$?

message=$(python3 - "$PWD" "$tmp" "$format_exit" "$nohttp_exit" <<'PY'
import os, re, sys
root, tmp, format_exit, nohttp_exit = sys.argv[1:]
read = lambda f: open(os.path.join(tmp, f), encoding="utf-8", errors="replace").read()
files = [os.path.relpath(f, root) for f in re.findall(r"^\[ERROR\]\s+\* (\S+)", read("format.log"), re.M)]
urls = []
for l in read("nohttp.log").splitlines():
    m = re.search(r"\[ERROR\] (\S+?):\[(\d+),\d+\].*?got '([^']+)'", l)
    if m:
        urls.append(f"{m.group(1)}:{m.group(2)}: {m.group(3)}")
out = ["Build checks failed: ./mvnw validate, which ./mvnw verify runs first."]
if format_exit != "0" or nohttp_exit != "0":
    out.append("Why: the build rejects unformatted Java code and plain http:// URLs (project baseline B1).")
    todo = []
    if format_exit != "0":
        todo.append("run ./mvnw spring-javaformat:apply")
    if nohttp_exit != "0":
        todo.append("change each http:// URL below to https://")
    out.append("What to do instead: " + "; ".join(todo) + ".")
    out.append("Where:")
    out += [f"  Unformatted: {f}" for f in files] or ([] if format_exit == "0" else ["  Unformatted: see ./mvnw spring-javaformat:validate"])
    out += [f"  http:// URL: {u}" for u in urls] or ([] if nohttp_exit == "0" else ["  http:// URL: see ./mvnw checkstyle:check@nohttp-checkstyle-validation"])
else:
    errors = [l for l in read("validate.log").splitlines() if l.startswith("[ERROR]") and l.strip() != "[ERROR]"][:5]
    out.append("Why: formatting and URLs pass; another check that the build runs at validate failed.")
    out.append("What to do instead: read the error below and fix its cause.")
    out.append("Where:")
    out += ["  " + l for l in errors]
out.append("Do not edit src/checkstyle/ or the pom's plugin settings, and do not add skip flags: fix the files.")
print("\n".join(out))
PY
)

# Stop, after this hook already blocked once: let the agent stop, and tell the person.
# Exit 1 is a non-blocking error: Claude Code shows it to the user, not the agent.
printf '%s\n' "$message" >&2
if [ "$active" = "True" ]; then exit 1; fi
exit 2
