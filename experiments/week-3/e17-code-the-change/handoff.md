# Extra tasks for the coding agent (e17), from the reviews of the change

Under the stop rule in `../../plan.md`, review fixes that need no decision move forward as tasks once no BLOCK is left. These are the ones still open after round 4. Each is a fix to how a task is checked; none changes the behaviour the spec asks for. Do them as part of the task named.

| # | Task | From | What to do |
|---|---|---|---|
| H1 | 3.2 | review of round 2, R2 | The edit-path checks must be able to fail. Build the bound pet and the owner's pet as separate objects, as `PetControllerCharacterizationTests.editCopiesNameBirthDateAndTypeOntoOwnersPetWhenInstancesDiffer` does, so "copied onto the owner's pet" fails if `updatePetDetails` does not copy the microchip number. For "Saving a pet with its own number", stub `existsByMicrochipNumber` to return `true` and `existsByMicrochipNumberAndIdNot` to return `false`, so the test fails if the wrong query is used |
| H2 | Workflow follow-up | review of round 2, R3 | The baseline Purpose edit has no check. Add to the follow-up a check that the archived `pets` spec's Purpose no longer excludes the GET forms |
| H3 | 1.5 | review of round 3, R2 (as D25 changes it) | After the migration script, run release 1's `schema.sql` and `data.sql` against the migrated table and assert they succeed: release 1 is what a rollback redeploys |
| H4 | 2.1 and design Decision 4 | review of round 3, R3 | Skip the uniqueness query when there is no microchip number, and say so in the code's design. In 2.1, assert the repository is never called for a pet without a number (`verifyNoInteractions`) |
| H5 | 4.1 | review of round 3, R4 | Cover the database duplicate and the "other violation is rethrown" case on both handlers: `createOtherIntegrityViolationIsRethrown` and `editOtherIntegrityViolationIsRethrown` must both still pass, and the microchip mapping needs a case on each |
| H6 | 1.5 | review of round 4, R1 | The migration tests must build the old schema before anything creates the new one: no `spring.sql.init` before the old schema (for example `spring.sql.init.mode=never`, or plain JDBC against the container). Before running the script, assert that `pets` has no `microchip_number` column |

Decisions D19 to D26 in `openspec/changes/pc-301/decisions.md` already hold everything a person decided. Nothing here needs one; if doing a task turns out to need one, stop and ask.
