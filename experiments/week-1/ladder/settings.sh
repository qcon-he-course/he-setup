# shellcheck shell=bash
# Shared settings for the ladder's scripts. Any of them can be set in the
# environment instead.
LADDER_HOME="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
EXPERIMENTS="$(dirname "$LADDER_HOME")"
PETCLINIC="${PETCLINIC:-$HOME/course/petclinic}"           # the seeded repository, your clone of he-petclinic
PETCLINIC_COMMIT="${PETCLINIC_COMMIT:-b107a86}"             # the pinned seeding commit
LADDER_MODEL="${LADDER_MODEL:-claude-opus-5-5}"             # the live model; stored runs also use claude-haiku-4-5
LADDER_WORKDIR="${LADDER_WORKDIR:-$HOME/.cache/qcon-he/ladder}"  # PetClinic clones, outside the project
LADDER_TIME_CAP="${LADDER_TIME_CAP:-1200}"                  # seconds an unattended run may take before it is stopped
export LADDER_HOME EXPERIMENTS PETCLINIC PETCLINIC_COMMIT LADDER_MODEL LADDER_WORKDIR LADDER_TIME_CAP

# Each experiment: its folder, and the layers it loads, in order. The ladder is
# cumulative: each rung keeps the layers below it. "init" is experiment 5's
# first step, /init in a bare session; its runs are kept in experiment 5's folder.
ladder_folder() {
  case "$1" in
    e0) echo e0-the-naked-agent ;;
    e2) echo e2-tell-it-how-to-behave ;;
    e3) echo e3-give-it-navigation ;;
    e4) echo e4-give-it-code-knowledge ;;
    e5|init) echo e5-require-evidence ;;
    e6) echo e6-build-your-mental-model ;;
    *) return 1 ;;
  esac
}
ladder_layers() {
  case "$1" in
    e0|init) echo "" ;;
    e2) echo "e2" ;;
    e3) echo "e2 e3" ;;
    e4) echo "e2 e3 e4" ;;
    e5) echo "e2 e3 e4 e5" ;;
    e6) echo "e2 e3 e4 e5 e6" ;;
    *) return 1 ;;
  esac
}
