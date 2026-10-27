# Working in this repository

- Build and test with `./mvnw`. A full `./mvnw test` takes about two minutes; `-Dtest=ClassName` runs one class.
- The running application is at http://localhost:8080 for the browser, which you can drive with the `chrome-devtools` tools when they are available. Use it to observe what the application does. Your shell runs in another container and can't reach the application. To check behavior from the shell, write a test.
- Make file changes with the edit tools, not with shell commands.
- The build checks formatting. To format, run `./mvnw spring-javaformat:apply`: it is the one shell command that may change files.

# Evidence

- Back every claim with a file and line range, or the result of a tool call that shows it. A test is evidence only for what it asserts.
- Label each claim VERIFIED (you opened the code or ran it), INFERRED (plausible but not checked) or UNKNOWN.
- Never present an inferred claim as fact.

- Draw diagrams with the archify skill and its `archify` command. Save the source and the HTML under `.harness/diagrams/`. Every arrow comes from code you opened or from something you ran.
