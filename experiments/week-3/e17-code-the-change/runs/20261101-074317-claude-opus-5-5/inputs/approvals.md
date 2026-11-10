# Approved changes to protected checks, for e17

A protected check changes only with its owner's approval. Each item names one file and the one change approved to it; demo.sh leaves that file writable for the run, and every other protected check stays read-only. Step 5's test-delta audit reports the change, and triage confirms it is the approved one.

- `src/test/java/org/springframework/samples/petclinic/owner/PetControllerCharacterizationTests.java`: add one field, `@MockitoBean private PetRepository pets;`, next to the existing `@MockitoBean` fields, so the class's context starts once `PetController` takes a `PetRepository` (task 3.1). Nothing else in the file changes: no test, assertion, stub or import. Approved by Prem, 1 November, after the first e17 run stopped on it.
