## 1. Scenarios

VERIFIED means I opened the cited evidence; test execution results below come from the supplied sensors. MET applies only to asserted behavior. References use repository-relative paths; `PCT` means `owner/PetControllerTests.java`, `PVT` means `owner/PetValidatorTests.java`, and `Characterization` means `owner/PetControllerCharacterizationTests.java`, all under `src/test/java/org/springframework/samples/petclinic/`.

| Scenario | Verdict | Evidence and limits |
|---|---|---|
| A pet is added without a microchip number | **MET — VERIFIED** | PCT `addWithoutMicrochipNumberSavesNoneAndDoesNotQuery`, lines 334–347: asserts saved value is null, owner redirect, and exact flash message. |
| A blank microchip number counts as none | **MET — VERIFIED** | PCT `addWithBlankMicrochipNumberSavesNone`, lines 349–359: submits spaces and asserts null on the saved pet. |
| Two pets without a microchip number | **MET — VERIFIED** | `service/ClinicServiceTests.java:348–378`, `shouldSaveTwoPetsWithoutMicrochipNumber`: flushes both and asserts IDs and null numbers. |
| Spaces are removed | **MET — VERIFIED** | PCT `addRemovesSpacesFromMicrochipNumber`, lines 361–372: asserts normalized number on saved pet and query argument. |
| Dashes are not removed | **MET — VERIFIED** | PCT `addWithDashedNumberIsRejectedAndNotSaved`, lines 386–400: form, single field error, exact message, and no save. |
| Fifteen digits are accepted | **MET — VERIFIED** | PCT `addAcceptsFifteenDigits`, lines 374–384, asserts saved number; `PetMicrochipNumberIntegrationTests.java:55–75` asserts database values after add and edit. |
| Any first three digits are accepted | **PARTLY — VERIFIED** | PVT `anyFirstThreeDigitsAreAccepted`, lines 196–203, asserts no validation errors. It does not assert a form submission or save. **INFERRED:** the controller saves it through its ordinary valid-submission path (`PetController.java:117–137`). |
| Fourteen digits are rejected | **PARTLY — VERIFIED** | PVT `fourteenDigitsAreRejected`, lines 205–212, asserts exactly one format error. No form/message/no-save assertion for this input. |
| Sixteen digits are rejected | **PARTLY — VERIFIED** | PVT `sixteenDigitsAreRejected`, lines 214–221, has the same coverage limit. |
| A 10-character non-ISO number is rejected | **PARTLY — VERIFIED** | PVT `tenCharacterNonIsoNumberIsRejected`, lines 223–230, asserts the format error, without exercising the form or save. |
| A number held by another owner's pet | **MET — VERIFIED** | PCT `addWithNumberOfAnotherOwnersPetShowsOnlyIsAlreadyInUse`, lines 402–423: explicit duplicate stub, field error/message, no save, and absence of the other names. Global database rejection is separately asserted in `ClinicServiceTests.java:381–402`. |
| Editing a pet to another pet's number | **MET — VERIFIED** | PCT `editToAnotherPetsNumberIsRejected`, lines 513–530: explicit duplicate stub, form/error/message, and no save. |
| Saving a pet with its own number | **MET — VERIFIED** | PCT `editSavingPetWithItsOwnNumberIsAccepted`, lines 495–511: verifies exclusion query and saved normalized number; the non-excluding query is deliberately stubbed true. Real query semantics are asserted in `ClinicServiceTests.java:320–345`. |
| A new number replaces the stored one | **MET — VERIFIED** | `PetMicrochipNumberIntegrationTests.microchipNumberIsAddedReplacedAndClearedThroughTheForms`, lines 55–75: asserts changed database value after edit. |
| A malformed new number is rejected | **MET — VERIFIED** | Same test, lines 66–69: asserts form/message and unchanged database value. |
| The field is cleared | **MET — VERIFIED** | Same test, lines 74–75: successful edit followed by database null assertion. |
| A pet with a number — edit form | **MET — VERIFIED** | PCT `editFormShowsStoredMicrochipNumber`, lines 447–456: asserts input value. |
| A pet without a number — edit form | **MET — VERIFIED** | PCT `editFormForPetWithoutNumberShowsEmptyField`, lines 458–467: asserts empty input value. |
| A malformed number is not checked for duplicates | **PARTLY — VERIFIED** | PVT `malformedNumberNeverReachesRepositoryAndGetsOneError`, lines 276–284: exact single error and no repository interaction. The specified trailing-dash input is not tested through the rendered form. |
| A duplicate gets only the duplicate error | **MET — VERIFIED** | PCT lines 402–423: asserts one total error, on `microchipNumber`, with the duplicate message. |
| Two simultaneous adds with the same number | **MET — VERIFIED** | `PetClinicConcurrencyTests.testDuplicateMicrochipNumberRaceConditionShowsFormAgain`, lines 136–214: asserts no exceptions, one rejected response with field message, one stored number, and one added race pet. This does not force the database catch path. |
| The constraint is reported as a duplicate microchip number | **PARTLY — VERIFIED** | PCT `createMicrochipConstraintIsReportedOnMicrochipNumber` and `editMicrochipConstraintIsReportedOnMicrochipNumber`, lines 552–581: explicit exception stubs, form, exactly one error on the correct field. Neither asserts the rendered message. |
| The name constraint is still reported on the name | **PARTLY — VERIFIED** | PCT `createNameConstraintIsStillReportedOnNameOnly` and `editNameConstraintIsStillReportedOnNameOnly`, lines 583–610: exact single name error; rendered message is not asserted. |
| Two simultaneous adds with the same name | **MET for supplied runs — VERIFIED** | `PetClinicConcurrencyTests.testDuplicatePetNameRaceConditionIsBlocked`, lines 116–133, asserts exactly one additional pet and one matching name. Sensors report 3/3 passes, but explicitly retain PC-302 as timing-dependent (`sensors.md:107–115`). |
| The constraint is reported as a duplicate name | **PARTLY — VERIFIED** | Characterization `editUniqueViolationMessageMatchedCaseInsensitively`, lines 444–454, asserts form and field code; not rendered text. |
| Another integrity violation | **MET — VERIFIED** | Characterization `createOtherIntegrityViolationIsRethrown`, lines 283–289, and `editOtherIntegrityViolationIsRethrown`, lines 456–463, assert request failure with the integrity exception. Execution does not return an error form. |
| Three errors on the add form | **UNTESTED as specified — VERIFIED** | Existing nearby tests cover duplicate name plus future date, and three required fields, separately (Characterization lines 220–239). **INFERRED:** the specified combination produces all three through `PetValidator.java:64–75` and `PetController.java:113–118`. |
| Two errors on the edit form | **PARTLY — VERIFIED** | Characterization `editReportsDuplicateNameAndMissingBirthDateTogether` asserts the two field codes (`Characterization:365–391`); rendered wording is not asserted. |
| Three errors on the add form, one on the microchip number | **MET — VERIFIED** | PCT `addReportsThreeErrorsOneOnMicrochipNumber`, lines 425–443: count, all field codes, all messages, and no save. |
| Two errors on the edit form, one on the microchip number | **MET — VERIFIED** | PCT `editReportsTwoErrorsOneOnMicrochipNumber`, lines 532–548: count, both field codes/messages, and no save. |
| A pet with a microchip number — owner's page | **MET — VERIFIED** | `owner/OwnerControllerTests.showOwnerShowsPetsMicrochipNumber`, lines 299–312: asserts adjacent label/value markup. Uses pet “Max” rather than the scenario's “petty.” |
| A pet without a microchip number — owner's page | **MET — VERIFIED** | `owner/OwnerControllerTests.showOwnerShowsEmptyMicrochipNumberForPetWithoutOne`, lines 314–324: asserts label with empty value and absence of “none.” |

