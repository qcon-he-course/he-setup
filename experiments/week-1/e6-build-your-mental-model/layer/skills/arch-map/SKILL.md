---
name: arch-map
description: Draw an evidence-backed component view of the repository with archify, built from CodeBoarding's components and the code graph's dependencies, with a table tying every node and edge to evidence. Use when asked for an architecture overview or a component view.
disable-model-invocation: true
---

1. Read CodeBoarding's analysis in `.harness/codeboarding/` (`analysis.json` and the
   Markdown files). If it is missing, say so and build the components from the
   top-level packages instead.
2. Choose 6 to 10 components from the analysis. Add the external systems found
   in configuration, such as the database.
3. For each dependency you intend to draw, confirm it with
   `cgr graph importers`, `cgr graph callers` or Serena references. Drop edges
   you cannot confirm, or keep them marked INFERRED.
4. Write the archify architecture source to `.harness/diagrams/architecture.json`
   with `meta.quality_profile: "showcase"`, then validate and render it to
   `.harness/diagrams/architecture.html` following the archify skill.
5. Write `.harness/diagrams/architecture-evidence.md`: one row per node and edge
   with its source (CodeBoarding component id, package, graph query or
   `path:line`) and whether it is VERIFIED or INFERRED.

CodeBoarding names its components with a model, so treat the names as a
hypothesis and say where the code disagrees.
