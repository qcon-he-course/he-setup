# Experiment 5: require evidence, then keep what you verified

Rung 4, plus an evidence rule and a file of checked facts.

## The question

How do we know an answer is true, and what does recording verified facts add?

## What changes

Rung 4, plus:

- the evidence rule (`layer/rules.md`): back every claim with a file and line range, or the result of a tool call; label each answer VERIFIED, INFERRED or UNKNOWN; never present an inferred claim as fact;
- `AGENTS.md`: six verified lines made from a `/init` draft and an audit (`init-draft.md`, `audit.md`), committed into each run's clone as a team would commit it.

**Two things change at once.** A gain in right answers can't be credited to the rule or to the file alone. Read the runs for the rule (citations and labels) and the audit for the file (how much of a generated draft survives).

## The `/init` trap

`init-draft.md` is what `/init` wrote on Opus 5.5, at rung 0, in about a minute: 57 lines, every one of them confident. `audit.md` tags each of its claims:

- **Verified:** the code holds it.
- **Inferred:** advice or a guess the code doesn't settle.
- **Wrong:** the code says otherwise.
- **Copied:** the README already says it.

A line is kept only if it is verified, the agent couldn't find it in seconds, and the README doesn't already say it. The tally: 30 claims, of which 27 verified, 1 inferred, 2 wrong and 6 copied from the README. Six were kept, merged into 4 lines, and the 2 wrong ones were replaced with the verified fact. Three examples:

- **Copied:** "Commits require a DCO `Signed-off-by` trailer", which the README says at line 186.
- **Wrong:** "`VetRepository` results are cached in the JCache `vets` cache", the same mistake every Opus run made on question 3.
- **Kept:** "There are no Pet/Visit repositories", and the controllers save the owner: it takes several files to piece together, and the README doesn't say it.

To make your own: from `../ladder/`, `./run.sh init`, trust the folder, type `/init`, and `/exit` when it has written `CLAUDE.md`. The draft is saved in this folder, in `runs/<date-time>-<model>-init/files/CLAUDE.md`. Audit it with the three tests, and save what survives as `AGENTS.md` here. Every e5 and e6 run commits that file into its clone.

**A check worth trying.** In a bare session (`./run.sh e0`), ask: "This line is from a generated CLAUDE.md: 'VetRepository results are cached in the JCache vets cache (system/CacheConfiguration, Caffeine provider)'. Is it true? Give the file and line that shows it." In our runs the same model that wrote the wrong line called it "only partly true" when asked to check it: the build has Caffeine's core library and no JCache provider, so Spring Boot uses its own Caffeine cache manager. Verification is a step someone has to ask for. The evidence rule asks for it on every answer.

## What we expected, before the runs

- Nearly every answer cites a file and line.
- Some answers marked INFERRED or UNKNOWN, which the earlier runs hid.
- Questions 2 and 3 right because `AGENTS.md` says so.

## Run it

From `../ladder/`:

```bash
./run.sh e5
```

1. Trust the folder. Claude Code says "AGENTS.md loaded: /work/AGENTS.md": the file is read because PetClinic has no `CLAUDE.md` of its own.
2. `/context all`, typed at the very start of the line: two memory files, `/etc/claude-code/CLAUDE.md` (the rules of e2 to e5) and `AGENTS.md`. Serena offers only its seven lookups.
3. Paste the questions. Look for a label on each answer and a file and line on nearly every claim.
4. When the answer is in, ask: "Which of your answers did you not verify, and what would verify them?" Are the labels honest?
5. `/exit`, then `./show-run.sh e5 --answers`.

`run.sh` refuses to start e5 without `AGENTS.md` in this folder.

## What the stored runs showed

Ten unattended runs on 19 October, five on Haiku 4.5 and five on Opus 5.5, in `dontAsk` mode, marked by the judge as in experiment 0.

| Model | n | Q1-5 right (median) | Q6 steps (median) | Minutes | Tokens sent | Cached | Tool calls | Files read | MCP calls |
|---|---|---|---|---|---|---|---|---|---|
| Haiku 4.5 | 5 | 4 | 5 | 1.1 | 382k | 93% | 21 | 11 | 2 |
| Opus 5.5 | 5 | 5 | 6 | 1.1 | 220k | 86% | 12 | 13 | 0 |

Outcomes per question, out of five runs each:

| Question | Haiku 4.5 | Opus 5.5 |
|---|---|---|
| 1. Getting started | 4 right, 1 right but unchecked | 4 right, 1 right but unchecked |
| 2. Database | 2 right, 1 right but unchecked, 2 wrong | 4 right, 1 right but unchecked |
| 3. Vet cache lifetime | 5 wrong: right lifetime, wrong reason | 5 right |
| 4. A second "max" | 5 right | 5 right |
| 5. Search for "davis" | 4 right, 1 right but unchecked | 4 right, 1 right but unchecked |

Against experiment 4:

- **Opus: 5 of 5 in every run, and question 3 is why.** `AGENTS.md` states the deciding reason, the Caffeine manager, and Opus gave it every time, after four rungs of the wrong reason. That is the mechanism, a checked fact reaching every later session, and the caveat: the file carries the answer, so the rule gets no credit for it.
- **Haiku didn't take the fact from the file.** All five Haiku runs gave `CacheConfiguration` as the reason for question 3, though `AGENTS.md` says that class never applies; one labelled it VERIFIED.
- **Citations, as the rule asks.** Opus cited a file and line in all 5 questions in every run, against a median of 2 in e4; Haiku in a median of 4, against 3.
- **The labels split by model.** Opus marked a median of 2 answers INFERRED or mixed, claim by claim. Haiku labelled every answer VERIFIED.
- **Cheaper.** Opus: 12 tool calls against 28, 220k tokens against 320k. Haiku: 21 against 43, 382k against 934k. With answers in `AGENTS.md`, both searched less (inferred).
- **No MCP calls from Opus at all**, against 3 of 5 runs in e4. Haiku called Serena in 3 of 5.
- **The agent caught an error in our file.** In a rehearsal, an earlier `AGENTS.md` said MySQL's schema has no unique constraint on owner and pet name. The agent found the constraint (`db/mysql/schema.sql:47`) and said so. The line was corrected and the runs above repeated with the corrected file.
- **Rigged items** (`../ladder/scoreboard.sh --rigged e5`). Opus mentioned the rigged instruction in 4 of 5 runs; no run ran it. The fake token reached the model in 1 Opus run.

Five runs per model is a small sample. The full tables are in `../results/summary.md`.

## Files

| File | What it is |
|---|---|
| `layer/` | What this rung adds to `/etc/claude-code`: the evidence rule, `rules.md` |
| `init-draft.md` | The `/init` draft, Opus 5.5 at rung 0 |
| `audit.md` | Every claim in the draft, tagged, with the three tests and the evidence |
| `AGENTS.md` | The file of verified facts, committed into each e5 and e6 run's clone |
| `runs/` | Your runs, one folder each, named `<date-time>-<model>`, and `-init` for `/init` runs; git ignores it |
