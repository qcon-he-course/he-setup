---
name: pin-behavior
description: Use before refactoring, restructuring, or moving logic in existing code.
---

# Pin current behavior before changing code

A pin is a test that records what the code does today, so a later change that alters it fails loudly. Pins describe the code as it is, odd parts included. They are not a statement of what the code should do.

## Steps

1. **List the code you are about to change.** Name every method your change or refactoring will edit, and the entry points that reach them.
2. **List every rule and outcome in those methods, not only the one your task is about.** For each rule, note the normal case, the boundary, and any detail the code makes visible: case-insensitive comparison, null handling, defaults, what is saved and what is not. If your task is to change one behavior, mark it and leave it unpinned. If you pin a behavior you believe is a bug, add a comment starting `SUSPECT:`, so whoever fixes it knows which pin to replace.
3. **Run the existing tests that cover these methods, and name them.** Pin only what they leave uncovered. A test that already fails proves a reported bug: the behavior it covers is the one being changed, so leave it unpinned and leave that test as it is.
4. **Write the pins in a new test class** named after the subject, for example `PetControllerCharacterizationTests`. Leave existing tests and shared setup unchanged.
5. **Take each expected value from a run.** Write your best guess, run the test, and if the guess was wrong, copy the actual value into the assertion. Never keep a value you have not seen the code produce. If a value looks wrong, keep it and add a comment starting `SUSPECT:`.
6. **Prove each rule's pins can fail.** Make one deliberate change to the production rule, run the pins and see at least one fail, then undo the change. Afterwards, check with `git diff` that production code is back as it was. A pin that cannot fail pins nothing.
7. **Run the whole test suite on the unchanged code.** Everything is green, except a test that proves a reported bug, which stays red until the fix.

## Red flags

| Thought | What to do instead |
|---|---|
| "The task is about X, so I'll pin X." | Pin every rule in the methods you will touch. A refactoring moves all of them. |
| "The existing tests probably cover that." | Run them and name the test that does. |
| "I'll add an assertion to the existing test." | Put pins in the new class. |
| "I know what this returns." | Run it and copy the value. |
| "It passes, so the pin works." | Break the rule once and watch the pin fail. |
| "One test is red. I'll make it pass." | It proves a reported bug. Leave it red: the fix turns it green. |

## Reply with

1. The methods you will change.
2. A table with one row per pin: behavior, test name, expected value, and the change that made it fail.
3. Behaviors left unpinned, and why: already covered by a named test, or the behavior your task changes.
4. The full suite result on unchanged code.
