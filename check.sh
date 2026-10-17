#!/usr/bin/env bash
# check.sh: checks a machine's setup for Week 1 of the InfoQ Certified
# AI-Assisted Engineering Program, and prints a summary to paste into Slack.
#
# Usage:   bash ~/course/he-setup/check.sh
# Options: --no-network   skip the network checks
#
# Environment:
#   HE_COURSE_DIR   where the course repositories are (default: ~/course)
#
# It changes nothing on the machine. It reads versions, the two course
# repositories and the Maven cache, and makes one HTTPS request to each
# download site. It never prints keys, tokens or environment variables.
#
# Exit status: 0 when nothing failed, 1 when at least one check failed.
#
# Written for bash 3.2, the version macOS ships.

set -u

COURSE_DIR="${HE_COURSE_DIR:-$HOME/course}"
TOLLGATE_COMMIT="a256c9cce69319c8a6b060d9902efbd8f4d31e53"
PETCLINIC_COMMIT="b107a866c339e7473b17359d57eb643a7cd39442"
NETWORK=1

for arg in "$@"; do
  case "$arg" in
    --no-network) NETWORK=0 ;;
    -h|--help) sed -n '2,17p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) printf 'check.sh: unknown option: %s\n' "$arg" >&2; exit 2 ;;
  esac
done

PASS=0
WARN=0
FAIL=0
SUMMARY=""
TILDE="~"

# result STATUS LABEL DETAIL
result() {
  case "$1" in
    PASS) PASS=$((PASS + 1)) ;;
    WARN) WARN=$((WARN + 1)) ;;
    FAIL) FAIL=$((FAIL + 1)) ;;
  esac
  # Show the home folder as ~, so the Slack summary carries no user name.
  # The ~ comes from a variable: bash 3.2 and 5 treat a literal \~ in the
  # replacement differently.
  detail="${3//"$HOME"/$TILDE}"
  printf '%-4s  %-16s %s\n' "$1" "$2" "$detail"
  if [ "$1" != PASS ]; then
    SUMMARY="${SUMMARY}${1} ${2}: ${detail}
"
  fi
}

have() { command -v "$1" >/dev/null 2>&1; }

# --- Platform ----------------------------------------------------------------

