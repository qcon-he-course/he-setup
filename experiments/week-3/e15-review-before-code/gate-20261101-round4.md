# The gate after the fresh review of round 3: round 4, 1 November

Input: the fresh review of e16's round 3 (`runs/20261101-053638-claude-opus-5-5`). Its R1 is a BLOCK whose fix needs a decision; Prem answered it, and answered the dependency question raised after round 3. Under the stop rule in the plan, R1 goes back to the author and a fresh review checks the fix. The review's R2, R3 and R4 need no decision and go to the coding agent in e17 as extra tasks.

## Decisions

| # | Question | Answer |
|---|---|---|
| G7 | R1: on MySQL the old code cannot start against the migrated table, because the old `db/mysql/data.sql` inserts pets by position and runs at every start. How does MySQL move from the old code to the new? | **Two releases.** Release 1 ships only the column lists for the pet inserts in `data.sql` (H2 and MySQL); they work on the old table and on the migrated one. Then the migration script runs. Then release 2 ships the microchip number. Rollback from release 2 redeploys release 1, which works on the migrated table. Amend D23: its premise "the old code keeps working against the new table because it never names the column" is false on MySQL while the old `data.sql` inserts by position; it holds from release 1 on. Record G7 as a new decision that amends D23; do not delete D23's text, mark what G7 changes. The change stays one OpenSpec change; the two releases are ordered steps in the design's deployment plan and in the tasks |
| G8 | Task 1.5 adds `org.testcontainers:testcontainers-postgresql` for the Postgres migration test. Add the dependency? | **No.** Adding a dependency stays with a person, and this one is not needed: `PostgresIntegrationTests` starts Postgres through Spring Boot's Docker Compose support, already in the pom, and the MySQL tests use the `testcontainers-mysql` already there. The migration tests follow those existing patterns and add no dependency |

Why D23's premise was wrong (for the log): the round-3 gate file stated it, and nobody checked it against the old `data.sql`. The positional seed inserts are the same root cause as the `data.sql` BLOCK of the first reviews.

## Fixes that need no decision

None in this round. R2, R3 and R4 of the review go to e17.

## Left as they are

- R5 to R8 of the review: informational.
