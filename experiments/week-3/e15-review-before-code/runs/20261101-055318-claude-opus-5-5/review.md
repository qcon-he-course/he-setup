I checked all 26 decisions and found nothing that blocks the change. One task needs rewording before anyone codes it: as written, the migration tests could pass without testing the migration.

**Scope of the check.** I read every file in `openspec/changes/pc-301/`, the baseline `openspec/specs/pets/spec.md`, `GLOSSARY.md`, and the code and tests the design names. I ran `openspec validate pc-301 --strict`, which only checks the format. I did not run any `./mvnw` tests. For `ArchitectureTests` I rely on the harness probe you gave me.

## 1. Decisions

| # | Verdict | Where |
|---|---|---|
| D1 Term is "microchip number" | CARRIED | In the glossary. `grep -rniE "transponder\|chip id\|(^\|[^o])chip number"` over the change only finds D1 quoting the words to avoid (VERIFIED) |
| D2 Optional on both forms | CARRIED | spec "Microchip number is optional"; proposal:9 |
| D3 Exactly 15 digits | CARRIED | spec "is exactly 15 digits"; design Decision 3 |
| D4 Unique across all owners | CARRIED | spec "unique across all pets", scenario "A number held by another owner's pet" |
| D5 No lookup | CARRIED | proposal:20; design non-goals |
| D6 Shown on the owner's page | CARRIED | `specs/owner-details/spec.md` |
| D7 Edit accepts a new number | CARRIED | spec "A pet's microchip number can be changed" |
| D8 Empty field clears it; edit form shows the stored number | CARRIED | spec "Clearing…", "The edit form shows the stored microchip number"; design Decision 6 |
| D9 Trim, remove spaces, store the digits, nothing else removed | CARRIED | spec "is stored as its digits"; design Decision 2 |
| D10 The two error texts, on the field | CARRIED | spec text; design Decisions 3–4 |
| D11 Duplicate error names nobody | CARRIED | spec "unique across all pets" (line 74, line 81) |
| D12 Named constraint on all three databases, reported on the field | CARRIED | spec "Duplicate microchip numbers caught by the database"; design Decision 5 |
| D13 MySQL name constraint out of scope | CARRIED | proposal:20; design non-goals |
| D14 Own number never conflicts | CARRIED | spec "A pet keeps its own microchip number"; design Decision 4 (`AndIdNot`) |
| D15 Prefix not checked | CARRIED | spec "exactly 15 digits" (SHALL NOT check), scenario "Any first three digits" |
| D16 Label shown with an empty value | CARRIED | owner-details spec |
| D17 One error per field, reported with the other errors | CARRIED | spec "One microchip number error at a time"; the MODIFIED "Validation errors are reported together" |
| D18 Where the check goes is a design choice | CARRIED | design Decision 4 |
| D19 Database duplicate goes through a `PetValidator` method; no new controller `rejectValue` | CARRIED | design Decision 5; task 4.1, task 4.3 |
| D20 (replaced by D23) | Correctly superseded | Only its known gap is kept (design Risks:138) |
| D21 One H2 test for add / edit / clear / rejected edit | CARRIED | task 3.5 |
| D22 Wrong-pet case accepted | CARRIED | proposal:24; design Risks:142 |
| D23 + D25 Migration scripts, two releases, order, rollback | CARRIED | proposal:17–18; design Decision 8; tasks section 0, 1.5 |
| D24 No visit form | CARRIED | proposal:20; tasks follow-up |
| D26 No new dependency for the migration tests | CARRIED | task 1.5; design Risks:139 |

**Scope the author added.** None. Every piece of work traces to a decision or to something the code requires:
- `PetRepository`: F6 says `PetValidator` has no repository access.
- Release-1 column lists: D25 and F12.
- The message key for the label: D16.
- The `@MockitoBean` additions: `PetController`'s constructor changes, and both `@WebMvcTest(value = PetController.class…)` classes load it (`PetControllerTests.java:51`, `PetControllerCharacterizationTests.java:56`).

**Log's Open section.** It says "None on PC-301's frontier". Both follow-up tickets are in the tasks' Workflow follow-up.

**Questions in the ticket that nothing answers.** None. "So we can identify a pet when it is scanned" is moved to the lookup ticket (D5), and its effect is accepted in D22.

**Spec checks.**
- `openspec validate pc-301 --strict` → `Change 'pc-301' is valid` (VERIFIED). That only checks the format.
- Both MODIFIED requirements restate every baseline scenario. Nothing ADDED contradicts any other baseline requirement (VERIFIED by reading `openspec/specs/pets/spec.md` against the delta).

**Task coverage.** Every requirement has a task that shows it working, and each of those tasks has a check (VERIFIED by reading `tasks.md` against both specs).

## 2. Findings

**R1. AUTO-FIX+REVERIFY: the migration tests can run against a database that already has the new schema**
- **Where:** `tasks.md:22` (task 1.5).
- **Claim:** Task 1.5 tells the tests to follow `MySqlIntegrationTests` and `PostgresIntegrationTests`. Those tests boot the app with the `mysql` or `postgres` profile, where `spring.sql.init.mode=always`. So the release-2 `schema.sql` runs before the test body does. The test's "create `pets` from the release-1 schema" then hits `CREATE TABLE IF NOT EXISTS` and is skipped, which means the migration runs on a table that already has the column.
  - On Postgres every statement in the script is `IF NOT EXISTS`, so the script does nothing and the test still passes. It would prove nothing about migrating an old table.
  - On MySQL, `ADD COLUMN` fails because the column already exists.