os="$(uname -s)"
arch="$(uname -m)"
case "$os" in
  Darwin)
    platform="macOS $(sw_vers -productVersion 2>/dev/null || echo '?') $arch"
    result PASS platform "$platform" ;;
  Linux)
    if grep -qi microsoft /proc/version 2>/dev/null; then
      if grep -qi 'microsoft-standard' /proc/version 2>/dev/null || [ -n "${WSL_INTEROP:-}" ]; then
        platform="WSL 2 $arch"
        result PASS platform "$platform"
      else
        platform="WSL 1 $arch"
        result FAIL platform "WSL 1 is not supported. Convert the distribution with 'wsl --set-version <name> 2' in PowerShell"
      fi
      case "$COURSE_DIR" in
        /mnt/*) result WARN location "$COURSE_DIR is on the Windows drive, which is slow from WSL. Use a folder in your Linux home" ;;
      esac
    else
      # shellcheck disable=SC1091 # a system file, read at run time
      distro="$( (. /etc/os-release 2>/dev/null && printf '%s' "${PRETTY_NAME:-Linux}") || echo Linux)"
      platform="$distro $arch"
      result PASS platform "$platform"
    fi ;;
  *)
    platform="$os $arch"
    result FAIL platform "$os is not supported. On Windows, use WSL 2" ;;
esac

# --- Memory and disk ---------------------------------------------------------

mem_gb=""
if [ "$os" = Darwin ]; then
  bytes="$(sysctl -n hw.memsize 2>/dev/null || echo 0)"
  mem_gb=$((bytes / 1073741824))
elif [ -r /proc/meminfo ]; then
  kb="$(awk '/^MemTotal:/ {print $2}' /proc/meminfo)"
  mem_gb=$(((kb + 524288) / 1048576))
fi
if [ -n "$mem_gb" ]; then
  if [ "$mem_gb" -ge 8 ]; then
    result PASS memory "${mem_gb} GB"
  else
    result WARN memory "${mem_gb} GB. 8 GB or more is recommended; the Java language server needs room"
  fi
fi

free_kb="$(df -Pk "$HOME" 2>/dev/null | awk 'NR == 2 {print $4}')"
if [ -n "$free_kb" ]; then
  free_gb=$((free_kb / 1048576))
  if [ "$free_gb" -ge 5 ]; then
    result PASS disk "${free_gb} GB free in $HOME"
  else
    result WARN disk "${free_gb} GB free in $HOME. 5 GB or more is recommended"
  fi
fi

# --- git ---------------------------------------------------------------------

if have git; then
  result PASS git "$(git --version | sed 's/^git version //')"
else
  result FAIL git "not found"
fi

# --- Java --------------------------------------------------------------------

java_cmd=""
if [ -n "${JAVA_HOME:-}" ] && [ -x "$JAVA_HOME/bin/java" ]; then
  java_cmd="$JAVA_HOME/bin/java"
elif have java; then
  java_cmd="java"
fi

if [ -z "$java_cmd" ]; then
  result FAIL java "no JDK found. Install JDK 17 (see the README)"
else
  # The version line is usually first, but JAVA_TOOL_OPTIONS adds a line
  # before it, so look for it.
  java_out="$("$java_cmd" -version 2>&1)"
  java_line="$(printf '%s\n' "$java_out" | grep 'version "' | head -n 1)"
  [ -n "$java_line" ] || java_line="$(printf '%s\n' "$java_out" | head -n 1)"
  java_version="$(printf '%s' "$java_line" | sed -n 's/.*version "\([^"]*\)".*/\1/p')"
  if [ -z "$java_version" ]; then
    # On macOS, /usr/bin/java exists even without a JDK and prints an error.
    result FAIL java "no working JDK: $java_line"
  else
    case "$java_version" in
      1.*) major="$(printf '%s' "$java_version" | cut -d. -f2)" ;;
      *) major="$(printf '%s' "$java_version" | cut -d. -f1 | cut -d- -f1 | cut -d+ -f1)" ;;
    esac
    case "$major" in
      ''|*[!0-9]*) result WARN java "could not read the version from: $java_line" ;;
      *)
        if [ "$major" -eq 17 ]; then
          result PASS java "$java_version"
        elif [ "$major" -gt 17 ]; then
          result WARN java "$java_version. The course is tested with 17; install 17 and make it the default"
        else
          result FAIL java "$java_version. JDK 17 is required"
        fi ;;
    esac
  fi
fi

# --- Coding agent ------------------------------------------------------------

agents=""
if have claude; then
  v="$(claude --version 2>/dev/null | head -n 1)"
  result PASS claude "${v:-installed, version unknown}"
  agents="${agents} claude"
fi
if have codex; then
  v="$(codex --version 2>/dev/null | head -n 1)"
  result PASS codex "${v:-installed, version unknown}"
  agents="${agents} codex"
fi
if [ -z "$agents" ]; then
  result FAIL agent "neither Claude Code nor Codex found on the PATH"
fi

# --- Course repositories -----------------------------------------------------

