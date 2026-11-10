# Step 5: the sensors

Deterministic checks on the change, run before any model reviews its code. Each line is evidence a reviewer may cite.

| Sensor | Result |
|---|---|
| Risk floor | **critical** (see below) |
| Test-delta audit | 4 findings |
| Glossary check | no avoided words |
| Architecture rule | passes |
| Build checks (`./mvnw validate`, B1) | pass (formatting, `http://` URLs, Java version) |
| Full test suite, without 1 known-defect test (18 s) | 153 run, 0 failures, 0 errors, 3 skipped |
| Known-defect lane (shown, not counted) | testDuplicatePetNameRaceConditionIsBlocked (PC-302): failed 0 of 3 |
| Mutation testing, pet slice (23 s) | 83 mutants: 76 killed, 4 survived, 3 without coverage, 0 timed out |

## Risk floor

```
risk floor: critical
touches: protected-check, persistence, schema, concurrency, production-code, messages, templates, tests, docs

critical    protected-check  src/test/java/org/springframework/samples/petclinic/owner/PetControllerCharacterizationTests.java
material    concurrency      src/test/java/org/springframework/samples/petclinic/service/ClinicServiceTests.java:321  @Transactional
material    persistence      src/main/java/org/springframework/samples/petclinic/owner/Pet.java:56  @Column
material    persistence      src/main/java/org/springframework/samples/petclinic/owner/PetRepository.java:25  public interface PetRepository extends Repository<Pet, Integer> {
material    schema           src/main/resources/db/h2/data.sql
material    schema           src/main/resources/db/h2/schema.sql
material    schema           src/main/resources/db/mysql/data.sql
material    schema           src/main/resources/db/mysql/migrate-pc-301-microchip-number.sql
material    schema           src/main/resources/db/mysql/schema.sql
material    schema           src/main/resources/db/postgres/migrate-pc-301-microchip-number.sql
material    schema           src/main/resources/db/postgres/schema.sql
bounded     messages         src/main/resources/messages/messages.properties
bounded     messages         src/main/resources/messages/messages_de.properties
bounded     messages         src/main/resources/messages/messages_es.properties
bounded     messages         src/main/resources/messages/messages_fa.properties
bounded     messages         src/main/resources/messages/messages_hi.properties
bounded     messages         src/main/resources/messages/messages_ja.properties
bounded     messages         src/main/resources/messages/messages_ko.properties
bounded     messages         src/main/resources/messages/messages_pt.properties
bounded     messages         src/main/resources/messages/messages_ru.properties
bounded     messages         src/main/resources/messages/messages_tr.properties
bounded     production-code  src/main/java/org/springframework/samples/petclinic/owner/Pet.java
bounded     production-code  src/main/java/org/springframework/samples/petclinic/owner/PetController.java
bounded     production-code  src/main/java/org/springframework/samples/petclinic/owner/PetRepository.java
bounded     production-code  src/main/java/org/springframework/samples/petclinic/owner/PetValidator.java
bounded     templates        src/main/resources/templates/owners/ownerDetails.html
bounded     templates        src/main/resources/templates/pets/createOrUpdatePetForm.html
bounded     tests            src/test/java/org/springframework/samples/petclinic/MicrochipNumberMigrationScenario.java
bounded     tests            src/test/java/org/springframework/samples/petclinic/MySqlMicrochipNumberMigrationTests.java
bounded     tests            src/test/java/org/springframework/samples/petclinic/PetClinicConcurrencyTests.java
bounded     tests            src/test/java/org/springframework/samples/petclinic/PetMicrochipNumberIntegrationTests.java
bounded     tests            src/test/java/org/springframework/samples/petclinic/PostgresMicrochipNumberMigrationTests.java
bounded     tests            src/test/java/org/springframework/samples/petclinic/owner/OwnerControllerTests.java
bounded     tests            src/test/java/org/springframework/samples/petclinic/owner/PetControllerTests.java
bounded     tests            src/test/java/org/springframework/samples/petclinic/owner/PetTests.java
bounded     tests            src/test/java/org/springframework/samples/petclinic/owner/PetValidatorTests.java
bounded     tests            src/test/java/org/springframework/samples/petclinic/service/ClinicServiceTests.java
bounded     tests            src/test/resources/pc-301-release-1/mysql/data.sql
bounded     tests            src/test/resources/pc-301-release-1/mysql/schema.sql
bounded     tests            src/test/resources/pc-301-release-1/postgres/data.sql
bounded     tests            src/test/resources/pc-301-release-1/postgres/schema.sql
mechanical  docs             GLOSSARY.md
mechanical  docs             openspec/changes/pc-301/decisions.md
mechanical  docs             openspec/changes/pc-301/design.md
mechanical  docs             openspec/changes/pc-301/proposal.md
mechanical  docs             openspec/changes/pc-301/specs/owner-details/spec.md
mechanical  docs             openspec/changes/pc-301/specs/pets/spec.md
mechanical  docs             openspec/changes/pc-301/tasks.md
mechanical  docs             openspec/specs/pets/spec.md
```

