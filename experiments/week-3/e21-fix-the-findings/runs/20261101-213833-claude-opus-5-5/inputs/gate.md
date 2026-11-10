# The gate for step 8's base, round 2, 1 November

Input: the base run of 1 November (e21 `runs/20261101-204240-claude-opus-5-5`), which did W8 and most of W9 and stopped on two items that needed a decision. Prem answered both. No new tests beyond the split below.

## Decisions

| # | Question | Answer |
|---|---|---|
| G14 | `@DataJpaTest` has no level in G13 | **`@DataJpaTest` is `database`, like `@SpringBootTest`.** G13 left it out by mistake: the plan and step 5's scenario-coverage sensor already count it as `database`. Record G14 as a new decision that amends G13 (D31); mark D31 as D23 is marked for D25 |
| G15 | G3's real-database test (`PetMicrochipNumberIntegrationTests.microchipNumberIsAddedReplacedAndClearedThroughTheForms`) shows three scenarios, and a test's name can carry one | **Split it into three tests, one per scenario, each setting up its own pet.** This reverses the part of G3 (D21) that asked for one test that adds, edits and clears; the checks it asked for stay, at the same level. Record G15 as a new decision that amends D21; mark D21 |

## Work for the author

| # | From | What to do | Checked by |
|---|---|---|---|
| W10 | G14 | Rename the `ClinicServiceTests` methods that show "Two pets without a microchip number" and "Saving a pet with its own number" (both `database`) to G13's rule, if they show the scenario; names only, no body change. If no test there honestly shows "Saving a pet with its own number" at `database`, leave it and say so | Step 5's test-delta audit shows "test renamed … body unchanged" for each |
| W11 | G15 | Replace `microchipNumberIsAddedReplacedAndClearedThroughTheForms` with three tests in the same class: `aNewNumberReplacesTheStoredOne`, `aMalformedNewNumberIsRejected` and `theFieldIsCleared`. Each sets up its own pet through the forms, makes one change through the forms, and reads the stored value from the database, with the same assertions the one test made for that step. Update task 3.5 and design Decision 4's mention of the test | `./mvnw test -Dtest=PetMicrochipNumberIntegrationTests` passes with three tests; each fails if its form change is not stored (say in the self-review how you checked that, for example by breaking the copy in `updatePetDetails` once) |

## Left as they are

- Everything else, including the scenarios with no test at their level ("Three errors on the add form", "Two errors on the edit form"): those are for step 5 to report.
