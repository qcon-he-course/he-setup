# How the code is connected

- For how the code is connected, ask the code graph (code-graph-rag) before reading files one by one: `callers` and `callees` for call chains, `implementors` and `overrides` for type hierarchies, `importers` for dependencies between classes, `tests_reaching` for the tests that reach a method, and `resolve` or `definition` to find a symbol's qualified name. The same lookups work on the command line, for example `cgr graph callees <qualified.name> --depth 2`.
- The graph is already built for this repository. Don't re-index it.
