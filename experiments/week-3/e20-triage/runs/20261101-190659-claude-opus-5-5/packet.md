# For the person: PC-301, triage

| | |
|---|---|
| Eligible to merge | **no**: 2 open BLOCK; failing: PostgresMicrochipNumberMigrationTests |
| Risk floor | **critical**; sign-off: a named owner of each critical surface |
| Test suite | 153 run, 0 failures, 0 errors, 3 skipped; 3 classes passed on the host in 2 test orders; failed on the host: PostgresMicrochipNumberMigrationTests |
| Not run | PostgresMicrochipNumberMigrationTests (0 run) |
| Known-defect tests (shown, not counted) | PC-302: failed 0 of 3 runs |
| Findings | 19 reported, merged into 16: 2 BLOCK, 1 DISCUSS, 1 AUTO-FIX+REVERIFY, 12 INFORMATIONAL |
| Doubt theater | 4 of 4 substantial findings lead to a question, a fix or a task; 0 overruled with a reason |

## What the change does, from its spec

- pets: added "Microchip number is optional"
- pets: added "Microchip number is stored as its digits"
- pets: added "Microchip number is exactly 15 digits"
- pets: added "Microchip number is unique across all pets"
- pets: added "A pet keeps its own microchip number"
- pets: added "A pet's microchip number can be changed"
- pets: added "Clearing the microchip number on the edit form removes it"
- pets: added "The edit form shows the stored microchip number"
- pets: added "One microchip number error at a time"
- pets: added "Duplicate microchip numbers caught by the database"
- pets: modified "Duplicate names caught by the database"
- pets: modified "Validation errors are reported together"
- owner-details: added "The owner's page shows each pet's microchip number"

## Questions for you

**T1. Postgres migration test depends on test order: after PostgresIntegrationTests it never starts from a release-1 database** (BLOCK; review-step6-claude-opus-5-5:C1, review-step6-gpt-6.1-sol:C1)

The Postgres migration test failed in the alphabetical Docker run ('pets has no microchip_number column before the migration ... Expecting value to be false but was true', build exit 1) and passed in reverse order. How should it get a fresh release-1 database whatever ran before it: spring.docker.compose.start.skip=never, a separate compose service or project, or a schema created and dropped inside the test? Whichever you choose, D23's Postgres evidence counts only once the test passes with Docker in both class orders.

Evidence: sensors.md:121-133; src/test/java/org/springframework/samples/petclinic/PostgresMicrochipNumberMigrationTests.java:39-41; src/test/java/org/springframework/samples/petclinic/MicrochipNumberMigrationScenario.java:62-63

**T2. New PetRepository departs from baseline A1 and no decision in the log records it** (BLOCK; review-step6-claude-opus-5-5:C3, review-step6-gpt-6.1-sol:C2)

Baseline A1 says 'There is no repository for pets or visits', and a departure needs a decision in the log (project-baseline.md:3,9). PetRepository (PetRepository.java:25) adds two read-only exists queries for the uniqueness check, and writes still go through OwnerRepository.saveAndFlush. Only design.md:48-62 justifies it. D18 hands placement to the design without naming A1, and D19 does not mention a repository. Should a decision be added to the log that records this departure, should baseline A1 change, or should the check go through the owner instead?

Evidence: src/main/java/org/springframework/samples/petclinic/owner/PetRepository.java:25; .review-inputs/project-baseline.md:3,9; openspec/changes/pc-301/decisions.md:24-25; openspec/changes/pc-301/design.md:48-62

**T3. Release 1 (seed-insert column lists) and release 2 are in one working tree, against D25's two releases** (DISCUSS; review-step6-claude-opus-5-5:C2)

D25 requires release 1 (only the column lists in db/h2/data.sql and db/mysql/data.sql) to be merged and released on its own before any release-2 task is merged, so that a rollback has a target that starts on the migrated MySQL table. Task 0.2 is unticked, and the uncommitted diff holds both releases. Will release 1 be split out and shipped first, or has it already shipped somewhere this clone cannot show?

Evidence: openspec/changes/pc-301/tasks.md:5,10; openspec/changes/pc-301/decisions.md:31 (D25); git diff HEAD --stat

## Blocking

- **T1** Postgres migration test depends on test order: after PostgresIntegrationTests it never starts from a release-1 database
- **T2** New PetRepository departs from baseline A1 and no decision in the log records it

## Nobody could verify

- PostgresMicrochipNumberMigrationTests: 0 run in the agent-run suite (no Docker). In the host Docker lane it failed in alphabetical order and passed in reverse order, so D23 on Postgres is not evidenced (T1)
- PostgresIntegrationTests (0 run), MySqlIntegrationTests (2 skipped) and MySqlMicrochipNumberMigrationTests (1 skipped) did not run in the agent-run suite. They are evidenced only by the host Docker lane (sensors.md:117-142)
- Duplicate microchip numbers on MySQL and Postgres through the forms (scenario 21 and the database catch path): untested, a known gap recorded with D20 and in the design's Risks
- Task 6.1 (full ./mvnw test with Docker): not passed in both orders
- Whether release 1 has already been released on its own (D25, task 0.2): UNKNOWN
- Scenario 11, THEN 3 (the page names neither the other pet nor its owner): the assertion cannot fail (T6). It holds in the code only by inference
- Scenarios 7-10 at the form (saved or not saved, form shown again) and the original three-error add combination: no test (T5)
- That release 2 refuses to start on an unmigrated Postgres table (T10): INFERRED, not run
- Mutation testing covers only PetController and PetValidator. The SQL scripts, templates and Pet's normalising setter have no mutation evidence

