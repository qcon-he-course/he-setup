# Experiment 6: build your mental model

Rung 5, plus skills that draw what the agent finds.

## The question

Can you explain the system yourself, from the evidence, and show that the code agrees?

## What changes

Rung 5, plus:

- the `trace-journey` skill (`layer/skills/trace-journey/`): find where a journey starts, follow it with the code graph and Serena, mark hops it can't confirm as inferred, and draw an archify sequence diagram with a file and line on every arrow (`.harness/diagrams/journey-*.html`, with notes in `.harness/notes/`);
- the `arch-map` skill, which the model can't call by itself: `/arch-map` draws a component view from CodeBoarding's components;
- archify, as a skill and the `archify` command, and permission to write under `.harness/` and nowhere else (`layer/settings.json`, `layer/rules.md`);
- CodeBoarding's analysis of PetClinic (`codeboarding/`), copied into the clone as `.harness/codeboarding/`.

**The journey.** "An owner adds a new pet", from submitting the form to the row in the database: seven steps, four of them decided by the framework. The key is `../reference/e6-journey-answer-key.md`.

**A caveat.** `AGENTS.md`'s line on the controllers saving the owner, with JPA cascading the rows, gives away part of step 7. Don't count step 7 as found unaided.

## What we expected, before the run

The drawing misses the framework's steps, or marks them inferred. The component view shows the parts and what reaches the database, and none of the order; a model chose its names.

## Run it

Before you start, write the journey yourself, one line per step, with the class and the method. Then, from `../ladder/`:

```bash
./run.sh e6
```

1. Trust the folder. `/context all`, typed at the very start of the line, lists `trace-journey` and `archify` among the skills. `arch-map` doesn't show, because the model can't call it.
2. Type `/trace-journey an owner adds a new pet`. Watch whether it calls the graph (`cgr graph callees`) and Serena, as the skill says, and which hops it marks inferred.
3. When it says the diagram is written, `/exit`. The diagram exists only in the container until Claude Code exits.
4. Open the diagram: `runs/<the run>/files/.harness/diagrams/journey-*.html` in this folder. The notes are beside it, in `files/.harness/notes/`.
5. Check the drawing against the key's seven steps: which of the four framework steps (2, 3, 4 and 7) it has, which it marks inferred, and which it misses. Then check the notes.

For the component view, run `./run.sh e6` again and type `/arch-map`. It draws `files/.harness/diagrams/architecture.html`.

Approve read-only commands, `cgr graph` lookups, `archify` and writes under `.harness/`; deny any other write, build or network call.

`grade.sh` doesn't mark e6 runs: mark the drawing against the key by hand.

## What our runs showed

There is no stored batch for e6: one `/trace-journey` run and two `/arch-map` runs, on Opus 5.5.

**The journey run.** 3 minutes 17 seconds, 29 tool calls: 16 shell commands, 6 calls to Serena, 2 to the graph (`resolve`, `callees`), the archify skill, and two writes. It wrote only under `.harness/`. The drawing had 8 participants and 17 arrows, each with a file and line, with framework wiring and generated SQL dashed. Against the key:

| Step | In the drawing? |
|---|---|
| 1. The form posts back to `/pets/new` | Yes: "POST pets/new", `PetController.java:107`; the handler's name isn't given |
| 2. Spring calls the three `@ModelAttribute` methods first (framework) | **No.** `findById` and `findPetTypes` are drawn on the GET only, as calls from `PetController`; `findPet` is missing. The notes have it right |
| 3. `PetTypeFormatter.parse` converts the type (framework) | Dashed, inferred, but drawn from `PetController`, the key's typical wrong answer. Borderline |
| 4. `@InitBinder` installs `PetValidator`; `@Valid` runs it (framework) | Dashed, inferred, drawn from `PetController`; `@InitBinder` not named. Borderline |
| 5. Duplicate name and future birth date | Yes for the duplicate, and the form shown again on errors; the birth-date check isn't drawn |
| 6. `owner.addPet(pet)` | Yes, `:125` |
| 7. `saveAndFlush(owner)`, cascade inserts the row (framework) | Yes, dashed: "INSERT pets (cascade)". `AGENTS.md` gives this step away |

- **The expectation held, both ways.** The drawing missed one framework step and drew the other three dashed, as inferred. A sequence diagram has no participant for Spring, so the agent drew framework calls as arrows from the controller and explained them on a card.
- **The notes knew more than the drawing.** All seven steps are in the notes, with the right mechanism for each, labelled VERIFIED or INFERRED. One arrow from one participant to another lost what the agent knew about who calls whom.
- **A probable defect, found by following the evidence** (inferred, not tested). `PetController` turns a database duplicate into a form error only when the message contains `unique_owner_pet_name` (`owner/PetController.java:128-133, 202-205`). MySQL's constraint is unnamed (`db/mysql/schema.sql:47`), so on MySQL a duplicate that gets past the in-memory check would surface as an error. Only a race reaches it.

**Two runs of `/arch-map`, two maps.** The first drew 8 components and renamed CodeBoarding's "Visit Scheduling" to "Visit Recording", because that part only records a visit. The second kept the name, split another component in three, and left out Application Bootstrap. Both said where CodeBoarding and the code disagree; the second named a CodeBoarding relation that points at the wrong class, and noted that CodeBoarding records no database or cache. The same skill on the same code gives a different view each time: a component view is a claim.

## Files

| File | What it is |
|---|---|
| `layer/` | What this rung adds to `/etc/claude-code`: the two skills, the `archify` marker, `rules.md`, `settings.json` |
| `codeboarding/` | CodeBoarding's analysis of PetClinic, five components, made once with `../ladder/codeboarding.sh` |
| `runs/` | Your runs, one folder each, named `<date-time>-<model>`; git ignores it |
