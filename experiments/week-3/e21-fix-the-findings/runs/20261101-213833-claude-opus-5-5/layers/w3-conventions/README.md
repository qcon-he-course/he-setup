# w3-conventions

A Stop hook for the coding agent (e17, e21): `check-conventions.sh` runs `./mvnw validate`, the build's own checks (baseline B1: `spring-javaformat` and the nohttp checkstyle; also the enforcer's Java version), when the agent tries to stop with changes in the clone. A failure goes back to the agent (exit 2) as a message in Week 2's five parts: what failed, why, what to do instead, where, what not to do. If it fails again on the second try, the agent may stop and the person is told (exit 1).

Built like Week 2's `check-architecture.sh` (`w2-sensors`, reused unchanged): quiet until the end, since code is unformatted until the agent runs the formatter. The guide for the same rule is in `w3-base/rules.md`; step 5 checks again afterwards, outside the agent's session. Tests: `check-conventions.test.sh` (11, with a stub `mvnw`, so they run anywhere). demo.sh copies the whole layer into each run, the test file included; nothing wires it.

Known limit: the nohttp check scans the whole clone, including `.review-inputs/` while a run has it. A plain `http://` URL in a gate file would be reported to an agent that may not edit it; it then stops on its second try and the person is told.
