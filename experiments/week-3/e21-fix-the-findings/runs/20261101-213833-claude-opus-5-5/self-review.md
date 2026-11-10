I did both gate items, but task 7.2 stays unticked: its check is step 5's test-delta audit, which isn't in this repo, so I couldn't run it. No other item was blocked, and I needed no decision the gate doesn't hold.

There is no `.review-inputs/approvals.md`, so no protected check was touched. I edited nothing in `.review-inputs/`.

## Self-review

### 1. Full test suite (`./mvnw test`) — VERIFIED
- **BUILD SUCCESS**: 167 tests run, 0 failures, 0 errors, 3 skipped.
- **Skipped, no Docker:** `MySqlIntegrationTests` (2) and `MySqlMicrochipNumberMigrationTests` (1).
- **Not run, no Docker:** `PostgresIntegrationTests` and `PostgresMicrochipNumberMigrationTests` each report "Tests run: 0". None of these count as passed.
- `ArchitectureTests` (1) and `PetControllerCharacterizationTests` (29) passed.
- `openspec validate pc-301 --strict` reports the change as valid.

### 2. Gate items

**Decisions (`openspec/changes/pc-301/decisions.md`)** — VERIFIED
- **D32** records G14: `@DataJpaTest` is `database`. It amends D31, and D31 now carries an "Amended by D32" note, marked the way D23 is for D25.
- **D33** records G15: the one test becomes three, one per scenario. It amends D21, and D21 carries an "Amended by D33" note.
- Both cite the gate for step 8's base, round 2, answered 2026-11-01. No earlier text was deleted.

**W10 (G14)** — `ClinicServiceTests.java`
- **Renamed:** `shouldSaveTwoPetsWithoutMicrochipNumber` → `twoPetsWithoutAMicrochipNumber`. Only the method name changed.
- **Not renamed:** no test in this class honestly shows "Saving a pet with its own number". That scenario submits the edit form with a spaced number and expects the edit to be saved with the number kept. `shouldFindMicrochipNumberOfAnotherPetButNotOfThePetItself` and `shouldTestMicrochipNumberAndIdOnTheSamePet` (lines 318–374) only call the exists queries and never save a pet again. As the gate says, I left them and am saying so here. This scenario still has no test at `database`, which is for step 5 to report.
- **Check:** the class passes (16 tests). The rename-only claim rests on my single-line edit; I could not run step 5's audit.

**W11 (G15)** — `PetMicrochipNumberIntegrationTests.java`
- **What changed:** the old test is replaced by `aNewNumberReplacesTheStoredOne`, `aMalformedNewNumberIsRejected` and `theFieldIsCleared`. Each one:
  - adds its own pet through the add form and checks the number is stored,
  - makes one edit through the forms,
  - reads the stored value from the database with the old test's assertions for that step.
- **Docs:** task 3.5 and design Decision 4 are updated to name the three tests.
- **Check:** `./mvnw test -Dtest=PetMicrochipNumberIntegrationTests` passes with 3 tests. VERIFIED.
- **How I checked each test fails without its change** (both breaks undone, and a grep shows no leftovers) — VERIFIED:
  - With the copy in `updatePetDetails` commented out, `aNewNumberReplacesTheStoredOne` failed (expected `985141000654321`, was `985141000123456`) and `theFieldIsCleared` failed (expected null, was `985141000222222`).
  - That break can't touch the malformed test, because a rejected edit never reaches the copy. So I made a second break: save the pet even when the form has errors. Then `aMalformedNewNumberIsRejected` failed (expected `985141000111111`, was `12345`).
- I re-ticked 3.5 because both checks passed.

### 3. What I was unsure of, and what went beyond the gate
- **Different test values.** The three tests share one H2 database with no rollback, so each pet has its own name (Chippy, Nibbles, Dotty) and starting number. Only the replace test keeps the original `985141000123456` → `985141000654321`. The malformed and clear tests start from `985141000111111` and `985141000222222`. The assertions are the same kind as before, but the values differ out of necessity.
- **The number check moved.** The "stored after add" check now sits in the shared `add` helper, so all three tests repeat it. I read that as part of "sets up its own pet through the forms".
- **Task 7.2 is left unticked.** I replaced its "Open, outside the gate's decisions" sentence with the G14/G15 outcomes. I also qualified its check's "no test deleted" to allow for the test task 3.5 replaces (D33), since that replacement will show up as a deletion.
- **Design Decision 9** now lists `@DataJpaTest` as `database`, to match D32.
- **Formatting.** I ran `./mvnw spring-javaformat:apply`.
- **Tasks 0.2 and 1.5 stay unticked as before.** I did not touch them.
