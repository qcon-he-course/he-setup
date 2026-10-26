---
name: trace-request
description: Use before changing code you did not write, when you need to know what one request goes through, from a captured or reproduced request to the code that handles it.
---

# Trace what one request goes through

This skill ends at a trace of one request: every step it passes through, in order, each labelled with how you know it. It changes no production code.

## Steps

1. **Start from one real request.** Write down its method, path, parameters and response, and where you got them: a browser's network log, a server log, a reproduction. If you have only a report, reproduce the request first or ask for it.
2. **Find the code that handles it.** Match the path to its handler, and give the file and symbol.
3. **List every step the request goes through, in order, from arrival to response.** Include the steps the framework runs without a call in the code: annotations, decorators, middleware, filters, interceptors, data binding, validation, transactions. Read every annotation on the handler, its parameters and its class, and every method the framework calls before or after it.
4. **For each step, record what it does to the data, the file and symbol, and a label.** VERIFIED: you read it in the code or saw it run. INFERRED: it follows from how the framework works, or from a name, and you have not checked it. UNKNOWN: you could not tell.
5. **Compare with a path that works,** if the report names one. Note each step that one path has and the other lacks.
6. **Check the inferences your conclusion depends on by running something.** A log line, a test, or a temporary change that you undo afterwards. Then the step is VERIFIED, with what you ran. A test that replaces part of the framework, such as a mocked repository, shows what that setup does: label a step it checks VERIFIED for the test and INFERRED for the running app. Check with `git diff` that production code is as it was.

## Red flags

| Thought | What to do instead |
|---|---|
| "The method I opened is the whole path." | Read the annotations around it. The framework runs code that nothing calls. |
| "Nothing calls this method, so it doesn't run." | Check whether the framework calls it: an annotation, a registration, a naming convention. |
| "I know what the framework does here." | Label it INFERRED until something has run. |
| "I have the cause. The rest of the path doesn't matter." | Finish the trace to the response. A change in the middle of the path affects every step after it. |

## Reply with

1. The request, and where it came from.
2. A table, one row per step, in order: what happens, file and symbol, label, and the evidence for each VERIFIED step that is not plain reading.
3. Where it differs from the working path, if there is one.
4. A Mermaid sequence diagram of the same steps.
5. What you ran to check, and `git diff --stat` afterwards.
