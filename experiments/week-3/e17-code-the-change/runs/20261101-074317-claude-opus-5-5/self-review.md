## pc-301: 18 of 21 tasks done; 3 are open, and the build is not reliably green

I implemented the microchip number through to the owner's page, and did H1–H6 under their tasks. The full suite does not pass reliably. The existing test `PetClinicConcurrencyTests.testDuplicatePetNameRaceConditionIsBlocked` fails intermittently since my new race test was added next to it. The cause is a race in the existing pet-name code, not in the microchip code (details under task 6.1).

### Tasks left open
- **0.2 (merge and release release 1 on its own):** this is a release step I can't do from here. Release 1 is only the two `data.sql` files. Nothing is committed: everything sits in one working tree, so release 1 has to be split out before anything is merged.
- **1.5 (migration scripts and tests):** the scripts and both tests are written and compile. Its check is "with Docker, both tests pass", and there is no Docker here. `MySqlMicrochipNumberMigrationTests` was skipped and `PostgresMicrochipNumberMigrationTests` ran 0 tests. Both are **not run**, not passed. They do what H3 and H6 ask: plain JDBC or `spring.sql.init.mode=never`, a check that the column is absent before the script, and release 1's scripts run again afterwards.
- **6.1 (full build passes):** blocked by the failure below.
  - **The failure:** across the runs I made, the name race test failed 3 of 4 times when run after my microchip race test, and passed 3 of 3 times on its own.
  - **What the SQL log shows:** the second name request runs `update pets set owner_id=null where owner_id=? and id=?`. Because `saveAndFlush` merges an owner whose pet list was loaded before the other request committed, it detaches the first request's pet. The `(owner_id, name)` constraint never fires, so both requests succeed and only one pet stays with the owner.
  - **Why it shows only now:** I think (not checked) that the name test used to pass because its first request was slowed by cold-start setup. My test warms up the shared context first.
  - **What it would take:** fixing it means changing how the controller saves the owner, which no task or decision covers. Moving or reordering the tests would only hide it. **Someone needs to decide** whether to open a ticket for the name race, or accept the test as flaky in the meantime.

### Self-review
**1. Full `./mvnw test` (final run):** 154 tests, 0 failures, 0 errors, 3 skipped, BUILD SUCCESS. The run before it had 1 failure, the name race test above, so this pass is not reliable.
- **Skipped or not run because there is no Docker:** MySqlIntegrationTests (2 skipped), MySqlMicrochipNumberMigrationTests (1 skipped), PostgresIntegrationTests and PostgresMicrochipNumberMigrationTests (0 run). None of these count as passed.
- **Baseline before any change:** 110 tests, 0 failures, 2 skipped, with the same Docker skips.
- **Other checks:** `openspec validate pc-301 --strict` reports the change as valid. ArchitectureTests passes, and the freeze store and other protected checks are unchanged (`git status` shows nothing there).

**2. Scenario → test**