## Known defects

- PC-302: two pets added to one owner at the same moment can lose one (A1's save-the-owner pattern). testDuplicatePetNameRaceConditionIsBlocked runs in the known-defect lane and passed 3 of 3 this time, which does not show the defect is fixed (sensors.md:107-115)
- `PetClinicConcurrencyTests#testDuplicatePetNameRaceConditionIsBlocked` (PC-302) runs in the known-defect lane, outside the build: failed 0 of 3 runs; it passed in every run of the lane, which may mean only that the timing hid it. It does not count toward eligibility while PC-302 is open.

## Carried elsewhere

- T4 (AUTO-FIX+REVERIFY): Step 3: the migration tests could run against a database that already has the new schema (task 1.5 wording). The fix R1 asked for is in the code. Spring's SQL init is off (PostgresMicrochipNumberMigrationTests.java:41, 'spring.sql.init.mode=never'), and the scenario checks there is no microchip_number column before the migration (MicrochipNumberMigrationScenario.java:63). That check is what fails in T1, from a different cause (a reused container). The reverification is carried by T1.
- T12 (INFORMATIONAL): The baseline's Purpose excludes the GET forms; only a manual archive step deals with it. Carried as a workflow follow-up with its own check in tasks.md:59-60. Whether archiving keeps the delta's Purpose is UNKNOWN.

## Logged

- T5 (INFORMATIONAL, logged): Scenario coverage is narrower than the scenario list: scenarios 7-10 and some rendered outcomes are tested only at the validator or by error code. Reason: VERIFIED by both reviews: for scenarios 7-10 (any first three digits, 14 and 16 digits, the 10-character non-ISO number) only PetValidatorTests calls validate, with no controller test for those inputs. GPT also notes that the constraint-handler tests (PetControllerTests 552-610) do not check the rendered message, and that the original three-error add combination has no matching test. INFERRED: the shared hasErrors() path covers these outcomes. Adding controller cases would close the gap.
- T6 (INFORMATIONAL, logged): The 'Leo'/'Franklin' assertions in addWithNumberOfAnotherOwnersPetShowsOnlyIsAlreadyInUse cannot fail. Reason: VERIFIED: the fixture holds an unnamed owner with 'petty' and 'doggy' and the type 'hamster' (PetControllerTests.java:85-98), so neither name can appear on the page. The test's comment breaks off mid-sentence (lines 416-418). This contradicts step6-gpt's MET for scenario 11. D11 still holds in the code and in PetValidatorTests' assertion that the error has no arguments.
- T7 (INFORMATIONAL, logged): Task ticks 1.5 and 6.1 don't match the evidence. Reason: VERIFIED: tasks.md:22 (1.5) and :54 (6.1) are unticked although the files of 1.5 exist. Leaving them open is consistent with T1: with Docker, 1.5's check fails in one class order.
- T8 (INFORMATIONAL, logged): The baseline spec openspec/specs/pets/ is untracked and enters the repository with this change. Reason: VERIFIED: git ls-files openspec lists only changes/archive/.gitkeep, config.yaml and specs/.gitkeep.
- T9 (INFORMATIONAL, logged): D19 passes the architecture rule because of where the rejectValue call sits. Reason: The rule only flags direct rejectValue calls from @Controller classes. The architecture sensor passes on the implemented code with the freeze store unchanged.
- T10 (INFORMATIONAL, logged): 'Nothing in the app enforces the order' is only true on MySQL. Reason: VERIFIED that design.md:135 still says it. That Postgres startup fails on an unmigrated table is INFERRED and has not been run.
- T11 (INFORMATIONAL, overruled): Step 3: the 'Saving a pet with its own number' controller test would pass with the wrong query. Reason: R4's own falsification condition is met. The implemented test stubs the query that does not exclude the pet to return true: 'given(pets.existsByMicrochipNumber(anyString())).willReturn(true);' (line 500). It then verifies existsByMicrochipNumberAndIdNot (line 510), so the wrong query fails the test.
- T13 (INFORMATIONAL, logged): Sensor: skip added in MySqlMicrochipNumberMigrationTests (@Testcontainers(disabledWithoutDocker = true)). Reason: Disposition set by the clerk. The skip follows the existing pattern that task 1.5 and D26 require. With Docker, the test ran and passed in both class orders (sensors.md:126,140).
- T14 (INFORMATIONAL, logged): Sensor: broad catch added in PetClinicConcurrencyTests. Reason: Disposition set by the clerk. VERIFIED: the catch collects exceptions (line 173), and the test then asserts 'assertThat(exceptions).isEmpty()' (line 190), so no failure is hidden.
- T15 (INFORMATIONAL, logged): Sensor: skip added in PostgresMicrochipNumberMigrationTests (assumeTrue Docker available). Reason: Disposition set by the clerk. The skip copies PostgresIntegrationTests.java:68, as task 1.5 and D26 require. The skip itself is not a defect. What it hides in the agent-run suite (0 run) is the failure with Docker, which is T1.
- T16 (INFORMATIONAL, logged): Sensor: protected check PetControllerCharacterizationTests modified (3 lines added). Reason: Disposition set by the clerk. VERIFIED by git diff HEAD: the only change is '@MockitoBean private PetRepository pets;', which the new PetController constructor needs (task 3.1). No assertion is added, removed or changed. The critical risk floor this triggers is for the policy to apply.

## Audit

Every one of the 19 reported findings is accounted for, and every merged finding appears above.
