# The gate for step 8's base, 1 November

Input: PC-301's finished change (e21, round 2). Step 8 plants flaws in it and measures what the sensors and the reviewers catch. Before that, each scenario declares the level at which it is checked, and the tests are named after the scenarios they show, so that step 5's scenario-coverage sensor can check, by name and level, that each scenario has a test (plan, "A scenario-coverage sensor for step 8").

## Decisions

| # | Question | Answer |
|---|---|---|
| G12 | At what level is each scenario checked? | **The lowest level at which its outcome can be observed**, from `unit` < `form` < `database` < `mysql-postgres` < `concurrency` < `manual` (`manual` only with a recorded reason). Most scenarios are checked at `unit`; fewer at each level up. Prem approved these levels for PC-301 on 1 November: see "Levels" below (11 unit, 14 form, 5 database, 2 concurrency). A scenario declares its level in a last line `- **CHECKED AT** <level>`. Record G12 as a new decision |
| G13 | How does a test say which scenario it shows? | **By its name alone, no comments.** The method's name is the scenario's title in lowerCamelCase, punctuation and apostrophes dropped; more words may follow (`spacesAreRemoved`, `spacesAreRemovedOnTheEditForm`); when two titles match, the longest wins. A test's level comes from its class (`@WebMvcTest` is `form`; `@SpringBootTest` is `database`, and `form` as well if it drives MockMvc or HTTP (and `@DataJpaTest` is `database` too: added by G14 in round 2, after this gate left it out); threads against a running app are `concurrency`; no Spring test annotation is `unit`). Record G13 as a new decision |

## Levels

| Scenario | Level |
|---|---|
| A pet is added without a microchip number | form |
| A blank microchip number counts as none | unit |
| Two pets without a microchip number | database |
| Spaces are removed | unit |
| Dashes are not removed | unit |
| Fifteen digits are accepted | unit |
| Any first three digits are accepted | unit |
| Fourteen digits are rejected | unit |
| Sixteen digits are rejected | unit |
| A 10-character non-ISO number is rejected | unit |
| A number held by another owner's pet | form |
| Editing a pet to another pet's number | unit |
| Saving a pet with its own number | database |
| A new number replaces the stored one | database |
| A malformed new number is rejected | database |
| The field is cleared | database |
| A pet with a number | form |
| A pet without a number | form |
| A malformed number is not checked for duplicates | unit |
| A duplicate gets only the duplicate error | unit |
| Two simultaneous adds with the same number | concurrency |
| The constraint is reported as a duplicate microchip number | form |
| The name constraint is still reported on the name | form |
| Two simultaneous adds with the same name | concurrency |
| The constraint is reported as a duplicate name | form |
| Another integrity violation | form |
| Three errors on the add form | form |
| Two errors on the edit form | form |
| Three errors on the add form, one on the microchip number | form |
| Two errors on the edit form, one on the microchip number | form |
| A pet with a microchip number (owner's page) | form |
| A pet without a microchip number (owner's page) | form |

## Work for the author

| # | From | What to do | Checked by |
|---|---|---|---|
| W8 | G12 | Add the line `- **CHECKED AT** <level>` as the last line of each of the 32 scenarios in `specs/pets/spec.md` and `specs/owner-details/spec.md`, with the level from "Levels". Change nothing else in the spec deltas | `openspec validate pc-301 --strict` is valid; each of the 32 scenarios has exactly one such line |
| W9 | G13 | Rename the test methods that show a scenario, at its level, so that their names follow G13. Rename only: no test body changes, and no new tests. A test that shows no scenario keeps its name. Where no test at the scenario's level shows it, leave it, and list it in your self-review with the level it needs: that is a finding for step 5, not work for this run. A test you cannot honestly say shows the scenario is not renamed to it. Renames in `PetControllerCharacterizationTests` are approved (`approvals.md`); there too, names only. `PetClinicConcurrencyTests.testDuplicatePetNameRaceConditionIsBlocked` becomes `twoSimultaneousAddsWithTheSameName`: a person updates the known-defect list after this run | `./mvnw test` passes as before. Step 5's test-delta audit shows each change as "test renamed … body unchanged", and no "test deleted". In the self-review, a table: scenario, level, the test or tests now named for it, or "none at this level" |

## Left as they are

- Everything else in the change, the decisions D1 to D29, and every finding of the earlier gates.
