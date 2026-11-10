# w3-codex

The Week 3 reviewer on Codex CLI, for e15 with `LADDER_AGENT=codex`. Not a Claude Code layer: `ladder-assemble` never sees it.

demo.sh builds the run's `CODEX_HOME` from:

- `config.toml` (this folder);
- `AGENTS.md`: `w3-base/rules.md` without its Claude-only batch line, then `w3-reviewer/rules.md`;
- `skills/<name>/SKILL.md`: each of Week 3's skills in this repository's `skills/` folder, as `w3-skills` gives Claude.

Differences from the Claude reviewer, which the comparison has to allow for:

- Authority is the same for both: the clone is mounted read-only except `target/` (compose services `reviewer` and `codex`). Claude also keeps the `w3-reviewer` deny on its edit tools, as a second layer.
- Commands: Claude in batch mode refuses shell commands outside its allow list. Codex runs any command.
- Floor: Week 1's managed settings apply to Claude only.

Checked on 31 October with Codex CLI 0.163.0 (`codex debug prompt-input`): the AGENTS.md in `CODEX_HOME` and the skills in `CODEX_HOME/skills` reach the model; `config.toml` passes `--strict-config`.
