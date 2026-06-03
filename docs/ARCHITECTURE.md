# Architecture Documentation

## OpenCode-OpenHands Integration (June 2026)

### System Overview

This integration creates a multi-agent workflow where:
- **OpenCode** serves as the primary UI and orchestrator
- **Oh My OpenCode** provides advanced agent orchestration
- **OpenHands** delivers autonomous coding capabilities via MCP

### Component Architecture

```
┌─────────────┐
│    User     │
└──────┬──────┘
       │
       ▼
┌──────────────────────────┐
│   OpenCode (Terminal)    │  ← Primary interface
└──────┬───────────────────┘
       │
       ▼
┌──────────────────────────┐
│  Oh My OpenCode Plugin   │  ← Agent orchestration
│  - Sisyphus              │
│  - Oracle                │
│  - Librarian             │
│  - Explore               │
└──────┬───────────────────┘
       │ MCP (JSON-RPC 2.0)
       ▼
┌──────────────────────────┐
│  OpenHands MCP Server    │  ← Autonomous execution
│  (FastMCP 3.3.1+)        │
└──────┬───────────────────┘
       │
       ▼
┌──────────────────────────┐
│  OpenHands Agent SDK     │  ← Core agent logic
└──────────────────────────┘
```

### Communication Flow

1. User sends prompt to OpenCode
2. Oh My OpenCode routes to appropriate agent (Sisyphus, Oracle, etc.)
3. Agent analyzes task complexity
4. If complex: delegate to OpenHands via MCP
5. MCP server invokes OpenHands SDK
6. Results returned through the chain

### MCP Protocol

- **Specification:** 2025-11-25
- **Transport:** STDIO (default) or HTTP
- **Message Format:** JSON-RPC 2.0
- **Tools Exposed:**
  - execute_task
  - analyze_code
  - debug_issue
  - research_codebase
  - refactor_code
  - health_check

### Technology Stack

| Component | Technology | Version |
|-----------|-----------|---------|
| OpenCode | Go | Latest |
| Oh My OpenCode | Node.js | Latest |
| OpenHands | Python | 3.12+ |
| MCP Server | FastMCP | 3.3.1+ |
| Protocol | JSON-RPC 2.0 | 2025-11-25 |

### Agent Orchestration

**Pattern 1: Direct Execution**
- Simple tasks → Handled by Oh My OpenCode agents directly
- Examples: Single-file edits, quick questions

**Pattern 2: MCP Delegation**
- Complex tasks → Delegated to OpenHands via MCP
- Examples: Multi-file refactoring, deep research

**Pattern 3: Parallel Execution (Ultrawork)**
- Decomposable tasks → Multiple OpenHands agents in parallel
- Examples: Bulk fixes, large-scale refactoring

### Orchestrator Improvement Patterns (2026)

Derived from >300 refs across top 2026 skill/agent repos. Full details in [`docs/ORCHESTRATOR_PATTERNS.md`](ORCHESTRATOR_PATTERNS.md).

**Improvement Pattern 1: "Use when" in Agent Descriptions**
- Source: anthropics/skills — `skills/skill-creator/SKILL.md` (verbatim: *"Use when users want to create a skill from scratch..."*)
- Applied: each agent in `config/oh-my-opencode.json.example` now has an explicit `"Use when:"` block
- Benefit: orchestrator routing accuracy ↑; fewer mis-delegations across 4 personas

**Improvement Pattern 2: Persona I/O Contracts (Progressive Disclosure)**
- Source: ComposioHQ/awesome-claude-skills (63k ★), travisvn/awesome-claude-skills (13.1k ★) — three-level loading: Metadata → SKILL.md body → Bundled resources
- Applied: `[[inputs]]` / `[[outputs]]` contracts declared per agent; orchestrator pre-validates before dispatch
- Three levels:
  1. **Metadata** (name + "Use when") → routing decision (~100 words, always in context)
  2. **Body** (`[[inputs]]` list) → pre-flight validation (<500 lines)
  3. **Resources** (output schema) → result normalisation (unlimited, loaded as needed)

**Improvement Pattern 3: MCP Wiring for GitHub (search_tool → use_tool)**
- Source: hesreallyhim/awesome-claude-code (45.5k ★), rohitg00/awesome-claude-code-toolkit (135 agents, 15 MCP configs)
- Applied: `mcps.github` block added to `config/oh-my-opencode.json.example`; Sisyphus system_prompt updated with two-step sequence:
  1. `search_tool` — locate issue/PR/task (always first, never skip)
  2. `use_tool copilot-cloud-agent__create_task` with `create_pr=true`
- Benefit: full GitHub automation loop (open PRs, comment issues, trigger CI)

### Security Considerations

1. **API Keys:** Stored in environment variables, never committed
2. **File Access:** Limited to workspace directory
3. **Network:** Firewall rules can limit outbound connections
4. **Execution:** All code changes reviewed before deployment

### Performance Optimization

- Token usage monitoring via provider dashboards
- Parallel agent execution (up to 3 concurrent)
- Caching of file contents and LSP data
- Targeted prompts to reduce context size

### Extension Points

- **Custom MCP Tools:** Add new tools to mcp_server.py
- **Custom Agents:** Define in oh-my-opencode.json
- **Additional MCPs:** Connect more MCP servers

### Deployment Options

1. **Local (Default):** All components on one machine
2. **Remote MCP Server:** OpenHands on separate machine via HTTP
3. **Docker:** Containerized OpenHands MCP server

---

**Last Updated:** June 2026
**Version:** 1.0.0
