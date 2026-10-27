#!/usr/bin/env bash
# Status line for the Week 2 ladder: model, the layers this step runs with,
# context used, lines changed. Display only: the model never sees it.
input=$(cat)
IFS=$'\t' read -r model ctx added removed < <(jq -r '[
  .model.display_name // "?",
  (.context_window.used_percentage // 0 | floor),
  .cost.total_lines_added // 0, .cost.total_lines_removed // 0] | @tsv' <<<"$input")
layers=$(printf '%s' "${LADDER_LAYERS:-none}" | sed 's/w2-//g')

reset=$'\e[0m' dim=$'\e[2m' bold=$'\e[1m'
cyan=$'\e[36m' magenta=$'\e[35m' green=$'\e[32m' yellow=$'\e[33m' red=$'\e[31m'
# Context: green below half, yellow from half, red from 80%.
if [ "$ctx" -ge 80 ]; then cc=$red; elif [ "$ctx" -ge 50 ]; then cc=$yellow; else cc=$green; fi
sep="${dim} · ${reset}"

printf '%s%s%s%s%slayers: %s%s%s%scontext %s%%%s%s%s+%s%s %s-%s%s\n' \
  "$bold$cyan" "$model" "$reset" "$sep" \
  "$magenta" "$layers" "$reset" "$sep" \
  "$cc" "$ctx" "$reset" "$sep" \
  "$green" "$added" "$reset" "$red" "$removed" "$reset"
