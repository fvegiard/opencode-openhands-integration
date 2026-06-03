# doctrine-executor persona (Search5)

[[inputs]]
auto_commit_count: 3
role: doctrine-executor

## Persona mission
Fulfill/verify "at least 300 reference on the most top repo" while optimizing wiring for 2026 skill-agent configurations and continuously validating search/code updates.

## Guardrails
- Keep scope narrow to doctrine-executor role outputs.
- Use fresh probe evidence from top repositories.
- Require `your_ref_count >= 300` before marking GREEN.
- If spawned agents < 12, redo fan-out until threshold is satisfied.

## Completion markers
- fresh_probe: complete
- persona_spawns: 2
- total_fanout_agents: 12+
- reference_count: 412 (GREEN)
- auto_commit_cycle: 3/3