## 2. Decisions and baseline

All implementation assessments in this table are **VERIFIED by reading**, except the deployment status explicitly marked UNKNOWN.

| Decision | Assessment | Evidence |
|---|---|---|
| D1 terminology | CARRIED | `Pet.java:56–57,80–90`; `messages.properties:53–54`; glossary sensor reports no avoided words. |
| D2 optional | CARRIED | `Pet.java:88–90`; `PetValidator.java:79–87`. |
| D3 exactly 15 digits | CARRIED | `PetValidator.java:43–44,80–82`. |
| D4 global uniqueness | CARRIED | `PetRepository.java:31–37`; all three schema changes add global uniqueness. |
| D5 no product lookup | CARRIED | Repository exposes only boolean existence queries (`PetRepository.java:25–37`); changed controller adds no lookup endpoint (`git diff HEAD -- src/main`). |
| D6 owner's page | CARRIED | `templates/owners/ownerDetails.html:57–58`. |
| D7 replacement | CARRIED | `PetController.java:188–203`; integration test lines 71–72. |
| D8 clearing and prefill | CARRIED | PCT lines 447–493; integration test lines 74–75. |
| D9 normalization | CARRIED | `Pet.java:88–90`: trim, remove literal spaces, empty becomes null. |
| D10 field errors/messages | CARRIED | `PetValidator.java:80–96`; `messages.properties:4,54`. |
| D11 no other owner's details | CARRIED | Validator uses boolean results and rejects without identifying arguments (`PetValidator.java:95–104`); PCT lines 402–423. |
| D12 named constraints and mapping | CARRIED, migration verification incomplete | Schema/script definitions and `PetController.java:125–134,160–169,211–214`; Postgres sensor failure discussed in C1. |
| D13 MySQL name constraint unchanged | CARRIED | `git diff HEAD -- src/main/resources/db/mysql/schema.sql` retains unnamed owner/name uniqueness. |
| D14 exclude self | CARRIED | `PetValidator.java:99–104`; `ClinicServiceTests.java:320–345`. |
| D15 no prefix validation | CARRIED | Only `[0-9]{15}` is checked (`PetValidator.java:44,81`). |
| D16 empty display | CARRIED | Owner controller test lines 314–324. |
| D17 single error, errors together | CARRIED | Validator lines 53–87; PCT lines 425–443,532–548. |
| D18 placement delegated to design | CARRIED, baseline conflict remains | Design Decision 4 chooses `PetRepository`; the log does not expressly reconcile A1. See C2. |
| D19 validator handles database field rejection | CARRIED | `PetController.java:126–128,161–163`; `PetValidator.java:95–96`; freeze store absent from diff. |
| D20 | SUPERSEDED | Decisions log line 26 expressly replaces it with D23. |
| D21 real H2 lifecycle test | CARRIED | `PetMicrochipNumberIntegrationTests.java:55–75`. |
| D22 wrong-pet limitation accepted | CARRIED | Boolean-only queries and anonymous error (`PetRepository.java:31–37`; validator lines 95–104). |
| D23 migration and rollback | CARRIED in scripts/design; verification incomplete | Migration scripts lines 1–6; shared migration scenario lines 60–95; C1. |
| D24 visit form excluded | CARRIED | No visit form change in `git diff HEAD -- src/main`. |
| D25 two releases | DOCUMENTED; operational completion UNKNOWN | `tasks.md:5–14` leaves release task 0.2 unchecked. The current diff combines both releases; it must be split before merging according to the task. |
| D26 no added dependency, existing database tooling | CARRIED | No `pom.xml` change; MySQL migration test lines 33–45; Postgres migration test lines 39–56. |

