# PetClinic project baseline: architecture and conventions

What every change to `he-petclinic` is held to, beyond the spec of the slice it touches. Assembled on 1 November from Week 1's verified facts (`course/week-1/experiments/e5-require-evidence/AGENTS.md`) and Week 2's architecture rule, and re-checked against `week-3-start` (76adfc4); every line cites the code. A change that departs from a line here needs a decision in its log that says so, and a reviewer reports a departure without one.

Requirements live in `openspec/specs/` (so far only `pets`, from step 1) and the project's words in `GLOSSARY.md`.

## Architecture

- **A1. Pets and visits are reached through their owner.** There is no repository for pets or visits: the repositories are `OwnerRepository`, `PetTypeRepository` and `VetRepository`. `PetController` and `VisitController` load the `Owner` through `OwnerRepository`, change its pets or visits, and save the owner; JPA cascades from `Owner.pets` to `Pet.visits` write the rows. (`owner/Owner.java:67-70`, `owner/Pet.java:56`, `owner/PetController.java:120, 190`, `owner/VisitController.java:109`)
- **A2. Field validation belongs in the form's validator, not the controller.** Enforced by the frozen ArchUnit rule `controllersLeaveFieldValidationToValidators`: no `@Controller` calls `Errors.rejectValue`; the four existing calls in `PetController` are frozen in `src/test/resources/archunit_store/`, and a new one fails the build. (`ArchitectureTests.java:36-43`; Week 2)
- **A3. The schema comes from SQL scripts, not from Hibernate.** `spring.sql.init` runs `db/${database}/schema.sql` and `data.sql` (H2 by default; `mysql` and `postgres` profiles); `ddl-auto=none`, `open-in-view=false`. There is no migration tool. (`application.properties:2-4, 10-11`)
- **A4. Uniqueness is enforced by the database as well as the code.** All three schemas have a unique constraint on owner and pet name: H2's and Postgres's are named `unique_owner_pet_name`, Postgres's on `LOWER(name)`; MySQL's is unnamed. In H2 the name column is `VARCHAR_IGNORECASE`. (`db/h2/schema.sql:48, 55`, `db/postgres/schema.sql:45`, `db/mysql/schema.sql:47`)

## Conventions the build enforces

- **B1. Formatting and URLs.** `./mvnw verify` fails on unformatted code (`spring-javaformat`) and on any plain `http://` URL (nohttp checkstyle). (`pom.xml:213, 235-248`)
- **B2. No hard-coded text, and every message key in every language.** `I18nPropertiesSyncTest` fails if a template has hard-coded text or a key is missing from a `messages_*.properties` file. (`system/I18nPropertiesSyncTest.java:40, 87`)

## Known defects

- **PC-302.** Two pets added to one owner at the same moment can lose one; the existing race test passes or fails by timing (`course/week-3/PC-302.md`). It sits in A1's save-the-owner pattern. Its test (`twoSimultaneousAddsWithTheSameName` from step 8's base on; `testDuplicatePetNameRaceConditionIsBlocked` before) runs in step 5's known-defect lane (`known-defect-tests.txt`), outside the build, while the ticket is open.

## Where this should live

In a real team this file is committed to the repository and read by every agent and reviewer. Here it is course material: `demo.sh` gives it to the reviewers in e15 and e19 as `.review-inputs/project-baseline.md`, because the class clone is pinned at `week-3-start` and every stored run starts from that commit. Committing it to `he-petclinic` is the homework's version.
