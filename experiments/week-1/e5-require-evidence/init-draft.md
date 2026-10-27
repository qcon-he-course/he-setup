# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

Spring PetClinic: a Spring Boot + Thymeleaf + Spring Data JPA sample app. Java 17+. Builds with either Maven (`./mvnw`, primary) or Gradle (`./gradlew`); CI runs both.

## Commands

```bash
./mvnw spring-boot:run                 # run on http://localhost:8080 (H2 in-memory by default)
./mvnw verify                          # full build: format validation, checkstyle (nohttp), tests
./mvnw test -Dtest=OwnerControllerTests            # single test class
./mvnw test -Dtest=OwnerControllerTests#testMethod # single test method
./mvnw spring-javaformat:apply         # fix formatting (the build fails on unformatted code)
./mvnw package -P css                  # recompile src/main/scss -> static/resources/css/petclinic.css
./mvnw spring-boot:build-image         # container image (there is no Dockerfile)

./gradlew bootRun / ./gradlew build / ./gradlew test --tests '*OwnerControllerTests'
```

Run against a real database by activating a profile and starting its container from `docker-compose.yml` (service names match the profile names):

```bash
docker compose up postgres && ./mvnw spring-boot:run -Dspring-boot.run.profiles=postgres
docker compose up mysql    && ./mvnw spring-boot:run -Dspring-boot.run.profiles=mysql
```

## Formatting and lint

- Code must match `spring-javaformat` (tabs, Spring style); `validate` runs in the Maven build, so run `spring-javaformat:apply` before building after edits.
- The nohttp checkstyle rule scans **all files** in the repo and fails on plain `http://` URLs; use `https://` (suppressions in `src/checkstyle/nohttp-checkstyle-suppressions.xml`).
- `.editorconfig` defines whitespace per file type.
- Commits require a DCO `Signed-off-by` trailer.

## Architecture

Package-by-feature under `org.springframework.samples.petclinic`:

- `model/` – `BaseEntity` (id) → `NamedEntity` (name) / `Person` (first/last name) mapped superclasses.
- `owner/` – the core aggregate. `Owner` owns `Pet`s, and `Pet` owns `Visit`s (both `@OneToMany(cascade = ALL, fetch = EAGER)`). There are no Pet/Visit repositories: `PetController` and `VisitController` load the `Owner` via `OwnerRepository`, mutate its pets/visits, and save the owner. `PetTypeFormatter` converts form strings to `PetType`; `PetValidator` is registered via `@InitBinder` for custom validation.
- `vet/` – read-only vets list, served as HTML and as JSON/XML (`Vets` wrapper). `VetRepository` results are cached in the JCache `vets` cache (`system/CacheConfiguration`, Caffeine provider).
- `system/` – welcome page, `CrashController` (intentionally throws to demo the error page), web config including locale switching via `?lang=`.
- Repositories are Spring Data `JpaRepository` interfaces; owner search is paginated (`findByLastNameStartingWith`).
- `PetClinicRuntimeHints` supplies GraalVM native-image hints.

Resources:

- `application.properties` sets `database=h2`; the `mysql`/`postgres` profiles override `database` and the datasource. Schema/data load from `db/${database}/schema.sql` and `data.sql` — schema changes must be made in all three of `db/h2`, `db/mysql`, `db/postgres`.
- Views are Thymeleaf templates in `templates/`, sharing `fragments/layout.html` and the form-field fragments `inputField.html`/`selectField.html`.
- UI strings live in `messages/messages*.properties`. `I18nPropertiesSyncTest` fails if a key is missing from any locale file or if templates contain hard-coded text, so add new keys to every `messages_*.properties` file.

## Tests

- Controller tests use `@WebMvcTest` with mocked repositories; `ClinicServiceTests` uses `@DataJpaTest` against H2.
- `PetClinicIntegrationTests` (H2), `MySqlIntegrationTests` (Testcontainers) and `PostgresIntegrationTests` (Docker Compose via `spring-boot-docker-compose`) boot the full app; the MySQL/Postgres ones need Docker and are skipped when it isn't available. Their `main()` methods (plus `MysqlTestApplication`) can be run from an IDE as dev launchers against each database.
