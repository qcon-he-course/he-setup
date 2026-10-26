---
name: prove-bug
description: Use when a bug, defect, regression or wrong behavior has been reported and no test fails because of it yet, before any production code is changed.
---

# Prove the bug with a failing test

This skill ends at one test that fails for the reason the bug report gives. It changes no production code. Fixing the bug is a separate step that starts after the failing test is reported.

## Steps

1. **Write down the expected behavior in one sentence, and say where it came from.** Take it from the report, or from a path the report names as correct ("as adding one does"). Never take it from the code under suspicion: that code is what is wrong. If the report does not say what should happen, stop and ask.
2. **Choose the lowest level that shows what the user saw.** Usually the controller or service the user's action reaches. Add to an existing test class and reuse its setup.
3. **Write one test, named after the expected behavior.** The first assertion is the outcome the user saw: the page, status or result. Detail assertions come after it. Use this order even when neighboring tests use another.
4. **Run the test class and read the first failure line.** The new test must fail, and that line must name the symptom in the report. For example, "expected the form to be shown again, got a redirect" names it. "No BindingResult for attribute: owner" does not, because it is about test plumbing. If the line names anything else (a compile error, a missing fixture, an assertion the report does not mention), reorder or fix the test and run it again. The other tests in the class still pass.
5. **Check that production code is untouched.** `git diff --stat` lists only test files.
6. **Report, and stop.** If you were also asked to fix the bug, write this report in your reply before starting the fix.

## Red flags

| Thought | What to do instead |
|---|---|
| "The cause is obvious. I'll fix it and add the test after." | The fix is not part of this skill. Report the failing test first. |
| "It failed, good enough." | Read the first failure line. A failure for the wrong reason is not a reproduction. |
| "The message is odd, but the status shows the symptom." | Then the status assertion should have failed first. Reorder and run it again. |
| "The code returns X, so X is expected." | The code is the suspect. The expected value comes from the report. |

## Reply with

1. Expected behavior, and its source.
2. The test: file and name.
3. The command, and the first failure line.
4. `git diff --stat`, showing test files only.