| Scenario | Test |
|---|---|
| Added without a number | `PetControllerTests$MicrochipNumber.addWithoutMicrochipNumberSavesNoneAndDoesNotQuery` |
| Blank counts as none | `addWithBlankMicrochipNumberSavesNone`, `PetTests.blankMicrochipNumberBecomesNone` |
| Two pets without a number | `ClinicServiceTests.shouldSaveTwoPetsWithoutMicrochipNumber` |
| Spaces are removed | `addRemovesSpacesFromMicrochipNumber`, `PetTests` |
| Dashes are not removed | `addWithDashedNumberIsRejectedAndNotSaved` |
| Fifteen digits are accepted | Add form: `addAcceptsFifteenDigits`. Edit form: `editReplacesStoredNumberOnOwnersPet`, `PetMicrochipNumberIntegrationTests` |
| Any first three digits / 14 digits / 16 digits / 10-character number | Validator level only: `PetValidatorTests$MicrochipNumber`. **No form-level test** shows "nothing is saved" for these exact values, and none covers the edit form. |
| Number held by another owner's pet | `addWithNumberOfAnotherOwnersPetShowsOnlyIsAlreadyInUse`. It runs on a mocked repository, so "names no other pet" holds by construction: the query returns only a yes/no. |
| Editing to another pet's number | `editToAnotherPetsNumberIsRejected` |
| Saving with its own number | `editSavingPetWithItsOwnNumberIsAccepted`, `PetValidatorTests.ownNumberIsAcceptedForExistingPet`, `ClinicServiceTests.shouldFindMicrochipNumberOfAnotherPetButNotOfThePetItself` |
| New number replaces the stored one / field cleared / malformed new number rejected | `editReplacesStoredNumberOnOwnersPet`, `editWithEmptyFieldRemovesStoredNumberFromOwnersPet`, and `PetMicrochipNumberIntegrationTests` against H2 |
| Edit form with a number / without one | `editFormShowsStoredMicrochipNumber`, `editFormForPetWithoutNumberShowsEmptyField` |
| Malformed number not checked for duplicates / duplicate gets only the duplicate error | `PetValidatorTests.malformedNumberNeverReachesRepositoryAndGetsOneError`, `numberOfAnotherPetIsRejectedForNewPet` |
| Two simultaneous adds (microchip) | `PetClinicConcurrencyTests.testDuplicateMicrochipNumberRaceConditionShowsFormAgain` |
| Microchip constraint reported as a duplicate microchip number | `create…`/`editMicrochipConstraintIsReportedOnMicrochipNumber`. H2's real message: `ClinicServiceTests.shouldFailToInsertDuplicateMicrochipNumberForDifferentOwners` |
| Name constraint still reported on the name | `create…`/`editNameConstraintIsStillReportedOnNameOnly` |
| Another integrity violation | `PetControllerCharacterizationTests.create…`/`editOtherIntegrityViolationIsRethrown` |
| Two simultaneous adds (name) | `testDuplicatePetNameRaceConditionIsBlocked`, which is flaky (see 6.1) |
| Name constraint reported as a duplicate name | Existing `…UniqueViolationMessageMatchedCaseInsensitively` tests |
| Three errors on the add form / two errors on the edit form (baseline versions) | **None matches exactly.** The closest are `createReportsDuplicateNameAndFutureBirthDateTogether` and `createReportsEveryValidatorErrorAtOnce`. |
| Three / two errors, one on the microchip number | `addReportsThreeErrorsOneOnMicrochipNumber`, `editReportsTwoErrorsOneOnMicrochipNumber` |
| Owner's page with a number / without one | `OwnerControllerTests.showOwnerShowsPetsMicrochipNumber`, `showOwnerShowsEmptyMicrochipNumberForPetWithoutOne` (with the pet "Max" rather than "petty") |

**3. What I was unsure of, and work beyond the tasks**
- **H4 "say so in the code's design":** I put the explanation in a comment in `PetValidator` and did not edit `design.md`, which is a settled input.
- **H1:** I checked that the edit tests can fail by removing the copy line in `updatePetDetails` and rerunning. "Replaces" and "cleared" failed. The own-number test kept passing, because it is sensitive to which query runs, not to the copy. I then restored the line.
- **H2:** I added a check line under the Workflow follow-up in `tasks.md` (`openspec validate --specs --strict` exists; I checked `--help`).
- **Release 1 copies (for H3):** release 1's `schema.sql` and `data.sql` are stored as test resources under `src/test/resources/pc-301-release-1/`. The Postgres `data.sql` copy is missing one trailing space on line 9, because the editing tool trims it. It makes no difference to the SQL.
- **Approved change:** `PetControllerCharacterizationTests.java` gained only the `@MockitoBean PetRepository pets;` field. `git diff` confirms it, and no import was needed.
- **Beyond the tasks:**
  - a shared helper, `MicrochipNumberMigrationScenario`, used by both migration tests;
  - a test for a `null` microchip number in `PetTests`;
  - the form label uses the new `#{microchipNumber}` message rather than a literal, like the owner's page;
  - the translations in the nine locale files are mine and need review by a speaker, as the design notes.
- **Not verified (inferred):** the migration scripts and both migration tests have never run against a real MySQL or Postgres.
