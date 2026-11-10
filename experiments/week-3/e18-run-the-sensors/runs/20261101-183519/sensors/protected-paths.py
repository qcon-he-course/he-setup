#!/usr/bin/env python3
"""protected-paths: the files in a clone that the protected-check rules cover.

  protected-paths.py [--rules FILE] [--approvals FILE] <clone>

Prints one path per line, relative to the clone: every tracked file that a
"protected-check" path rule in the rules file (default: risk-rules.txt next to
this script) matches, minus the files an approvals file names. An approvals file
names a file as a list item that starts with the path in backticks:

  - `src/test/java/.../PetControllerCharacterizationTests.java`: what was approved

demo.sh mounts the printed files read-only for the coding agent (e17), so the
agent cannot edit the checks that judge its change, except where a person has
approved one change. The same rules feed risk-floor.py and test-delta.py.
Exit 0, or 2 on a usage error.
"""

import os
import re
import subprocess
import sys

sys.dont_write_bytecode = True  # no __pycache__ next to the sensors
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import changes  # noqa: E402

APPROVED = re.compile(r"^\s*[-*]\s+`([^`]+)`")


def run(argv):
    rules_path = os.path.join(os.path.dirname(os.path.abspath(__file__)), "risk-rules.txt")
    approvals, clone, args = None, None, list(argv)
    while args:
        a = args.pop(0)
        if a in ("--rules", "--approvals"):
            if not args:
                raise changes.Usage(f"{a} needs a file")
            v = args.pop(0)
            if a == "--rules":
                rules_path = v
            else:
                approvals = v
        elif a.startswith("-"):
            raise changes.Usage(f"unknown option {a}")
        elif clone is None:
            clone = a
        else:
            raise changes.Usage("usage: protected-paths.py [--rules FILE] [--approvals FILE] <clone>")
    if clone is None:
        raise changes.Usage("usage: protected-paths.py [--rules FILE] [--approvals FILE] <clone>")
    rules = [r for r in changes.read_rules(rules_path) if r.surface == "protected-check" and r.kind == "path"]
    approved = set()
    if approvals:
        try:
            for line in open(approvals, encoding="utf-8"):
                m = APPROVED.match(line)
                if m:
                    approved.add(m.group(1).strip())
        except OSError:
            raise changes.Usage(f"no approvals file at {approvals}")
    p = subprocess.run(["git", "-C", clone, "ls-files"], capture_output=True, text=True)
    if p.returncode != 0:
        raise changes.Usage(f"{clone} is not a git clone")
    for path in p.stdout.splitlines():
        if path in approved:
            continue
        if any(r.regex.match(path) for r in rules):
            print(path)
    return 0


if __name__ == "__main__":
    changes.main(run)
