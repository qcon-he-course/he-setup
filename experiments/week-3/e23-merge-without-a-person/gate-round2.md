# The gate on PC-303 after round 2, 2 November

Input: round 2 (`runs/clean-round2/`). e14's proposal listed four open questions (Q1 to Q4), and e17 stopped under D6 with 16 of the 20 scenarios tested and nothing on the page yet. Its self-review also asked whether the `pom.xml` edit of task 2.4 was allowed. Prem answered all five on 2 November. After this gate: e21 finishes the code from where e17 stopped, then e18, the four reviews and the rung.

## Decisions

| # | Question | Answer |
|---|---|---|
| G1 | Q1: which side of the birth date does "Age" go? | Directly after Birth Date, before Type: it reads with the date it is worked out from |
| G2 | Q2: does `messages_en.properties` get the texts? | No. It stays empty: it exists to fall back to `messages.properties`, and `I18nPropertiesSyncTest` skips it on purpose. D7's "every language file" means the files the sync test checks |
| G3 | Q3: the `pets` spec's Purpose excludes the owner's page | Widen the Purpose to cover a pet's details on the owner's page. OpenSpec has no delta for a Purpose, so the change edits the Purpose line of `openspec/specs/pets/spec.md` directly, and the proposal says so |
| G4 | Q4: which digits does the age use? | Always 0 to 9, as the birth date beside it does (`yyyy-MM-dd`), in every language |
| G5 | Task 2.4 edits `pom.xml` to add `PetAge` to PIT's `targetClasses`. Allowed? | No. PC-303 leaves `pom.xml` as it is: any `pom.xml` change makes the risk floor material. Mutation testing of new classes is Week 4's work, with its thresholds before commit. Rejected: keeping the edit and accepting a material floor; narrowing the risk rule for this change |

## Work for the author

| # | From | What to do | Checked by |
|---|---|---|---|
| W1 | G5 | Undo the `pom.xml` edit: `pom.xml` is as it was at the start of the change. Change task 2.4 to say that `PetAge` is not in PIT's list in this change, and why (G5) | `git diff -- pom.xml` is empty; `./mvnw validate` passes |
| W2 | G2 | Task 2.1: `messages_en.properties` stays as it is. Tick 2.1 when its check passes | `git diff -- src/main/resources/messages/messages_en.properties` is empty; `I18nPropertiesSyncTest` passes |
| W3 | G3 | Edit the Purpose line of `openspec/specs/pets/spec.md` so that it covers a pet's details on the owner's page, and say in the proposal that the change does this and why. This is the one edit to that file | `openspec validate pc-303 --strict` is valid |
| W4 | G1, G4 | The rest of the tasks, from 1.1 on, with the answers above: "Age" directly after Birth Date; digits 0 to 9 in every language. Update the specs' wording to match G1 and G4 where they say "next to" or assume the digits, and the proposal's open questions to "answered at the gate, see decisions" | Each task's own check; `./mvnw test` passes; every scenario in the spec delta has a test named for it at its level |

## Left as they are

- `messages_en.properties`, `pom.xml`, `I18nPropertiesSyncTest` and every protected check.
- The decisions D1 to D12.
