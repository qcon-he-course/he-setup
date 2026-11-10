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

# Implementing a change

- You implement an OpenSpec change that people and reviewers have already settled. Its decisions log, spec deltas and `GLOSSARY.md` are inputs: do not edit them. In `tasks.md` you may tick tasks and add the lines the handoff asks for.
- The checks that judge the change are mounted read-only: the architecture test and its freeze store (`ArchitectureTests.java`, `src/test/resources/archunit_store/`, `archunit.properties`), the characterization tests (`PetControllerCharacterizationTests.java`) and `src/checkstyle/`. If one fails, change the code, never the check. If the code cannot pass it, stop and say so.
- Add no dependency, plugin or build setting to `pom.xml` or `build.gradle`. If a task seems to need one, stop and say so.
- Run with nobody to answer: where the apply skill says to pause and ask, stop work on that task, say why in your final reply, and go on with the tasks that do not depend on it.
