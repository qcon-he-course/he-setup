# The answers checked against the running app

18 October 2026. Seeded PetClinic at `b107a86`, started with `./mvnw spring-boot:run` and no options, in the `he-ladder` image (Java 21) on a fresh clone in `~/.cache/qcon-he/verify-app`. The seeding changed only six files since upstream `500158f` (`.claude/settings.json`, `.env`, `CONTRIBUTING.md`, `README.md`, `application.properties`, `templates/welcome.html`), so the build and the Java code are upstream's.

| Question | What the running app showed |
|---|---|
| 1. Getting started | `./mvnw spring-boot:run` starts the app with no database to start first. Tomcat on port 8080 in under 3 seconds once the dependencies were downloaded. |
| 2. Database | No active profile, so the default one. Hikari's first connection is `jdbc:h2:mem:<uuid>`: H2 in memory. |
| 3. Vet cache lifetime | The `cacheManager` bean is `CaffeineCacheManager`. After `GET /vets.html`, `/actuator/caches` shows the `vets` cache as Caffeine's `UnboundedLocalCache`: no size limit and no expiry. `CacheConfiguration`'s `JCacheManagerCustomizer` bean exists but is never applied, because the pom has the JCache API and no JCache provider, so Spring Boot uses its Caffeine cache manager. |
| 4. A second pet called "max" | `GET /owners?lastName=Coleman` redirects to owner 6. Posting a new pet named `max` returns the form with "is already in use" on the name field. |
| 5. Search for "davis" | The owners list, not a redirect, with Betty Davis and Harold Davis. |
| 6. Booking a visit | Posting a visit for owner 1, pet 1 redirects to `/owners/1` with "Your visit has been booked", and the owner's page, loaded again from the database, lists the visit with its date and description. |

## What this changes in the keys

Question 3. The answer stays the same: no expiry, the list stays until the app restarts. The deciding reason changes. It is Spring Boot's Caffeine cache manager with no Caffeine spec, not `CacheConfiguration`. An answer that gives `CacheConfiguration`'s `MutableConfiguration`, or a JCache default, as the reason has the right lifetime for the wrong reason. Under the agreed rule, a right answer needs the outcome and the deciding reason, so that answer is marked `wrong_other`, with the note "right lifetime, wrong reason". `reference/grading-keys.json` carries this.

Questions 1, 2, 4, 5 and 6: the running app agrees with the keys.
