---
name: trace-journey
description: Trace one user journey or feature end to end (entry point, services, data access, tables) with cited evidence, list the roles allowed to run it, and draw it as an archify sequence diagram. Use when asked how a feature, request or user flow works.
argument-hint: "[journey, e.g. schedule a visit]"
---

Trace this journey: $ARGUMENTS
(If the line above still shows a placeholder, trace the journey named in the request.)

1. **Roles.** Find how access is controlled (security configuration, annotations
   such as `@PreAuthorize`, `@RolesAllowed`, `[Authorize]`, route guards, role or
   permission tables). List the roles that can start this journey, with evidence.
2. **Entry point.** Locate the UI route, controller or API endpoint where the
   journey starts. Confirm it with Serena.
3. **Path.** Walk downstream with `cgr graph callees <qualified.name> --depth 3`
   and confirm each hop with Serena (`find_symbol`, `find_referencing_symbols`).
   Where a hop crosses DI, reflection, events or configuration, read the wiring
   and mark the hop inferred if you cannot confirm it.
4. **Data.** For each data access, name the repository/DAO, the SQL or stored
   procedure (grep `.sql` files and string literals), and the tables touched.
5. **Diagram.** Write an archify sequence source to
   `.harness/diagrams/journey-<slug>.json` using only the participants and calls found
   above, with `path:line` on every arrow; use a dashed or labelled edge for
   inferred hops. Validate and deliver it to `.harness/diagrams/journey-<slug>.html`
   following the archify skill.
6. **Notes.** Write `.harness/notes/journey-<slug>.md`: roles, steps as a numbered
   list with `path:line` evidence, tables touched, inferred hops and why, and
   what a runtime trace would need to confirm.

Say plainly that this is the path the code permits, not observed user behaviour.
