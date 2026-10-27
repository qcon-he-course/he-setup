#!/usr/bin/env bash
# Experiment 6, once, before the dry runs: CodeBoarding's component analysis of
# PetClinic, saved in e6-build-your-mental-model/codeboarding/. run.sh e6 copies
# it into the clone as .harness/codeboarding/, where the arch-map skill reads it.
#
# CodeBoarding calls a model for every component, so it needs a provider API
# key: set exactly one of ANTHROPIC_API_KEY (a Claude Console key, sk-ant-api...),
# OPENAI_API_KEY, OPENROUTER_API_KEY or GOOGLE_API_KEY. A Claude subscription
# token is never used here. AGENT_MODEL picks the model (CodeBoarding's default
# for the provider otherwise). CODEBOARDING_DEPTH sets --depth-cap (default 2).
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=settings.sh
. "$here/settings.sh"

keys=()
for k in ANTHROPIC_API_KEY OPENAI_API_KEY OPENROUTER_API_KEY GOOGLE_API_KEY; do
  [ -n "${!k:-}" ] && keys+=("$k")
done
if [ "${#keys[@]}" != 1 ]; then
  echo "codeboarding: set exactly one of ANTHROPIC_API_KEY, OPENAI_API_KEY, OPENROUTER_API_KEY, GOOGLE_API_KEY (found ${#keys[@]})" >&2
  exit 1
fi
case "${ANTHROPIC_API_KEY:-}" in
  sk-ant-oat*) echo "codeboarding: that is a Claude subscription token. CodeBoarding needs a Claude Console API key (sk-ant-api...)." >&2; exit 1 ;;
esac

out="$EXPERIMENTS/e6-build-your-mental-model/codeboarding"
stamp="$(date +%Y%m%d-%H%M%S)-codeboarding"
work="$LADDER_WORKDIR/$stamp/petclinic"
mkdir -p "$LADDER_WORKDIR/$stamp" "$LADDER_WORKDIR/$stamp/config" "$LADDER_WORKDIR/$stamp/record"
git clone --quiet "$PETCLINIC" "$work"
git -C "$work" -c advice.detachedHead=false checkout --quiet "$PETCLINIC_COMMIT"

export LADDER_WORK="$work" LADDER_CONFIG="$LADDER_WORKDIR/$stamp/config" LADDER_LAYERS="" \
       LADDER_LAYERS_DIR="$LADDER_WORKDIR/$stamp/record" LADDER_RECORD="$LADDER_WORKDIR/$stamp/record"
model_env=()
[ -n "${AGENT_MODEL:-}" ] && model_env=(-e AGENT_MODEL)
echo "codeboarding: PetClinic at $PETCLINIC_COMMIT, provider key ${keys[0]}, depth cap ${CODEBOARDING_DEPTH:-2}"
cd "$here"
docker compose build session
# Started from its own folder, so nothing reads PetClinic's .env.
log="$LADDER_WORKDIR/$stamp/codeboarding.log"
docker compose run --rm -T -e LADDER_PREPARE=0 -e CLAUDE_CODE_OAUTH_TOKEN= -e "${keys[0]}" \
  ${model_env[@]+"${model_env[@]}"} -w /home/node session \
  codeboarding full --local /work --output-dir /work/.harness/codeboarding --project-name petclinic \
  --render md --depth-cap "${CODEBOARDING_DEPTH:-2}" 2>&1 | tee "$log"

if [ ! -f "$work/.harness/codeboarding/analysis.json" ]; then
  echo "codeboarding: no analysis.json was written; the clone and the log are kept in $LADDER_WORKDIR/$stamp" >&2
  exit 1
fi
# CodeBoarding writes analysis.json even when every model call fails, with
# deterministic names only. That output is no use for experiment 6.
if grep -q -E "Semantic analysis failed|fell back to deterministic names" "$log"; then
  echo "codeboarding: the model calls failed, so components have no model-written names or descriptions." >&2
  grep -m1 -o -E "'message': '[^']*'" "$log" >&2 || true
  echo "codeboarding: nothing was saved; the log is in $log" >&2
  exit 1
fi
rm -rf "$out"
cp -R "$work/.harness/codeboarding" "$out"
rm -rf "${LADDER_WORKDIR:?}/$stamp"
echo "codeboarding: saved in $out"
ls "$out"