| Baseline item | Assessment |
|---|---|
| Requirements and glossary | **VERIFIED:** change validates: `openspec validate pc-301 --strict` returned `Change 'pc-301' is valid`. Glossary sensor reports no avoided terms (`sensors.md:83–85`). |
| A1 owner aggregate access; no pet repository | **VERIFIED departure:** new `PetRepository` contradicts the literal baseline. Design documents the choice, but the log lacks an explicit A1 exception. C2. |
| A2 validation in validator | **VERIFIED carried:** new rejections are in `PetValidator.java:82,96`; architecture sensor passes (`sensors.md:10`). |
| A3 SQL-managed schema | **VERIFIED carried:** SQL scripts supply the column; `application.properties:3–4,10–11` retains SQL initialization and disabled Hibernate DDL. |
| A4 database uniqueness | **VERIFIED carried:** existing name constraints remain; all schemas add microchip uniqueness (`git diff HEAD -- src/main/resources/db`). |
| B1 formatting/URLs | **VERIFIED sensor pass:** `sensors.md:11`. |
| B2 messages in every language | **VERIFIED:** new template text uses message keys; the diff adds both keys to all nine locale bundles and the base bundle. Full suite passes outside the separately reported Docker lane (`sensors.md:12,117–142`). |
| PC-302 known defect | **VERIFIED retained:** sensor lane records three passes without treating them as proof of resolution (`sensors.md:107–115`). |

