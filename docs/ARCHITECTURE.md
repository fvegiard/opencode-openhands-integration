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
