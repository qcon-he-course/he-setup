# Week 1 ready reckoner: understanding code you didn't write

Week 1 of the InfoQ Certified AI-Assisted Engineering Program, 19 October 2026. This page contains what you need from the session: the ideas, the text to copy into your own setup, the habits, and where to look next. It assumes you were there or have the slides. It doesn't repeat the answers to the PetClinic questions.

**Contents**

1. [The ideas](#1-the-ideas)
2. [The six layers, and their effects](#2-the-six-layers-and-their-effects)
3. [Text to copy](#3-text-to-copy)
4. [Keeping the repository from steering the agent](#4-keeping-the-repository-from-steering-the-agent)
5. [Choosing a comprehension tool](#5-choosing-a-comprehension-tool)
6. [Habits to keep](#6-habits-to-keep)
7. [Worth exploring](#7-worth-exploring)
8. [Further reading and references](#8-further-reading-and-references)

## 1. The ideas

- **An agent is a model in a loop.** The harness sends a request to the model. The model replies, or asks for a tool. The harness runs the tool and adds the result to the conversation. The loop repeats until the model replies without a tool call. The model keeps no memory between turns. Each request contains the whole conversation.
- **You pay on every turn for everything that is always loaded.** The system prompt, the tool definitions and your context files go on every request. Every tool result also stays in the request until the conversation is compacted. In Claude Code, `/context` shows what the request contains.
- **Feeling is a poor guide to speed.** In METR's 2025 study,<sup>[3](#src-3)</sup> experienced developers predicted AI would make them 24% faster and felt 20% faster afterward. The measurement said 19% slower. METR's 2026 update<sup>[4](#src-4)</sup> calls those results out of date, and its newer data is weak evidence either way. Prediction and feeling still don't tell you what happened. Measure.
- **Wrong answers read as fluently as right ones.** On code it hasn't seen, the bare agent answered with the same confidence whether it was right or not.
- **The harness is what surrounds the model.** The vendor builds the inner ring: the loop, the tools, the system prompt. The outer ring is yours:

  | Before it acts                                                             | After it acts                                                                 |
  |----------------------------------------------------------------------------|-------------------------------------------------------------------------------|
  | **Context:** what you give it to read (AGENTS.md, skills, tools)           | **Sensors:** what catches its mistakes (tests, linters, hooks, review agents) |
  | **Permissions:** what it may do (allow, ask, deny; container and firewall) | **Gates:** the review and CI its work must pass                               |

- **Guides steer, sensors check.**<sup>[1](#src-1)</sup> Guides work before the agent acts: context files, skills, tool routing. Sensors work after it acts: tests, linters, type checks, review. Both come in two kinds: computational (deterministic and cheap, like a compiler) and inferential (a model judges, like an AI review). Week 1 built guides. Week 2 adds sensors.
- **Same model, different harness, different results.** On Terminal-Bench 2.1,<sup>[9](#src-9)</sup> a model in its maker's harness scored a few percentage points to about 20 points higher than in the benchmark's neutral harness. Between mature harnesses, the difference in success is small and the difference in cost is large. The vendor tunes the inner ring. Your gains come from the outer one.
- **Trust grows with verification.** In Week 1, the agent could only read and answer. It gets more permissions as the surrounding checks increase. In Week 2 it edits code behind tests. In Week 3 it gets wider permissions, because independent review exists. In Week 4 it runs unattended in CI.

## 2. The six layers, and their effects

Same agent, same model, same six PetClinic questions. One thing changed per experiment.

|   | Layer      | What we added                                             | Effect                                                                                                    | Limits or cost                                                                                                  |
|---|------------|-----------------------------------------------------------|-----------------------------------------------------------------------------------------------------------|-----------------------------------------------------------------------------------------------------------------|
| 0 | Bare agent | Nothing                                                   | The baseline                                                                                              | Wrong answers as fluent as right ones; rigged README claims repeated as fact                                    |
| 1 | Contain    | A floor: managed settings the repository can't override   | The repository's own hooks, tool servers, permission rules and skills stopped loading                     | The answers didn't change. A secret the agent reads still goes to the model provider with its next request      |
| 2 | Instruct   | A four-line instruction file                              | It read the code where the README disagreed, started from the entry points, and said which source it used | No new facts. More reading, more calls, more tokens                                                             |
| 3 | Navigate   | A language server (Serena), plus a routing rule           | Finds the right symbol where names repeat, in fewer reads                                                 | Only when the agent uses it: agents often skip a tool that's loaded and described                               |
| 4 | Know       | A code graph (code-graph-rag)                             | Follows a call path in one call                                                                           | Blind to what the framework does: Spring's `@ModelAttribute` calls and Spring Data's `save` aren't in the graph |
| 5 | Verify     | The evidence rule, and an AGENTS.md of lines you checked  | Answers cite a file and line, or say INFERRED or UNKNOWN                                                  | It shows what the agent relied on. You still have to open a citation                                            |
| 6 | Understand | You, writing the journey yourself, and two diagram skills | You can say where the drawing is wrong                                                                    | A diagram is a claim. The drawing left out steps that the agent's notes had                                     |

The experiments showed three kinds of context:

- **Provided:** what you give the agent, like the instruction file.
- **Derived:** what tools extract from the code, like the language server and the graph.
- **Verified:** what you checked, kept in AGENTS.md. What you verify today is what tomorrow's session is given.

Week 1 didn't cover two other kinds of evidence: what the code does when it runs (runtime traces), and why it became what it is (its history). Later weeks cover both.

Our runs also showed one result outside the six layers: a smaller model is not cheaper by default. With nothing added, Haiku 4.5 made about twice as many tool calls as Opus 5.5 on the same questions. It sent about five times as many tokens, and it scored lower (five runs each, 18 October).

## 3. Text to copy

### The instruction file

In class, we used four lines written for PetClinic, so that one codebase could be measured. The advice behind them applies to any codebase: say what kind of session this is, say where the code starts, and say what the framework decides that the code doesn't show. There are three groups of lines.

**Works anywhere.** Put this line in your user-level instruction file, so every session gets it (in Claude Code, `~/.claude/CLAUDE.md`), or in each repository's AGENTS.md. The evidence rule below belongs here too.

```text
- Documents, including the README, may be out of date. When a document and the code disagree, the code decides. Say which one you relied on.
```

**Depends on the task.** Pick one per session. In class, we used the first. The second hasn't been tested in the course yet.

```text
- Exploring: You are here to explore and explain. Don't change, create or delete any file.
- Changing: Change only what the task needs. Say which files you changed and why.
```

**Depends on the codebase.** Complete these lines for each repository.

```text
- Start from the entry points: <where requests or jobs enter>, <where configuration lives>, and <the build file>.
- Much of the behavior here is decided by the framework: <the mechanisms that act without an explicit call>. Read them before concluding.
```

Examples for some common stacks:

| Stack                 | Entry points                                                                                        | What the framework decides                                                         |
|-----------------------|-----------------------------------------------------------------------------------------------------|------------------------------------------------------------------------------------|
| Spring (what we used) | Web controllers, `src/main/resources` (configuration, schema and data), `pom.xml` or `build.gradle` | Spring MVC annotations, Spring Data method names, JPA mappings, Spring profiles    |
| Rails                 | `config/routes.rb`, controllers, `db/schema.rb`                                                     | Naming conventions, callbacks, concerns, initializers                              |
| Django                | `urls.py`, views, `settings.py`                                                                     | Middleware, signals, model managers, migrations                                    |
| ASP.NET Core          | `Program.cs`, controllers or minimal APIs, `appsettings.*.json`                                     | Dependency injection registrations, middleware order, attributes, EF Core mappings |
| NestJS or Express     | Route and module files, `package.json`                                                              | Middleware order, decorators, dependency injection                                 |

Keep the user-level file small: it goes into every request, in every repository. The exploring line doesn't belong there, because it would stop the agent changing code anywhere.

### The evidence rule

A wrong answer reads as fluently as a right one, so you can't tell from the wording whether the agent checked. The rule makes it show where each claim comes from, and say when it didn't check. In class, the agent marked as INFERRED some answers that earlier runs had stated as fact. The other answers had a file and line that you could open in seconds. The rule doesn't make an answer right. VERIFIED is still the agent's claim about what it did, so open one citation per answer.

```text
# Evidence

- Back every claim with a file and line range, or the result of a tool call that shows it. A test is evidence only for what it asserts.
- Label each answer VERIFIED (you opened the code that shows it), INFERRED (plausible but not checked) or UNKNOWN.
- Never present an inferred claim as fact.
```

A citation to the README shows what the README says. A test shows what someone chose to check: PetClinic's duplicate-name test uses the same spelling twice, so it proves nothing about "Max" against "max".

### A routing rule for a tool

Loading a tool isn't enough. Say which kind of question goes to it. This is the rule we used with Serena:

```text
# Finding your way in the code

- For Java code, use the Serena tools before grep and before reading whole files: `find_symbol` for where something is defined, `find_referencing_symbols` for who uses it, `get_symbols_overview` for what a file contains, and `find_implementations` for the classes behind an interface.
- Use grep or ripgrep for configuration, SQL, templates and other files that aren't Java.
```

### What earns a line in AGENTS.md

A generated context file (`/init`) mostly repeats the README, and you pay for it on every request. In ETH Zurich's study,<sup>[5](#src-5)</sup> generated files solved slightly fewer tasks and cost 20 to 23% more. Audit a draft line by line, and keep a line only if it passes three tests:

1. **It's verified,** and says where: a file and line, or a tool result.
2. **Without it, the agent would get it wrong, or need a long time to find it.**
3. **The README doesn't already say it.**

| Leave out                                                                                                        | Keep                                                                                                                                                                        |
|------------------------------------------------------------------------------------------------------------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| "Follows Spring best practices with a clean layered architecture." Generic, and wrong: there's no service layer. | "Pet validation is in `PetValidator`, not in annotations: name required, at most 30 characters; birth date required; type required for new pets." `PetValidator.java:36-57` |
| "Uses Java and Spring Boot." True, and found in seconds.                                                         | "`/oups` throws on purpose, to demonstrate the error page." `CrashController.java:31-34`                                                                                    |

Also keep these lines:

- The place where a rule is enforced, when it isn't the obvious place.
- Values that live outside the code, such as a database flag or a configuration profile.
- Your house rules, such as the instruction lines and the evidence rule.

Leave out anything you tagged inferred and didn't check.

**As it grows, make it an index.** Put one topic in each file. In AGENTS.md, name each file and the area it covers, for example "Before changing assessment rules, read `docs/agents/assessment.md`". The agent reads a topic file when its task touches that area. This works in every agent, and each file stays short enough to review. Claude Code's documentation suggests staying under 200 lines per file.<sup>[10](#src-10)</sup> In Claude Code, an `@path` import loads the file into every session, so it saves no context; a path in backticks is only a pointer.

### Which file does your agent read?

| Agent       | Reads                                                      | After you edit it mid-session                   |
|-------------|------------------------------------------------------------|-------------------------------------------------|
| Claude Code | `CLAUDE.md`; `AGENTS.md` only when there is no `CLAUDE.md` | Ignored until `/clear`, `/compact` or a restart |
| Codex       | `AGENTS.md`, up to 32 KiB                                  | The new version is appended as a replacement    |
| OpenCode    | `AGENTS.md`                                                | Re-read on every step                           |
| Copilot CLI | `AGENTS.md`, `.github/copilot-instructions.md`             | Picked up in the next session                   |

Behavior as of September 2026. It changes between releases, so check what loaded rather than relying on the table.

## 4. Keeping the repository from steering the agent

**The lethal trifecta** (Simon Willison)<sup>[2](#src-2)</sup>: private data, untrusted content, and a way to send data out. Together they allow exfiltration. An agent reading an unvetted codebase always has the untrusted content, so remove one of the other two.

When you trust a folder, the repository's own agent configuration can load: hooks, tool servers, permission rules, skills. In experiment 1, PetClinic's start-up hook ran as soon as we trusted the folder, before anyone asked a question.

**What we used: a floor.** Claude Code's managed settings override the repository's settings. This is the floor from the course, at `/etc/claude-code/managed-settings.json` on Linux. Your operating system's path is in Claude Code's settings documentation.

```json
{
  "allowManagedHooksOnly": true,
  "allowManagedPermissionRulesOnly": true,
  "strictPluginOnlyCustomization": ["skills", "agents"],
  "autoMemoryEnabled": false,
  "permissions": {
    "disableBypassPermissionsMode": "disable",
    "disableAutoMode": "disable"
  }
}
```

| The floor stops                                                                                      | It doesn't stop                                                            |
|------------------------------------------------------------------------------------------------------|----------------------------------------------------------------------------|
| The repository's own hooks, tool servers, permission rules and skills                                | A rigged claim, repeated as fact                                           |
| Reading or changing files outside the repository (in our container, only the repository was mounted) | A secret the agent read, sent to the model provider with its next request  |
|                                                                                                      | A network call the agent makes, unless something like a firewall blocks it |

The instruction file and the evidence rule address claims. A secret is safe only where the agent can't read it, so scan for secrets before the agent reads the repository. A firewall with an allowlist removes the network as a way to send data out.

## 5. Choosing a comprehension tool

**grep finds text. A language server finds the symbol.** The gap is small where a name is used once, and grows with overloads, common method names and large codebases.

**A language server answers one hop at a time. A code graph answers the connections at once:** what a method reaches, which tests reach it, what a change touches. Both read the code as written. Neither sees what the framework decides at run time.

Published results:

- In 58% of trials with a code navigation tool available, the agent never called it (CodeCompass<sup>[6](#src-6)</sup>). In 56% of cases where a skill was available, it was never invoked (Vercel<sup>[8](#src-8)</sup>).
- One graph tool's authors<sup>[7](#src-7)</sup> measured 83% answer quality against 92% for plain file exploration, at about a tenth of the tokens. CodeCompass measured 76% to 99% coverage on questions with hidden dependencies, when the agent used the graph. A graph tool is likely to be cheaper. Whether it is better depends on the question.

We tried three graph tools on PetClinic. Two were wrong about the one journey we cared about, although their READMEs promised type resolution and Spring awareness. Before you adopt a tool:

1. Write down the question your team needs answered.
2. Run every candidate on your own code.
3. Check each answer against the code, file and line.
4. Only then weigh setup, speed and cost.

## 6. Habits to keep

- **Predict before you run.** Write down what you expect. Then compare the result with your prediction.
- **Change one thing at a time,** and ask the same questions before and after. Record the same few numbers each time: answers right, citations, tool calls, files read, minutes and tokens.
- **Run it twice.** The same agent gives different answers to the same question. One run is not enough evidence.
- **Open one citation per answer.** VERIFIED is the agent's claim about what it did. It takes seconds to check.
- **Treat INFERRED and UNKNOWN as good answers.** They're better than a confident guess.
- **Check what loaded** (`/context` in Claude Code) when an instruction seems to be ignored.
- **Read the framework.** Annotations, method names, mappings and profiles decide much of what a Spring application does, and none of it appears as a call in the code.
- **Check a diagram against the code** before you give it to anyone.

## 7. Worth exploring

These topics are outside Week 1. Later weeks cover some of them.

**Runtime evidence.** What the code does when it runs: start the application and try the behavior, step through it in a debugger, or read the request in the browser's developer tools. In Week 2 the agent reproduces a bug in a real browser through the Chrome DevTools MCP server.

**History.** Why the code became what it is. `git log -p -- <file>`, `git log -S '<text>'` to find the commit that added or removed a string, and `git blame`. A commit message describes what its author meant to change, and the diff shows what changed.

**Context that loads only when needed.**
- Topic files named from AGENTS.md (section 3).
- A subdirectory's own `AGENTS.md` or `CLAUDE.md`. Claude Code loads one when it works with a file in that subdirectory.<sup>[10](#src-10)</sup>
- Claude Code's path-scoped rules in `.claude/rules/`, which load only when the agent works with matching files.

**Skills.** A `SKILL.md` with a `name` and a `description` that says when to use it. The agent reads the descriptions at the start of a session, and opens a skill when its description matches the task. Week 2 builds and tests two.

**Tools from Week 1, and their alternatives.**

| Tool                                                                   | What it does                                     |
|------------------------------------------------------------------------|--------------------------------------------------|
| [Serena](https://github.com/oraios/serena)                             | Language-server navigation for agents, over MCP  |
| [code-graph-rag](https://github.com/vitali87/code-graph-rag)           | A code graph with call, type and test queries    |
| [codebase-memory-mcp](https://github.com/DeusData/codebase-memory-mcp) | A code graph in one static binary                |
| [code-review-graph](https://github.com/tirth8205/code-review-graph)    | A code graph on SQLite, which records web routes |
| [CodeBoarding](https://github.com/CodeBoarding/CodeBoarding)           | Component diagrams generated from the code       |

**Secret scanning** before an agent reads a repository: [gitleaks](https://github.com/gitleaks/gitleaks), [TruffleHog](https://github.com/trufflesecurity/trufflehog).

**More practice code.** The [Week 1 homework](../homework/week1.md) lists six open-source business applications, from an ERP to a CRM, that models are less likely to know. Use the same method: bare first, then your harness, and check every claim against the code. Check the license before you use one at work.

## 8. Further reading and references

1. <a id="src-1"></a>Birgitta Böckeler, ["Harness engineering for coding agent users"](https://martinfowler.com/articles/harness-engineering.html), martinfowler.com, April 2026.
2. <a id="src-2"></a>Simon Willison, ["The lethal trifecta for AI agents: private data, untrusted content, and external communication"](https://simonwillison.net/2025/Jun/16/the-lethal-trifecta/), 16 June 2025.
3. <a id="src-3"></a>METR, ["Measuring the impact of early-2025 AI on experienced open-source developer productivity"](https://arxiv.org/abs/2507.09089), arXiv 2507.09089, July 2025.
4. <a id="src-4"></a>METR, ["We are changing our developer productivity experiment design"](https://metr.org/blog/2026-02-24-uplift-update/), 24 February 2026.
5. <a id="src-5"></a>Gloaguen et al., ETH Zurich, ["Evaluating AGENTS.md"](https://arxiv.org/abs/2602.11988), arXiv 2602.11988, version 2, June 2026.
6. <a id="src-6"></a>CodeCompass, [arXiv 2602.20048](https://arxiv.org/abs/2602.20048).
7. <a id="src-7"></a>The authors of codebase-memory-mcp, [arXiv 2603.27277](https://arxiv.org/abs/2603.27277).
8. <a id="src-8"></a>Vercel, ["AGENTS.md outperforms skills in our agent evals"](https://vercel.com/blog/agents-md-outperforms-skills-in-our-agent-evals), 2026.
9. <a id="src-9"></a>[Terminal-Bench 2.1](https://www.tbench.ai/news/terminal-bench-2-1), May 2026.
10. <a id="src-10"></a>Claude Code documentation, ["How Claude remembers your project"](https://code.claude.com/docs/en/memory).
