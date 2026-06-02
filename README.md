# OpenCode + OpenHands Integration via MCP

**Production-ready integration connecting OpenCode + Oh My OpenCode to OpenHands via Model Context Protocol (MCP)**

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Python 3.12+](https://img.shields.io/badge/python-3.12+-blue.svg)](https://www.python.org/downloads/)
[![MCP Spec 2025-11-25](https://img.shields.io/badge/MCP-2025--11--25-green.svg)](https://modelcontextprotocol.io/)
[![FastMCP 3.3.1+](https://img.shields.io/badge/FastMCP-3.3.1+-orange.svg)](https://github.com/jlowin/fastmcp)

> **June 2026**: A cutting-edge agentic workflow where OpenCode (with Oh My OpenCode plugin) acts as your primary coding interface, using OpenHands as an MCP server to provide advanced AI-driven development capabilities.

---

## 🎯 What You Get

- **OpenCode's Sub-Agents** (Sisyphus, Oracle, Librarian, Explore) can call OpenHands for:
  - Multi-file refactoring across large repositories
  - Deep codebase research (SWE-Bench-style tasks)
  - Complex debugging workflows
  - Autonomous issue resolution
  
- **OpenHands as MCP Server**: Composable Python service that OpenCode invokes on-demand
- **Oh My OpenCode's Ultrawork Mode**: Orchestrate parallel calls to OpenHands for different subtasks
- **77.6% SWE-Bench Score**: Industry-leading autonomous coding performance

---

## 🏗️ Architecture

```
┌─────────────────────────────────────────┐
│  YOU (Project Manager / Vibe Coder)    │
└──────────────┬──────────────────────────┘
               │
               ▼
┌──────────────────────────────────────────┐
│  OpenCode (UI / Primary Agent)           │
│  + Oh My OpenCode Plugin                 │
│    - Sisyphus (main agent)               │
│    - Oracle, Librarian, Explore agents   │
│    - LSP/AST tools, MCPs (Exa, grep.app) │
└──────────────┬───────────────────────────┘
               │ MCP Client
               │ (connects via STDIO/HTTP)
               ▼
┌──────────────────────────────────────────┐
│  OpenHands MCP Server                    │
│  (Python MCP Server using FastMCP)       │
│    - Exposes tools:                      │
│      • execute_task(task_description)    │
│      • analyze_code(repo_path)           │
│      • debug_issue(stack_trace)          │
│      • research_codebase(query)          │
│      • refactor_code(description)        │
│    - Powered by OpenHands Agent SDK      │
└──────────────────────────────────────────┘
```

---

## 🚀 Quick Start

### Prerequisites

- **Python 3.12+** with `uv` (Python package manager)
- **Node.js/npm** (for OpenCode)
- **Git**
- **API Keys**: Anthropic Claude, OpenAI (optional)

### Installation

```bash
# Clone this repository
git clone https://github.com/fvegiard/opencode-openhands-integration.git
cd opencode-openhands-integration

# Run automated setup
bash setup.sh

# Or manual installation (see below)
```

### Manual Installation

#### 1. Install OpenCode

```bash
# macOS/Linux via Homebrew
brew install anomalyco/tap/opencode

# Or universal install
curl -fsSL https://opencode.ai/install | bash

# Verify
opencode --version
```

#### 2. Install Oh My OpenCode Plugin

```bash
# In OpenCode, run:
# (OpenCode will handle installation)
```

Or manually edit `~/.config/opencode/opencode.json`:

```json
{
  "plugins": ["oh-my-opencode"]
}
```

#### 3. Install OpenHands SDK

```bash
# Clone OpenHands
git clone https://github.com/fvegiard/OpenHands.git ~/openhands-sdk
cd ~/openhands-sdk

# Install with uv
curl -LsSf https://astral.sh/uv/install.sh | sh
uv venv
source .venv/bin/activate
uv pip install -e .
```

#### 4. Install MCP Server Dependencies

```bash
cd /path/to/opencode-openhands-integration

# Create virtual environment
uv venv
source .venv/bin/activate

# Install dependencies
uv pip install -r requirements.txt
```

#### 5. Configure Oh My OpenCode

Copy the example configuration:

```bash
# Get absolute path to mcp_server.py
pwd
# Example: /home/user/opencode-openhands-integration

# Create Oh My OpenCode config
mkdir -p ~/.config/opencode
cp config/oh-my-opencode.json.example ~/.config/opencode/oh-my-opencode.json

# Edit the config and update the path to mcp_server.py
nano ~/.config/opencode/oh-my-opencode.json
```

Update the `openhands` MCP section with your absolute path:

```json
{
  "mcps": {
    "openhands": {
      "command": "python",
      "args": ["/home/user/opencode-openhands-integration/mcp_server.py"],
      "transport": "stdio"
    }
  }
}
```

#### 6. Set API Keys

```bash
# Copy environment template
cp .env.example .env

# Edit and add your keys
nano .env

# Or export directly
export ANTHROPIC_API_KEY="sk-ant-your-key-here"
export OPENAI_API_KEY="sk-your-key-here"
```

#### 7. Start MCP Server

```bash
cd /path/to/opencode-openhands-integration
source .venv/bin/activate
python mcp_server.py
```

Keep this terminal open! OpenCode will connect when needed.

---

## ✅ Verify Installation

Use the checks below (or jump to the full "MCP Validation" section below for the one-command `scripts/validate_mcps.sh --strict`).

### Test MCP Connection

**Via OpenCode + Oh My OpenCode:**
In OpenCode, run:
```
@openhands health_check
```

**Expected output:**
```
✓ OpenHands MCP Server is running with OpenHands SDK (v3.0 - June 2026)
```

**Via Claude Code (`claude mcp`):**
```bash
claude mcp list
claude mcp get openhands   # if you registered the local one too
```

**Full validation (recommended):**
See dedicated "MCP Validation" section below (after this Verify section), which runs `bash scripts/validate_mcps.sh --strict` (covers direct health + claude registry + GitHub if enabled).

### Test Task Execution

```
@openhands execute_task: Create a Python hello world script
```

---

## 🧪 MCP Validation

Run the dedicated validator script for a full matrix of checks (prereqs, repo MCP direct health via `health_check`, `claude mcp list` registry, GitHub smoke if configured, OpenCode config consistency, etc.):

```bash
bash scripts/validate_mcps.sh --strict
```

Verbose + strict (for CI or full gate):
```bash
bash scripts/validate_mcps.sh --verbose --strict
```

**Prerequisites** (enforced by script): `claude` (Claude Code), `python3 >= 3.12`, `uv`. Optional: `jq`, `gk` (GitKraken), `docker`.

See the complete validation matrix and check details in [docs/MCP_ENABLEMENT_PLAN.md](docs/MCP_ENABLEMENT_PLAN.md) (section 7).

**Copy-paste manual equivalents** (also exercised by the validator):

```bash
# 1. Repo setup + direct OpenHands MCP health (MOCK is acceptable until ~/openhands-sdk present)
source .venv/bin/activate || uv venv && source .venv/bin/activate
uv pip install -r requirements.txt -q
python -m py_compile mcp_server.py
python -c "
from mcp_server import health_check
h = health_check()
print(h)
" | grep -q "running" && echo "✓ direct health OK" || echo "✗ health fail"

# 2. Claude MCP registry
CLIST=$(claude mcp list 2>&1 || true)
echo "$CLIST" | grep -qi 'github' || echo "WARN: no 'github' MCP registered"
echo "$CLIST" | grep -qi 'GitKraken\|git-mcp' || echo "WARN: no git MCP proxy"
echo "$CLIST"

# 3. (if github registered) GitHub read smoke via claude
if echo "$CLIST" | grep -qi 'github'; then
  claude --print --allow-dangerously-skip-permissions "Use the github MCP. List the default branch for repo fvegiard/opencode-openhands-integration. Be terse." 2>&1 | cat
fi
```

**GitHub MCP (for authenticated remote GitHub ops in Claude):**
- Requires a GitHub Personal Access Token (PAT).
- Create one (fine-grained recommended): https://github.com/settings/personal-access-tokens/new
- Minimum scopes for this integration: `repo` (Contents: Read & write or Read), `issues` (Read), `pull_requests` (Read).
- Classic tokens: https://github.com/settings/tokens (select `repo` scope).
- Register (example; use your PAT):
  ```bash
  export GITHUB_PERSONAL_ACCESS_TOKEN=ghp_yourpat...
  claude mcp add --transport http github https://api.githubcopilot.com/mcp/ --header "Authorization: Bearer $GITHUB_PERSONAL_ACCESS_TOKEN"
  claude mcp list
  claude mcp get github
  ```
- The validator will warn/skip smoke if no PAT or no "github" entry (GitKraken/git-mcp provide local git fallbacks with many overlapping tools).
- Remove if needed: `claude mcp remove github`

Run the validator after any MCP registration changes.

---

## 📖 Usage Examples

### Example 1: Simple Task Delegation

```
ulw

Create a Python FastAPI hello world app with:
- /health endpoint
- /user/{id} endpoint with Pydantic validation
- Proper error handling
- Deploy-ready with Docker

Use @openhands to implement the core logic if needed.
```

**What happens:**
1. Sisyphus (Oh My OpenCode's main agent) analyzes the task
2. Recognizes it's a multi-file task → delegates to OpenHands via MCP
3. OpenHands executes the task autonomously
4. Returns results to Sisyphus
5. Sisyphus presents final code to you

### Example 2: Deep Codebase Research

```
@openhands research_codebase: How does authentication flow from login to JWT validation in this repo?
```

**Expected output:**
```
✓ Research completed

OpenHands traced the authentication flow:
1. Login request → /api/auth/login (routes/auth.py:45)
2. Validates credentials → services/auth_service.py:120
3. Generates JWT → utils/jwt_helper.py:78
4. Returns token → middleware/auth_middleware.py:56 validates on subsequent requests

[Full detailed trace with file paths and line numbers]
```

### Example 3: Bug Debugging

```
@openhands debug_issue: Getting "NoneType object has no attribute 'id'" error when loading user profile

Stack trace:
  File "app/routes/profile.py", line 89, in get_profile
    user_id = current_user.id
AttributeError: 'NoneType' object has no attribute 'id'
```

**Expected output:**
```
✓ Debug analysis complete

Root Cause:
- JWT middleware (middleware/auth_middleware.py:67) returns None when token is expired
- get_profile route doesn't check if current_user is None

Fix:
1. Add null check in get_profile
2. Return 401 if current_user is None
3. Add token expiry validation in middleware

[Suggested code patches provided]
```

### Example 4: Code Analysis

```
@openhands analyze_code: src/security/auth.py
```

### Example 5: Refactoring

```
@openhands refactor_code: Extract authentication logic into a separate service class
```

---

## 🛠️ Available MCP Tools

The OpenHands MCP Server exposes the following tools:

| Tool | Description | Use Cases |
|------|-------------|-----------|
| `execute_task` | Execute development tasks autonomously | Feature implementation, bug fixes, code generation |
| `analyze_code` | Analyze code for issues and improvements | Code review, security audit, performance analysis |
| `debug_issue` | Debug and diagnose issues | Bug investigation, stack trace analysis, error diagnosis |
| `research_codebase` | Research and understand codebases | Architecture discovery, flow tracing, documentation |
| `refactor_code` | Refactor code while preserving behavior | Code cleanup, architecture improvements, tech debt reduction |
| `health_check` | Check server health | Monitoring, debugging connections |
| `get_capabilities` | List all available capabilities | Discovery, documentation |

---

## 📁 Project Structure

```
opencode-openhands-integration/
├── mcp_server.py              # Main MCP server implementation
├── setup.sh                   # Automated setup script
├── requirements.txt           # Python dependencies
├── pyproject.toml            # Python project configuration
├── .env.example              # Environment variables template
├── .gitignore                # Git ignore rules
├── config/
│   ├── opencode.json.example           # OpenCode config template
│   └── oh-my-opencode.json.example     # Oh My OpenCode config template
├── docs/
│   ├── ARCHITECTURE.md       # Detailed architecture
│   ├── TROUBLESHOOTING.md   # Common issues and solutions
│   └── EXAMPLES.md          # More usage examples
└── README.md                # This file
```

---

## 🔧 Configuration

### OpenCode Configuration

Location: `~/.config/opencode/opencode.json`

```json
{
  "plugins": ["oh-my-opencode"],
  "defaultModel": "anthropic/claude-sonnet-4-20250514"
}
```

### Oh My OpenCode Configuration

Location: `~/.config/opencode/oh-my-opencode.json`

See `config/oh-my-opencode.json.example` for a complete example with:
- OpenHands MCP integration
- Agent configurations (Sisyphus, Oracle, Librarian, Explore)
- Ultrawork mode settings
- Other MCP integrations (websearch, context7, grep.app)

### Environment Variables

See `.env.example` for all configuration options:

```bash
ANTHROPIC_API_KEY=sk-ant-your-key-here
OPENAI_API_KEY=sk-your-key-here
MCP_TRANSPORT=stdio
MCP_PORT=8765
```

---

## 🐛 Troubleshooting

### MCP Server Not Connecting

1. **Check server is running:**
   ```bash
   ps aux | grep mcp_server.py
   ```

2. **Check logs:**
   ```bash
   tail -f ~/.config/opencode/logs/mcp.log
   ```

3. **Verify configuration path:**
   ```bash
   cat ~/.config/opencode/oh-my-opencode.json | grep mcp_server.py
   ```

### OpenHands SDK Not Available

If you see "MOCK MODE" in health check:

1. **Install OpenHands SDK:**
   ```bash
   cd ~/openhands-sdk
   source .venv/bin/activate
   uv pip install -e .
   ```

2. **Restart MCP server**

### API Rate Limits

OpenHands can use significant tokens on large tasks:

1. **Monitor usage** in your provider's dashboard
2. **Adjust `max_iterations`** in tool calls
3. **Use cheaper models** for simple tasks

### Oh My OpenCode Not Loading

1. **Check OpenCode version:**
   ```bash
   opencode --version
   ```

2. **Reinstall plugin:**
   ```
   # In OpenCode
   /plugins uninstall oh-my-opencode
   /plugins install oh-my-opencode
   ```

---

## 🎓 Real-World Workflows

### 1. "Build a full-stack app from scratch"

- OpenCode's Sisyphus delegates to OpenHands for backend scaffolding
- Oracle (GPT 5.2) handles architecture decisions
- Frontend Engineer (Gemini 3 Pro) builds UI
- **Result:** Complete app in one `ulw` prompt

### 2. "Fix all ESLint warnings in this 50k-line repo"

- Sisyphus spawns parallel OpenHands tasks (one per module)
- Each OpenHands agent fixes its assigned files
- Sisyphus aggregates results
- **Result:** Done in <1 hour (vs. days manually)

### 3. "Research how library X implements feature Y"

- Librarian searches official docs (via Context7 MCP)
- Explore scans GitHub implementations (via grep.app MCP)
- OpenHands clones + analyzes top 3 repos
- **Result:** Comprehensive research report with code examples

### 4. "Debug this production error"

- Paste stack trace
- OpenHands traces through your codebase
- Oracle provides architectural fix suggestions
- **Result:** Root cause + patch in minutes

---

## 🌟 Best Practices

### When to Use OpenHands MCP

✅ **Use OpenHands for:**
- Multi-file refactoring
- Complex debugging with stack traces
- Deep codebase research
- Autonomous feature implementation
- Large-scale code analysis

❌ **Don't use OpenHands for:**
- Simple file edits (use OpenCode directly)
- Quick questions (use Librarian or Explore)
- UI-only changes (use Frontend Engineer agent)

### Performance Tips

1. **Start with smaller `max_iterations`** (10-15) for exploration
2. **Use specific prompts** with file paths when possible
3. **Leverage Oh My OpenCode's parallel agents** for independent tasks
4. **Monitor token usage** on large repositories

---

## 📚 Resources

- **OpenCode Docs:** https://opencode.ai/docs
- **Oh My OpenCode Docs:** https://github.com/code-yeongyu/oh-my-opencode/tree/master/docs
- **OpenHands SDK Docs:** https://docs.openhands.dev/sdk
- **MCP Specification:** https://modelcontextprotocol.io/docs/sdk
- **FastMCP Documentation:** https://gofastmcp.com
- **Ultrawork Manifesto:** https://github.com/code-yeongyu/oh-my-opencode/blob/master/docs/ultrawork-manifesto.md

---

## 🤝 Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## ⚠️ Important Notes

### API Keys Required

You need API keys for LLMs. Set these in your environment:

```bash
export ANTHROPIC_API_KEY="sk-ant-..."
export OPENAI_API_KEY="sk-..."
```

### OpenHands Performance

OpenHands agents can use significant tokens (especially on large repos). Monitor usage if on paid APIs.

### Oh My OpenCode Licensing

Oh My OpenCode uses SUL-1.0 license (source-available, not MIT). Review license if deploying commercially.

### Resource Usage

Running 3+ agents in parallel (Oh My OpenCode + OpenHands) can be CPU/memory-intensive.

**Recommended:** 16GB+ RAM

---

## 🎉 You Now Have...

A **2026-grade agentic coding setup** where:
- OpenCode orchestrates multiple AI agents
- OpenHands provides industrial-strength task execution via MCP
- All components are composable and extensible

**This is the future of software development—autonomous, composable, and ridiculously productive.**

---

**Built with ❤️ by fvegiard**
