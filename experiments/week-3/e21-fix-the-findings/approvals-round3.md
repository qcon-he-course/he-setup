# Approved changes to protected checks, for e21 round 3, step 8's base (renamed after the run, so later e21 runs carry no approval)

A protected check changes only with its owner's approval. Each item names one file and the one change approved to it; demo.sh leaves that file writable for the run, and every other protected check stays read-only.

- `src/test/java/org/springframework/samples/petclinic/owner/PetControllerCharacterizationTests.java`: rename test methods that show a scenario of PC-301's spec deltas to the naming rule G13 (`../e22-test-the-reviewer/base-gate.md`). Names only: no test body, assertion, stub, field or import changes, and no test added or removed. Step 5's test-delta audit must show each change as "test renamed … body unchanged". Approved by Prem, 1 November.
