# Approved changes to protected checks, for e21 round 1 (renamed after the run: round 2 has no approvals, so every protected check stays read-only)

A protected check changes only with its owner's approval. Each item names one file and the one change approved to it; demo.sh leaves that file writable for the run, and every other protected check stays read-only.

- `src/test/java/org/springframework/samples/petclinic/owner/PetControllerCharacterizationTests.java`: remove the field `@MockitoBean private PetRepository pets;` that e17 added, and the blank line before it, so the file is exactly as it is at `week-3-start` (`git diff --quiet HEAD -- <file>` succeeds). Nothing else changes. Approved by Prem, 1 November, with G9 (the gate after triage); it replaces e17's approval.
