# Working in this repository

- Build and test with `./mvnw`. A full `./mvnw test` takes about two minutes; `-Dtest=ClassName` runs one class.
- Make file changes with the edit tools, not with shell commands.
- Batch runs deny shell commands they cannot match against the allow list. Run one command per Bash call (a pipe into `head`, `grep` or `sort` is fine). Don't use `for` loops, `$(...)`, parentheses or `git -C`: you are already in `/work`. To read several files, use the Read tool once per file.
- The build checks formatting. To format, run `./mvnw spring-javaformat:apply`: it is the one shell command that may change files.
- Specifications live in `openspec/`: current behaviour in `openspec/specs/`, proposed changes in `openspec/changes/`. The `openspec` command validates them.
- When `GLOSSARY.md` exists at the repository root, use its terms, and none of the words it lists under `_Avoid_`.

# Evidence

- Back every claim with a file and line range, or the result of a tool call that shows it. A test is evidence only for what it asserts.
- Label each claim VERIFIED (you opened the code or ran it), INFERRED (plausible but not checked) or UNKNOWN.
- Never present an inferred claim as fact.
