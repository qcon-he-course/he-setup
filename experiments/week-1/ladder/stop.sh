#!/usr/bin/env bash
# Stop Memgraph and remove the ladder's network. Saved runs and the caches
# (Serena's index, Maven's downloads) are kept. --all also removes the caches
# and the graph.
set -euo pipefail
cd "$(dirname "$0")"
if [ "${1:-}" = --all ]; then
  docker compose down --volumes
else
  docker compose down
fi
