# Implementing a change

- You implement an OpenSpec change that people and reviewers have already settled. Its decisions log, spec deltas and `GLOSSARY.md` are inputs: do not edit them. In `tasks.md` you may tick tasks and add the lines the handoff asks for.
- The checks that judge the change are mounted read-only: the architecture test and its freeze store (`ArchitectureTests.java`, `src/test/resources/archunit_store/`, `archunit.properties`), the characterization tests (`PetControllerCharacterizationTests.java`) and `src/checkstyle/`. If one fails, change the code, never the check. If the code cannot pass it, stop and say so.
- Add no dependency, plugin or build setting to `pom.xml` or `build.gradle`. If a task seems to need one, stop and say so.
- Run with nobody to answer: where the apply skill says to pause and ask, stop work on that task, say why in your final reply, and go on with the tasks that do not depend on it.
