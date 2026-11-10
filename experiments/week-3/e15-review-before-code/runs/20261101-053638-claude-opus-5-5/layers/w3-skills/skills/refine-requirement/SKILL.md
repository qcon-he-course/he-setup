---
name: refine-requirement
description: Interview the user about a change before it is specified, one round of numbered questions at a time, and write down what is settled as it is settled: terms in GLOSSARY.md, every decision in the change's decisions log, hard-to-reverse trade-offs as ADRs. Use when the user asks to refine a ticket or requirement, or to be grilled about one.
---

# Refine a requirement

Interview the user about the change until you share one understanding of it. Write down what is settled the moment it is settled: the project's words in `GLOSSARY.md`, every decision in the change's decisions log, and the rare hard-to-reverse trade-off as an ADR. Do not write the spec or any code; the decisions log is what the next step works from.

## Facts are yours, decisions are the user's

Before each round, find every fact the round depends on: read the ticket, the baseline spec in `openspec/specs/`, the code and its tests. If your harness has sub-agents, give each lookup to one with a fresh context; otherwise look it up yourself before you ask. Never ask the user for something you could look up.

In an existing codebase, what the code does today is a fact; whether it stays that way is a decision. State the current behaviour with where you found it, then ask. Do not recommend "keep it as it is" by default: give the reason a change would or would not be worth it. The code may hold a bug.

## Rounds

Map the change as a design tree: every decision branches into the decisions that hang off it. The frontier is every decision whose prerequisites are already settled. Ask the whole frontier in one round, numbered, each with your recommended answer, and wait for the answers before the next round. A question that depends on another question still open belongs to a later round.

```
❓ **Q1. <question title>**: <the question, with the facts it rests on and where you found them>

➡️ <your recommended answer, and why>
```

Word each question so that "yes" accepts your recommendation. Each round's answers reshape the tree: recompute the frontier and ask the next round.

## Write as you go

**The decisions log.** Every decision goes to `openspec/changes/<change>/decisions.md` as soon as the user answers, in the user's words where they were precise. Keep numbers, limits, orderings and "must not" statements exactly as given; do not soften them. Create the file and its folder when the first decision is made.

```md
# Decisions: <change>

Ticket: <id and title>

## Decided

- **D1** <decision, one or two sentences>. Asked as Q1, answered <date>. Rejected: <alternatives, if any were discussed>.

## Facts the decisions rest on

- **F1** <fact>. Source: <file:line, test name, or command run>.

## Open

- **O1** <a question on the frontier that was not asked or not answered, and why>.
```

**The glossary.** When a term is resolved, add it to `GLOSSARY.md` at the repository root at once (create it with the first term). The glossary holds the project's own words and nothing else: no implementation details, no requirements, no notes.

```md
# <Context name>

<One or two sentences on what this context is.>

## Language

**Pet**:
An animal registered to one owner.
_Avoid_: Patient, animal
```

Be opinionated: when several words name one concept, pick one and list the others under `_Avoid_`. Keep each definition to one or two sentences, saying what the thing is. Include only terms specific to this domain. When the user, the ticket, the code or the spec uses a word that conflicts with the glossary, or uses two words for one thing, say so at once and ask which is right. When the user states how something works, check the code; if it disagrees, show where.

**ADRs.** Offer one only when the decision is hard to reverse, surprising without context, and the result of a real trade-off. If any of the three is missing, the decisions log is enough. An ADR goes to `docs/adr/NNNN-slug.md` (next number), and can be one paragraph: the context, what was decided, and why.

Test the boundaries of concepts with concrete scenarios, especially the edge cases the ticket does not mention.

## Ending

The session is done when the frontier is empty, or when the user ends it. Before you stop, write every question still on the frontier, or never reached, to the log's **Open** section. Then list what you wrote (log entries, glossary terms, ADRs) and ask the user to confirm you share one understanding. Do not act on the decisions until they do.

---

Adapted from Matt Pocock's `grilling`, `domain-modeling` and `grill-with-docs` skills (https://github.com/mattpocock/skills, commit 4ae2317ddb22b046e26455e4f9c9b3aaaf62212d, MIT; see LICENSE-mattpocock-skills). Changes: one self-contained file instead of a wrapper that loads two skills; a decisions log in the OpenSpec change folder; facts and current behaviour taken from the baseline spec and code; an Open section for the questions not asked.
