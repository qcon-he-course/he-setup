# The gate on PC-303 after round 3, 2 November

Input: round 3 (`runs/clean-round3/`), its four reviews and packets. Every packet said "Merges without a person: no". Two findings go back to the author; neither needs a decision, and the stop rule sends a fixed BLOCK to a fresh review. This is the last round of e23 (Prem, 2 November): whatever its packets say, step 8b is taught from rounds 1 to 4.

## Decisions

None. D11 stands: "today" is the date in the server's default time zone.

## Work for the author

| # | From | What to do | Checked by |
|---|---|---|---|
| W1 | Codex C1 (BLOCK), Opus C1 in 3 of 3 (DISCUSS) | `todayIsTheDateInTheServersTimeZone` must fail at any time of day if the controller used UTC's date instead of the default zone's. No zone is a day ahead of UTC before 10:00 UTC, so the test chooses, when it runs, a zone whose date differs from UTC's: one ahead (Pacific/Kiritimati) when UTC's time allows, otherwise one behind (for example Pacific/Pago_Pago), with a birth date for which the two dates give different pages. It first asserts that the two dates differ. Edit the scenario's WHEN to "a zone where the date differs from UTC's", and design.md's line on the comparison to match: this is the one spec edit, and it changes no behaviour | `./mvnw test -Dtest=OwnerControllerTests` passes; break the controller to use UTC's date once, see the test fail, put it back; say in the self-review why it fails at every hour, for both zones |
| W2 | Opus C2 in 3 of 3 | `theAgeTextsInTheOtherLanguages` must show that the page is in the requested language: for each language, also assert a text on the same page that differs by language (for example the owner-information heading from that language's file), beside the English age text | The same test class passes; with `?lang=` ignored (break it once, put it back), the test fails |

## Left as they are

- Everything else in the change, and every decision D1 to D17.
- The Opus INFORMATIONAL findings (the untracked main spec, the two ways the count is formatted, the form tests' midnight edge).
