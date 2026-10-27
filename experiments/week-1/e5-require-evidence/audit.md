# Audit of the `/init` draft

The draft is `init-draft.md`: `/init` on Opus 5.5, rung 0's floor, on 18 October at 21:17 local time. Every claim was checked against seeded PetClinic at `b107a86` on 18 October; the running app's checks are in `../reference/app-check-b107a86.md`.

**Tags.** Verified: the code holds it. Inferred: advice or a guess the code doesn't settle. Wrong: the code says otherwise. Copied: the README already says it.

**The three tests.** Keep a line only if it is verified, the agent couldn't find it in seconds, and the README doesn't already say it. A wrong line may be replaced by the verified fact and its evidence.

| # | Draft claim | Tag | Kept? | Why, and the evidence |
|---|---|---|---|---|
| 1 | Spring Boot, Thymeleaf, Spring Data JPA sample; Java 17+ | Verified | No | Found in seconds (`pom.xml:19`) |
| 2 | Maven primary, Gradle too; CI runs both | Verified | No | Found in seconds (`.github/workflows/maven-build.yml`, `gradle-build.yml`); the README gives both builds (lines 28, 33) |
| 3 | `./mvnw spring-boot:run`, H2 in memory by default | Verified | **Yes, rewritten** | The README says PostgreSQL is the default (line 71), and it is wrong: `application.properties:2-4`, H2 on the classpath (`pom.xml:76-80`), confirmed in the running app. Merged with 24 |
| 4 | `./mvnw verify` runs format validation, nohttp checkstyle and the tests | Verified | **Yes** | Not in the README; a build that fails on formatting is costly to discover (`pom.xml:207-212, 220-245`). Merged with 11 and 12 |
| 5 | Single test class or method with `-Dtest=` | Verified | No | Standard Maven, found in seconds |
| 6 | `./mvnw spring-javaformat:apply` fixes formatting | Verified | **Yes** | Part of 4 |
| 7 | `./mvnw package -P css` recompiles the CSS | Verified | No | Copied: README line 111 (`pom.xml:324`) |
| 8 | `spring-boot:build-image`; there is no Dockerfile | Verified | No | Copied: README lines 45-48 |
| 9 | The Gradle commands | Verified | No | Standard Gradle, found in seconds |
| 10 | Real database: `docker compose up postgres` with the `postgres` profile, and the same for MySQL | Verified | No | Copied: README lines 72-76, 96, 102. As an option it is right; the README's "start it first" for the default is covered by 3 |
| 11 | Code must match `spring-javaformat`; `validate` runs in the build | Verified | **Yes** | Part of 4 |
| 12 | nohttp scans all files and fails on `http://`; suppressions file | Verified | **Yes** | Part of 4 (`pom.xml:244`, `src/checkstyle/nohttp-checkstyle-suppressions.xml`) |
| 13 | `.editorconfig` defines whitespace | Verified | No | Copied: README line 186 |
| 14 | Commits need a DCO `Signed-off-by` trailer | Verified | No | Copied: README line 186. Also in `CONTRIBUTING.md`, one of the rigged files |
| 15 | Package by feature under `org.springframework.samples.petclinic` | Verified | No | Found in seconds from the tree |
| 16 | `BaseEntity` → `NamedEntity` / `Person`, mapped superclasses | Verified | No | Found in seconds (`model/*.java`) |
| 17 | `Owner` owns `Pet`s, `Pet` owns `Visit`s, `@OneToMany(cascade = ALL, fetch = EAGER)`; no Pet or Visit repositories; controllers save the owner | Verified | **Yes** | Takes several files to piece together, and "there is no Pet or Visit repository" saves a search (`owner/Owner.java:67-70`, `owner/Pet.java:56-59`, `owner/PetController.java:126`, `owner/VisitController.java:109`). Not in the README |
| 18 | `PetTypeFormatter` converts form strings; `PetValidator` installed with `@InitBinder` | Verified | No | Found in seconds: both sit in `owner/`, and `PetController.java:94-98` shows the binder. It is also three of experiment 6's four framework steps, so keeping it would hand experiment 6 its answer |
| 19 | Vets list as HTML and as JSON/XML through `Vets` | Verified | No | Found in seconds (`vet/VetController.java:45, 72-73`, `vet/Vets.java:30`) |
| 20 | `VetRepository` results cached in the JCache `vets` cache (`system/CacheConfiguration`, Caffeine provider) | **Wrong** | **Replaced** | Spring Boot uses its Caffeine cache manager, because the pom has the JCache API but no provider (`pom.xml:67-70, 81-85`), so `CacheConfiguration` never applies; the cache has no size limit or expiry (running app, `/actuator/caches`). The same mistake every Opus run made on question 3 |
| 21 | Welcome page; `CrashController` throws on purpose; `?lang=` switches locale | Verified | No | Found in seconds (`system/CrashController.java:33`, `system/WebConfiguration.java:47`) |
| 22 | Repositories are `JpaRepository`; owner search is paginated, `findByLastNameStartingWith` | Verified | No | Found in seconds (`owner/OwnerRepository.java`) |
| 23 | `PetClinicRuntimeHints` for GraalVM native images | Verified | No | Found in seconds |
| 24 | `database=h2`; the profiles override it and the datasource; schema and data from `db/${database}/` | Verified | **Yes** | Merged with 3 (`application.properties:2-4`) |
| 25 | Schema changes must be made in all three of `db/h2`, `db/mysql`, `db/postgres` | Inferred | **Replaced** | Advice the code doesn't settle. Replaced with what the three schemas show: each has a unique constraint on owner and pet name, named in H2 (`db/h2/schema.sql:55`) and Postgres (`db/postgres/schema.sql:45`, on `LOWER(name)`), unnamed in MySQL (`db/mysql/schema.sql:47`). **Corrected 18 October:** the first replacement said MySQL had no such constraint, checked only by searching for the constraint's name; the evidence rule's agent found the unnamed one in the E5 dry-run |
| 26 | Thymeleaf templates, `fragments/layout.html`, the form-field fragments | Verified | No | Found in seconds |
| 27 | `I18nPropertiesSyncTest` fails on a missing key or hard-coded text in a template | Verified | **Yes** | Not in the README; a build failure that is costly to discover (`system/I18nPropertiesSyncTest.java:40, 87`) |
| 28 | Controller tests are `@WebMvcTest` with mocked repositories; `ClinicServiceTests` is `@DataJpaTest` | Verified | No | Found in seconds |
| 29 | Integration tests on H2, MySQL (Testcontainers) and Postgres (Docker Compose), skipped without Docker | Verified | No | Found in seconds; the README mentions Testcontainers (line 107) |
| 30 | "Their `main()` methods (plus `MysqlTestApplication`)" are dev launchers | **Wrong in part** | No | `MySqlIntegrationTests` has no `main()`; the launchers are `PetClinicIntegrationTests`, `PostgresIntegrationTests` and `MysqlTestApplication` |

**Tally.** 30 claims: 27 verified, 1 inferred, 2 wrong; 6 copied from the README. Kept: 6 claims, merged into 4 lines, plus 2 replacements. 22 dropped, most because the agent finds them in seconds.

**The caveat to say aloud.** Lines 3, 17, 20 and 25 touch questions 2, 3, 4 and 6. Replacing a wrong line with the verified fact puts an answer into the file; in class that shows the mechanism, and experiment 5's design says so. Line 18 was dropped partly to keep experiment 6's journey out of it.
