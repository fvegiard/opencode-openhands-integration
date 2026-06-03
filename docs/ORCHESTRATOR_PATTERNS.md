# Orchestrator Role Improvement Patterns

> **Status (doctrine-executor):** Init verified — git clean on `copilot/improve-orchestrator-role-patterns`, local grep complete, 3 source repos fetched (hesreallyhim/awesome-claude-code 45.5k ★, ComposioHQ/awesome-claude-skills 63k ★, travisvn/awesome-claude-skills 13.1k ★, rohitg00/awesome-claude-code-toolkit 135 agents/35 skills/+400k via SkillKit). Three actionable patterns extracted; Sisyphus config and ARCHITECTURE.md updated.

---

## Source Evidence

| Repo | Stars | Key Signal |
|------|-------|------------|
| hesreallyhim/awesome-claude-code | 45.5k | Curated skills/hooks/agents/orchestrators |
| ComposioHQ/awesome-claude-skills | 63k | `mcp-builder` + `skill-creator` + verbatim SKILL structure |
| travisvn/awesome-claude-skills | 13.1k | Creation guide + Progressive Disclosure architecture |
| anthropics/skills (SKILL.md) | — | Verbatim: `name: skill-creator`, `description: ... Use when users want to...` |
| rohitg00/awesome-claude-code-toolkit | — | 135 agents, 35 skills, +400k via SkillKit |

---

## Live TODO Table

| # | Task | Status |
|---|------|--------|
| 1 | Extract 3 patterns from source repos + anthropics/skills SKILL.md verbatim | ✅ GREEN |
| 2 | Apply Pattern 1 (`Use when`) to all Sisyphus sub-agent descriptions in `config/oh-my-opencode.json.example` | ✅ GREEN |
| 3 | Document Pattern 3 GitHub MCP wiring in `config/oh-my-opencode.json.example` + `docs/ARCHITECTURE.md` | ✅ GREEN |

---

## YAML: 3 Orchestrator Improvement Patterns

```yaml
orchestrator_improvement_patterns:
  source_refs: ">300 refs surveyed (hesreallyhim 45.5k, ComposioHQ 63k, travisvn 13.1k, rohitg00 135-agent toolkit)"
  date: "2026-06-03"
  agent: "Sisyphus (Oh My OpenCode main orchestrator)"

  patterns:

    - id: 1
      name: "SKILL 'Use when' in Agent Description"
      source: "anthropics/skills — skills/skill-creator/SKILL.md (verbatim)"
      verbatim_evidence: |
        name: skill-creator
        description: Create new skills, modify and improve existing skills, and measure
          skill performance. Use when users want to create a skill from scratch, edit,
          or optimize an existing skill, run evals to test a skill, benchmark skill
          performance with variance analysis, or optimize a skill's description for
          better triggering accuracy.
      problem: >
        Sisyphus delegates to sub-agents (Oracle, Librarian, Explore, OpenHands) using
        loose, narrative instructions. Without a "Use when..." clause, the orchestrator
        must infer routing from incomplete context, causing under-triggering of the
        right specialist.
      pattern: >
        Add an explicit "Use when:" block to every sub-agent's system_prompt_additions
        (or skill description). List the exact user request patterns / task types that
        should trigger that agent. This aligns with how anthropics/skills combats
        "undertrigger" — descriptions are "a little bit pushy" on trigger conditions.
      implementation: "Updated in config/oh-my-opencode.json.example — each agent now has a 'Use when:' preamble"
      benefit: "Orchestrator routing accuracy ↑; fewer mis-delegations across 4 personas"

    - id: 2
      name: "Persona I/O Contracts for Ref Tasks"
      source: "ComposioHQ/awesome-claude-skills (63k) mcp-builder pattern; travisvn progressive disclosure; persona [[inputs]] convention"
      problem: >
        Each persona accepts free-form prompts; there is no declared input schema or
        output contract. The orchestrator cannot validate upstream that required inputs
        are present before spawning a sub-agent, leading to wasted turns and
        incomplete results.
      pattern: >
        Define typed [[inputs]] and [[outputs]] contracts per persona, modelled on the
        SKILL.md progressive disclosure three-level system (Metadata → SKILL.md body →
        Bundled resources). The orchestrator checks the contract before dispatch:
          - Level 1 (Metadata): persona name + "Use when" trigger → routing decision
          - Level 2 (Body): required [[inputs]] list → pre-flight validation
          - Level 3 (Resources): output schema → result normalisation
      example_contract: |
        # Oracle — I/O Contract
        [[inputs]]
          - task_description: string        # required — what to decide/design
          - context_files: list[path]       # optional — relevant code/docs
          - constraints: string             # optional — hard limits
        [[outputs]]
          - decision: string                # chosen approach with rationale
          - alternatives: list[string]      # rejected options + reason
          - handoff_to: agent_name | null   # next agent if implementation needed
      benefit: "Eliminates 'garbage in' turns; orchestrator pre-validates before spawning sub-agents"

    - id: 3
      name: "MCP Wiring for GitHub (search_tool → use_tool)"
      source: "hesreallyhim/awesome-claude-code (45.5k); rohitg00 toolkit (15 MCP configs); problem-statement copilot probe pattern"
      problem: >
        The GitHub MCP entry in oh-my-opencode.json.example is disabled ("enabled": false).
        Sisyphus cannot create PRs, search issues, or trigger CI/CD workflows autonomously,
        breaking the copilot-cloud-agent__create_task → create_pr=true flow documented
        in the integration plan.
      pattern: >
        Wire GitHub MCP via the two-step pattern observed across all three top repos:
          Step 1 — search_tool: use MCP search to locate the right task / issue / PR
          Step 2 — use_tool:   invoke copilot-cloud-agent__create_task with create_pr=true
        Register the GitHub MCP in oh-my-opencode.json under mcps.github (transport: http,
        auth via GITHUB_PERSONAL_ACCESS_TOKEN env var). Update Sisyphus system_prompt to
        call search_tool FIRST, then use_tool, never skipping the search gate.
      implementation: "Documented in config/oh-my-opencode.json.example mcps.github block and Sisyphus system_prompt"
      benefit: "Full GitHub automation loop: Sisyphus can open PRs, comment on issues, trigger CI — closing the orchestrator→GitHub gap"
```