- **Evidence:**
  - `MySqlIntegrationTests.java:41-43`: `@SpringBootTest` with `@ActiveProfiles("mysql")`.
  - `PostgresIntegrationTests.java:51-53`: `@SpringBootTest` with `@ActiveProfiles("postgres")`.
  - `application-mysql.properties:7` and `application-postgres.properties:7`: `spring.sql.init.mode=always`.
  - Old-style table creation: `db/postgres/schema.sql:36` and `db/mysql/schema.sql:38` use `CREATE TABLE IF NOT EXISTS pets`.
  - Planned Postgres script: design:107, `ADD COLUMN IF NOT EXISTS … CREATE UNIQUE INDEX IF NOT EXISTS`.
- **Fix:** Task 1.5 should say that Spring's SQL init must not run before the old schema is created (for example `spring.sql.init.mode=never`, or plain JDBC against the container). It should also add a check, before the script runs, that `pets` has no `microchip_number` column. That check catches the problem mechanically.
- **Falsification:** This finding is wrong if a migration test built by following those two classes leaves `pets` without `microchip_number` until the script runs.
- **Confidence:** medium. The mechanism is VERIFIED from the files. That an implementer would copy the profile setup is INFERRED.

**R2. INFORMATIONAL: D19 passes the architecture rule because of where the call sits**
- **Where:** design Decision 5; `ArchitectureTests.java:36-43`.
- **Claim:** The rule only flags direct calls to `Errors.rejectValue` from classes annotated `@Controller`. A `PetValidator` method that the controller's `catch` calls is not flagged.
  - That matches D19 and the rule's stated reason ("so the add and edit forms share one rule"): both handlers share the method.
  - Unlike the rejected `@ControllerAdvice` option, the call stays in the validator class.
- **Evidence:**
  - The rule's predicate: `call.getName().equals("rejectValue") && call.getTargetOwner().isAssignableTo(Errors.class)`, applied to `areAnnotatedWith(Controller.class)`.
  - The harness probe shows that a direct extra call in `processCreationForm` fails the rule ("was violated (1 times)") and that today's code passes. That confirms F11.
  - The freeze store holds exactly four `PetController` entries (`archunit_store/1cbfc1d1-…:3-6`).
  - That the D19 design itself passes is INFERRED, not run. Task 4.3 checks it.
- **Falsification:** This finding is wrong if ArchUnit's `callMethodWhere` also follows calls made indirectly through other methods.
- **Confidence:** high.

**R3. INFORMATIONAL: "Nothing in the app enforces the order" is only true on MySQL**
- **Where:** design Risks:135.
- **Claim:** On Postgres, release 2's `schema.sql` would run `CREATE UNIQUE INDEX IF NOT EXISTS unique_pet_microchip_number ON pets (microchip_number)` on every start. On an unmigrated table that statement should fail, so startup stops early. MySQL has no equivalent guard, because its constraint sits inside a skipped `CREATE TABLE`.
- **Evidence:** design:70 and :121 for the planned statements; `db/mysql/schema.sql:38` for `CREATE TABLE IF NOT EXISTS`. The Postgres failure itself is INFERRED, not run.
- **Falsification:** This finding is wrong if Postgres accepts `CREATE UNIQUE INDEX` on a column that does not exist.
- **Confidence:** medium.

**R4. INFORMATIONAL: in task 3.2, "Saving a pet with its own number" passes even if the own-number rule is broken**
- **Where:** `tasks.md:33`.
- **Claim:** In `@WebMvcTest`, the mocked `PetRepository` returns `false` from both `exists…` methods by default. So this controller test passes whichever query the validator calls.
- **Why it changes nothing here:** The rule is still covered by task 2.2, which uses a mock and can check which method is called, and by task 1.3, which runs the real queries on H2.
- **Evidence:** `tasks.md:27`, `tasks.md:20`.
- **Falsification:** This finding is wrong if task 3.2 stubs the repository so that the wrong query would return `true`.
- **Confidence:** high.

**R5. INFORMATIONAL: the baseline's Purpose excludes GET forms, and only a manual archive step deals with it**
- **Where:** baseline `openspec/specs/pets/spec.md:5`; the ADDED requirement "The edit form shows the stored microchip number".
- **Claim:** The change says so itself (proposal:38, tasks follow-up:59). Strict validation passes anyway. A related point is UNKNOWN: whether OpenSpec keeps the `## Purpose` section written in the new `owner-details` delta when it archives.
- **Falsification:** This finding is wrong if archiving updates the Purpose automatically.
- **Confidence:** high for the conflict; UNKNOWN for how archiving handles it.

**Design claims I checked and found correct (VERIFIED):**
- Validator wiring (`PetController.java:93-97`).
- Pet id cannot be bound, and the edit form's `pet` is the owner's own pet (`:74-86`, `:96`).
- Fields copied on edit (`:177-191`).
- Constraint-name match ignores case (`:193-196`).
- `open-in-view=false` and `ddl-auto=none` (`application.properties:10-11`).
- `spring.sql.init` only reads `schema.sql` and `data.sql` (`application.properties:3-4`).
- How the i18n sync test works (`I18nPropertiesSyncTest.java:112-127`).
- `PetValidatorTests.java:59` builds the validator with no arguments (`new PetValidator()`).
- Seed inserts: H2 and MySQL insert pets by position (`db/h2/data.sql:36-48`, `db/mysql/data.sql:36-48`); Postgres names its columns.
- The existing messages (`messages.properties:4,34`).
- The race test's template counts any failure loosely (`PetClinicConcurrencyTests.java:86-95`).

## 3. For the person

None of the findings needs a decision. R1 is a change to the wording of task 1.5 that a check can confirm. R2–R5 are informational.
