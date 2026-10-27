#!/usr/bin/env bash
# Experiment 1: stop the tripwire and remove the demo network. Saved runs are kept.
set -euo pipefail
cd "$(dirname "$0")"
docker compose down
