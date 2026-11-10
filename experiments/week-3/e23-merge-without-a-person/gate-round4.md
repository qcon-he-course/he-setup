# The gate on PC-303 after round 4, 2 November

Input: round 4 (`runs/clean-round4/`). e21 rewrote the time-zone test and stopped short of `gate-round3.md`'s spec edit, rightly: rewording only the WHEN would leave the THEN false for a zone behind UTC. Two Opus reviews asked how the scenario should read (DISCUSS); one Opus review and Codex rated it AUTO-FIX. Prem answered on 2 November. Nothing else in the change is reopened.

## Decisions

| # | Question | Answer |
|---|---|---|
| G1 | How does the scenario "Today is the date in the server's time zone" read, now that its test covers a zone ahead of UTC and a zone behind? | One scenario covering both cases, with exactly the text under W1. Record it as D18, amending how D11 is shown (D11 itself stands: "today" is the server's date). Rejected: two scenarios (no fixed zone differs from UTC all day, so each test would skip for part of it); the ahead case only (a test that skips 10 hours a day) |

## Work for the author

| # | From | What to do | Checked by |
|---|---|---|---|
| W1 | G1 | In `openspec/changes/pc-303/specs/pets/spec.md`, replace the scenario "Today is the date in the server's time zone" (its WHEN, THEN and CHECKED AT lines) with exactly this, and change nothing else in the spec delta:<br><br>`#### Scenario: Today is the date in the server's time zone`<br>`- **WHEN** the server's default time zone has a different date from UTC, and the owner's page is shown for a pet born on the later of the two dates`<br>`- **THEN** the age follows the server's date: "under a month" when the server's date is the later one, and no age when it is the earlier one`<br>`- **CHECKED AT** form`<br><br>Then tick task 5.1 | `openspec validate pc-303 --strict` is valid; `git diff` of the spec delta shows only this scenario changed; task 5.1 ticked; `./mvnw test` passes as before |

## Left as they are

- The code and every test, as round 4 left them.
- Every decision D1 to D17, apart from recording D18.
- The INFORMATIONAL findings of round 4.