# check_repo LABEL FOLDER EXPECTED_COMMIT REMOTE_NAME
check_repo() {
  label="$1"; dir="$2"; want="$3"; remote_name="$4"
  if [ ! -d "$dir" ]; then
    result FAIL "$label" "$dir not found. Clone it (see the README)"
    return
  fi
  if ! git -C "$dir" rev-parse --git-dir >/dev/null 2>&1; then
    result FAIL "$label" "$dir is not a git clone"
    return
  fi
  head="$(git -C "$dir" rev-parse HEAD 2>/dev/null)"
  url="$(git -C "$dir" config --get remote.origin.url 2>/dev/null || true)"
  case "$url" in
    *"$remote_name"*) ;;
    *) result WARN "$label" "origin is '${url:-none}', expected the course's $remote_name" ;;
  esac
  if [ "$head" != "$want" ]; then
    result FAIL "$label" "on commit ${head:0:7}, expected ${want:0:7}. Run: git -C $dir checkout main && git -C $dir pull"
    return
  fi
  # Build output is ignored by the repositories' .gitignore, so it does not
  # count as a change here.
  changes="$(git -C "$dir" --no-optional-locks status --porcelain 2>/dev/null | head -n 5)"
  if [ -n "$changes" ]; then
    result WARN "$label" "commit ${want:0:7}, but with local changes. Run: git -C $dir status"
  else
    result PASS "$label" "commit ${want:0:7}, no local changes"
  fi
}

check_repo tollgate "$COURSE_DIR/tollgate" "$TOLLGATE_COMMIT" he-tollgate
check_repo petclinic "$COURSE_DIR/petclinic" "$PETCLINIC_COMMIT" he-petclinic

if [ -d "$COURSE_DIR/he-setup" ]; then
  result PASS he-setup "$COURSE_DIR/he-setup"
else
  result WARN he-setup "$COURSE_DIR/he-setup not found. You'll need it on Monday"
fi

# --- Tollgate build ----------------------------------------------------------

# ./mvnw -B verify downloads Maven itself, Spring Boot and the embedded
# PostgreSQL binaries into ~/.m2. Their presence shows the build has run.
m2="$HOME/.m2"
missing=""
ls -d "$m2"/wrapper/dists/apache-maven-3.8.6* >/dev/null 2>&1 || missing="${missing} Maven 3.8.6,"
[ -d "$m2/repository/org/springframework/boot/spring-boot/2.7.18" ] || missing="${missing} Spring Boot 2.7.18,"
[ -d "$m2/repository/io/zonky/test" ] || missing="${missing} embedded PostgreSQL,"
if [ -z "$missing" ]; then
  if ls "$COURSE_DIR"/tollgate/*/target/surefire-reports/*.txt >/dev/null 2>&1; then
    result PASS build "Tollgate's dependencies are downloaded and its tests have run"
  else
    result WARN build "dependencies are downloaded, but no test reports found. Run: cd $COURSE_DIR/tollgate && ./mvnw -B verify"
  fi
else
  result FAIL build "not yet run (missing:${missing%,}). Run: cd $COURSE_DIR/tollgate && ./mvnw -B verify"
fi

# --- Network -----------------------------------------------------------------

# reach LABEL URL: any HTTP response counts, since some of these answer 404 to
# a bare request. Only a failed connection (code 000) fails.
reach() {
  code="$(curl -sS -o /dev/null -w '%{http_code}' --max-time 15 "$2" 2>/dev/null)" || true
  if [ -n "$code" ] && [ "$code" != 000 ]; then
    result PASS "$1" "reachable"
  else
    result FAIL "$1" "cannot reach $2. A proxy or firewall may block it"
  fi
}

if [ "$NETWORK" -eq 1 ]; then
  if have curl; then
    reach github https://github.com
    reach maven-central https://repo.maven.apache.org/maven2/
    reach pypi https://pypi.org/simple/
    case "$agents" in *claude*) reach anthropic https://api.anthropic.com ;; esac
    case "$agents" in *codex*) reach openai https://api.openai.com ;; esac
  else
    result WARN network "curl not found, so the network checks were skipped"
  fi
fi

# --- Summary -----------------------------------------------------------------

echo
echo "Paste the block below into the Slack thread:"
echo
echo '```'
printf 'he-setup check, %s, %s\n' "$(date '+%Y-%m-%d %H:%M')" "$platform"
printf '%s pass, %s warn, %s fail\n' "$PASS" "$WARN" "$FAIL"
if [ -n "$agents" ]; then
  printf 'agents:%s\n' "$agents"
fi
printf '%s' "$SUMMARY"
echo '```'

if [ "$FAIL" -gt 0 ]; then
  exit 1
fi
exit 0