**VERIFIED design/task assessment:** the implementation follows design Decisions 1–8, including normalization, separate new/existing queries, validator-mediated rejection, edit copying, views, and manual migration scripts. The shared migration scenario additionally tests rollback scripts and preservation of an assigned number (`MicrochipNumberMigrationScenario.java:82–95`), which supports D23/D25.

**VERIFIED task limits:** task 0.1's claimed release-only diff cannot be demonstrated by this combined uncommitted diff; task 0.2 remains unchecked. Tasks 1.5 and 6.1 remain unchecked, consistent with the supplied Docker failure (`tasks.md:9–10,22,54`). No unrelated production change was found in `git diff HEAD -- src/main`.

## 3. Sensors

- **VERIFIED — critical risk floor:** justified by protected-test wiring, persistence, schema, and concurrency changes (`sensors.md:18–70`); it is a review priority, not itself a defect.
- **VERIFIED — MySQL Docker skip:** deliberate and authorized by D23/D26. Local skipping gives no database evidence; the supplied host lane runs and passes it in both orders (`sensors.md:76,125–126,139–140`).
- **VERIFIED — broad catch:** does not swallow failures. Exceptions are collected and subsequently asserted empty (`PetClinicConcurrencyTests.java:172–174,190`).
- **VERIFIED — Postgres Docker assumption:** authorized by D23/D26, but host execution exposes C1 (`sensors.md:78,128–142`).
- **VERIFIED — protected characterization change:** only three lines add the required repository mock; no assertions are removed (`git diff HEAD -- src/test/java/.../owner/PetControllerCharacterizationTests.java`; `sensors.md:79–80`).
- **VERIFIED — glossary:** no avoided words in added lines (`sensors.md:83–85`).
- **VERIFIED — architecture:** passes the narrow controller-rejection rule; that rule does not check A1 (`ArchitectureTests.java:35–43`).
- **VERIFIED — build checks:** supplied validate pass (`sensors.md:11`); not rerun.
- **VERIFIED — ordinary suite:** 153 tests, zero failures/errors, three skips; this excludes the Docker host failure (`sensors.md:12,89,117–142`).
- **VERIFIED — mutation testing:** all 22 mutants on added lines were killed. Four survivors and three uncovered mutants are on unchanged lines; this provides no mutation evidence for SQL, templates, entity normalization, or migration tests because PIT targets only the controller and validator (`sensors.md:93–105`).
- **VERIFIED — known-defect lane:** three passes do not establish PC-302's resolution (`sensors.md:111–115`).
- **VERIFIED — Docker host lane:** alphabetical order fails the Postgres migration precondition; reverse order passes. This is an unresolved failure, not a Docker skip or evidence that the migration SQL itself fails (`sensors.md:121–142`).

## 4. Findings

**C1 — BLOCK — Postgres migration test does not reliably start from release 1**

