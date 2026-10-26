#!/usr/bin/env bash
# PreToolUse hook: stops an agent from editing the architecture sensor itself.
# Exit 2 sends the message on stderr back to the agent.
path=$(python3 -c 'import json,sys; print(json.load(sys.stdin).get("tool_input",{}).get("file_path",""))')
case "$path" in
  *ArchitectureTests.java|*/archunit_store/*|*/archunit.properties)
    echo "This file is part of the architecture sensor. Change the production code instead." >&2
    exit 2 ;;
esac
exit 0
