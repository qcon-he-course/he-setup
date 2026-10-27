#!/usr/bin/env bash
# Experiment 1, left window: start the tripwire and show every request it receives.
# Ctrl-C stops it. Run ./stop.sh afterwards to remove the network.
set -euo pipefail
cd "$(dirname "$0")"
TRIPWIRE_UTC_OFFSET="$(date +%z)" docker compose up --no-log-prefix tripwire