## Test-delta audit

```
src/test/java/org/springframework/samples/petclinic/MySqlMicrochipNumberMigrationTests.java:33: skip added: @Testcontainers(disabledWithoutDocker = true)
src/test/java/org/springframework/samples/petclinic/PetClinicConcurrencyTests.java:172: broad catch added: catch (Exception e) {
src/test/java/org/springframework/samples/petclinic/PostgresMicrochipNumberMigrationTests.java:51: skip added: assumeTrue(DockerClientFactory.instance().isDockerAvailable(), "Docker not available");
src/test/java/org/springframework/samples/petclinic/owner/PetControllerCharacterizationTests.java:79: protected check: modified, 3 lines added, 0 removed
summary: tests in changed files 82 -> 127; assertion lines added 138, removed 0, moved 0; findings 4
```

## Glossary check

No avoided word in the added lines.

## Full test suite

Not run (no Docker): PostgresMicrochipNumberMigrationTests (0 run), PostgresIntegrationTests (0 run), MySqlIntegrationTests (2 skipped), MySqlMicrochipNumberMigrationTests (1 skipped). Not run is not passed.

## Mutation testing: survivors and mutants without coverage

PIT's set-up is the pom's: `PetController` and `PetValidator`, tested by `owner.Pet*Tests`.

On lines the change adds: 22 mutants, 22 killed, 0 survived, 0 without coverage.

| Status | Class | Method | Line | In the change | Mutation |
|---|---|---|---|---|---|
| NO_COVERAGE | PetController | lambda$findOwner$0 | 72 | no | replaced return value with null for org/springframework/samples/petclinic/owner/PetController::lambda$findOwner$0 |
| NO_COVERAGE | PetController | lambda$findPet$1 | 86 | no | replaced return value with null for org/springframework/samples/petclinic/owner/PetController::lambda$findPet$1 |
| NO_COVERAGE | PetController | updatePetDetails | 201 | no | removed call to org/springframework/samples/petclinic/owner/Owner::addPet |
| SURVIVED | PetController | populatePetTypes | 66 | no | replaced return value with Collections.emptyList for org/springframework/samples/petclinic/owner/PetController::populatePetTypes |
| SURVIVED | PetController | initOwnerBinder | 93 | no | removed call to org/springframework/web/bind/WebDataBinder::setDisallowedFields |
| SURVIVED | PetController | initCreationForm | 105 | no | removed call to org/springframework/samples/petclinic/owner/Owner::addPet |
| SURVIVED | PetController | updatePetDetails | 190 | no | removed call to org/springframework/util/Assert::state |

## Known-defect tests

Tests tied to an open ticket (`known-defect-tests.txt`). They are left out of the full suite above and run here on their own, with their whole class as the suite runs them. Their result is shown here and in the packet; it does not decide the build.

| Test | Ticket | Runs | Failed | Passed | Not found |
|---|---|---|---|---|---|
| `PetClinicConcurrencyTests#testDuplicatePetNameRaceConditionIsBlocked` | PC-302 | 3 | 0 | 3 | 0 |

A test that passed in every run may mean its defect is fixed, or only that the timing hid it this time. Its ticket closes on evidence, not on one green lane.

## Docker tests (host)

Run on the presenter's machine by the harness, not by an agent; openjdk version "25.0.1" 2025-10-21; Docker 28.4.0. Twice, in opposite class orders.

**alphabetical** (32 s, build exit 1). Order run: MySqlIntegrationTests → MySqlMicrochipNumberMigrationTests → PostgresIntegrationTests → PostgresMicrochipNumberMigrationTests.

| Class | Run | Passed | Failed | Skipped |
|---|---|---|---|---|
| MySqlIntegrationTests | 2 | 2 | 0 | 0 |
| MySqlMicrochipNumberMigrationTests | 1 | 1 | 0 | 0 |
| PostgresIntegrationTests | 2 | 2 | 0 | 0 |
| PostgresMicrochipNumberMigrationTests | 1 | 0 | 1 | 0 |

Failures:

- `PostgresMicrochipNumberMigrationTests.migrationAddsMicrochipNumberToReleaseOneTable`: [pets has no microchip_number column before the migration] 
Expecting value to be false but was true

**reversealphabetical** (54 s, build exit 0). Order run: PostgresMicrochipNumberMigrationTests → PostgresIntegrationTests → MySqlMicrochipNumberMigrationTests → MySqlIntegrationTests.

| Class | Run | Passed | Failed | Skipped |
|---|---|---|---|---|
| MySqlIntegrationTests | 2 | 2 | 0 | 0 |
| MySqlMicrochipNumberMigrationTests | 1 | 1 | 0 | 0 |
| PostgresIntegrationTests | 2 | 2 | 0 | 0 |
| PostgresMicrochipNumberMigrationTests | 1 | 1 | 0 | 0 |
