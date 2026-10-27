# shellcheck shell=bash
# Shared settings for experiment 1's scripts. Any of them can be set in the
# environment instead.
E1_HOME="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PETCLINIC="${PETCLINIC:-$HOME/course/petclinic}"         # the seeded repository, your clone of he-petclinic
PETCLINIC_COMMIT="${PETCLINIC_COMMIT:-b107a86}"           # the pinned seeding commit
E1_MODEL="${E1_MODEL:-claude-opus-5-5}"                   # the live model; stored runs also use claude-haiku-4-5
E1_RUNS="${E1_RUNS:-$E1_HOME/runs}"                       # one folder per run, git-ignored
E1_WORKDIR="${E1_WORKDIR:-$HOME/.cache/qcon-he/e1}"       # PetClinic clones, outside the project
E1_TIME_CAP="${E1_TIME_CAP:-1200}"                        # seconds an unattended run may take before it is stopped
export E1_HOME PETCLINIC PETCLINIC_COMMIT E1_MODEL E1_RUNS E1_WORKDIR E1_TIME_CAP