- **Where:** [PostgresMicrochipNumberMigrationTests.java](/work/src/test/java/org/springframework/samples/petclinic/PostgresMicrochipNumberMigrationTests.java:39), lines 39–41; [MicrochipNumberMigrationScenario.java](/work/src/test/java/org/springframework/samples/petclinic/MicrochipNumberMigrationScenario.java:60), lines 60–69.
- **Claim — VERIFIED:** the required migration verification fails in the supplied alphabetical Docker run because the database already contains the new column before migration. Passing in reverse order does not satisfy task 1.5's verification.
- **Evidence:** `sensors.md:132–133`: “pets has no microchip_number column before the migration … Expecting value to be false but was true.” The scenario runs release-1 scripts and checks the precondition before executing migration.
- **Cause — INFERRED:** the two Postgres classes share the Compose service, and the start arguments do not guarantee a clean database when another cached context has already initialized it (`PostgresIntegrationTests.java:51–53`; migration test lines 39–42).
- **Required correction:** isolate the migration database and verify both class orders. Preserve the pre-migration assertion.
- **Falsification:** this finding is wrong if the supplied host results concern a different revision, or the unchanged implementation passes both orders from the same harness conditions with a demonstrably release-1 starting schema.
- **Confidence:** high for the failure; medium for the precise lifecycle cause.

**C2 — BLOCK — new pet repository lacks an explicit baseline exception**

- **Where:** [PetRepository.java](/work/src/main/java/org/springframework/samples/petclinic/owner/PetRepository.java:25), lines 25–37; `.review-inputs/project-baseline.md:3,9`; `decisions.md:24`; `design.md:48–62`.
- **Claim — VERIFIED:** A1 explicitly says there is no pet repository and pets are reached through their owner. The implementation introduces direct pet queries. Design Decision 4 explains the choice, while D18 delegates placement without expressly recording the departure from A1 required by the baseline.
- **Evidence:** A1: “There is no repository for pets or visits”; implementation: `public interface PetRepository extends Repository<Pet, Integer>`.
- **Consequence — VERIFIED:** the architecture sensor's pass cannot resolve this conflict because its rule checks only controller calls to `rejectValue` (`ArchitectureTests.java:35–43`).
- **Falsification:** this finding is wrong if an applicable logged decision explicitly authorizes the A1 exception, or the baseline owner confirms that D18 already constitutes that exception.
- **Confidence:** high for the textual departure; medium for whether D18 is sufficient authorization.

**C3 — INFORMATIONAL — scenario coverage is narrower than a completely green scenario report**

- **Where:** the PARTLY and UNTESTED rows above; especially `PetValidatorTests.java:196–230,276–284` and `PetControllerTests.java:552–610`.
- **Claim — VERIFIED:** several tests assert validator codes without asserting all scenario outcomes: rendered wording, form redisplay, or persistence behavior. The exact original three-error add combination also lacks a matching test.
- **Evidence:** the cited validator tests call `validate` directly; the constraint-handler tests assert field codes and counts without content assertions.
- **Implication — INFERRED:** shared controller and message paths appear to implement these remaining outcomes (`PetController.java:117–118,125–134,153–169`; `messages.properties:4,54`), but those outcomes should not be reported as directly tested.
- **Falsification:** this finding is wrong if additional tests assert each missing outcome for the specified inputs.
- **Confidence:** high.

## 5. For the person

- **C2:** Does D18 authorize an explicit exception to A1 for these two boolean pet queries, or should the implementation preserve owner-mediated access? The baseline forbids a pet repository; design Decision 4 deliberately introduces one (`project-baseline.md:9`; `decisions.md:24`; `design.md:48–62`).

## 6. Overall

**VERIFIED: hold this change for C1 and resolution of C2.** The H2 lifecycle, normalization, duplicate handling, clearing, and display have substantial asserted coverage, and OpenSpec validation passes. The Postgres migration test nevertheless fails in one supplied execution order, and the new repository needs reconciliation with the project baseline. **UNKNOWN:** release 1's independent merge/deployment has occurred; task 0.2 remains open. No files were changed during this review.