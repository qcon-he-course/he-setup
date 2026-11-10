# w3-egm

Google's Elephant-Goldfish Model (EGM), for one stored review in step 3 beside the class set (plan, 1 November). `egm/` is a pinned copy of the run-time parts of `google/elephant-goldfish-model` at `403d8881d62022490637d740657b33f01e321ea8` (30 October 2026): `skills/`, `agents/`, `resources/`, `docs/`, `LICENSE` (Apache-2.0), `README.md`, `plugin.json`. Unchanged.

How it runs (`LADDER_REVIEWER=egm ./demo.sh e15`):

- Not installed as a Claude Code plugin. EGM's own Claude Code guide (`egm/docs/claude.md`) says to read an EGM skill's `SKILL.md` and follow it in the same thread, since the `Skill` tool refuses EGM skills; the prompt does that for `egm-review`, with the `uninterrupted` preset (all five stages, no checkpoints).
- EGM's subagent types are not registered, so each Goldfish is a general-purpose subagent told to read its persona file first, as the skill allows. Two consequences, recorded with the run: Claude Code's adapters would limit reviewers to `Read, Grep, Glob` and omit `CLAUDE.md`; here the reviewers get the managed rules, and authority comes from the clone being mounted read-only (compose service `reviewer`), as for every Week 3 reviewer.
- Inputs as the step-3 class set had them, and the harness's probe of the frozen rule as a file in EGM's reading list: one target document assembled from the proposed change (proposal, spec deltas, design, then `## Detailed Implementation Plan` and the tasks), the decisions log, the baseline spec and the glossary. No project baseline: the class set had none.
- Reports go to `target/egm/` (`EGM artifact directory:`), the one writable folder; demo.sh copies them into the run and saves the consolidated report as `review.md`.
- The layer replaces `w3-skills` and `w3-reviewer` for this run: EGM writes its reports, which `w3-reviewer`'s deny on edit tools would block. `settings.json` allows reading the EGM copy and writing only under `target/egm/`.