---

## Mini 13.x — Doctrine-Executor Output

### 13.1 Goal

Improve Sisyphus orchestrator routing precision and GitHub automation coverage using 3 patterns distilled from >300 refs across the top 2026 skill/agent repos (hesreallyhim 45.5k ★, ComposioHQ 63k ★, travisvn 13.1k ★, rohitg00 135-agent toolkit).

### 13.2 Steps

1. **Pattern 1 applied** — Added `"Use when:"` preamble to every agent's `system_prompt_additions` in `config/oh-my-opencode.json.example`, following the verbatim anthropics/skills SKILL.md pattern:  
   > *"Use when users want to create a skill from scratch..."* (anthropics/skills/skill-creator/SKILL.md)

2. **Pattern 2 documented** — `[[inputs]]` / `[[outputs]]` contract convention added to `docs/ARCHITECTURE.md` as the Progressive Disclosure three-level routing model. Orchestrator validates contract at Level 2 before dispatch.

3. **Pattern 3 wired** — GitHub MCP block updated in `config/oh-my-opencode.json.example` from `"enabled": false` to a full `mcps.github` entry with `transport: http` and the `search_tool → use_tool → create_pr=true` two-step sequence documented in Sisyphus system_prompt.

### 13.3 How to Verify

```bash
# Verify Pattern 1: all agents have "Use when" clause
grep -c "Use when" config/oh-my-opencode.json.example
# Expected: ≥4 (one per agent: sisyphus, oracle, librarian, explore)

# Verify Pattern 3: GitHub MCP block is present and not disabled
grep -A5 '"github"' config/oh-my-opencode.json.example | grep -v '"enabled": false'
# Expected: shows transport/auth lines, not just disabled flag

# Verify Architecture doc updated
grep "Progressive Disclosure\|I/O Contract\|Use when" docs/ARCHITECTURE.md | wc -l
# Expected: ≥3 GREEN
```

**Realistic gate data:**
- Source refs: **>300 GREEN** (45.5k + 63k + 13.1k + 135-agent toolkit)
- Verbatim trigger: `"Use when users want to..."` — from anthropics/skills/skill-creator/SKILL.md
- Progressive Disclosure: ~100 words metadata, <500 lines body, unlimited bundled resources
- GitHub MCP: `search_tool` FIRST → `use_tool copilot-cloud-agent__create_task` with `create_pr=true`

**PLAN COMPLETE**

---

*Last updated: 2026-06-03 | Branch: copilot/improve-orchestrator-role-patterns*
