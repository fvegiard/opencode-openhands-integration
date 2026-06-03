# MCP Enablement Plan — OpenCode-OpenHands Integration
> doctrine-executor | Iter 5/6 | June 2026

## Overview

This document covers the full MCP enablement matrix for the
`fvegiard/opencode-openhands-integration` repository.
It is referenced by `scripts/validate_mcps.sh` for gate verification.

---

## §1 — Scope

Enable and validate the following MCP surfaces:

| MCP Surface | Transport | Status |
|-------------|-----------|--------|
| OpenHands (local) | `stdio` | ✓ Active (MOCK until SDK installed) |
| GitHub Copilot MCP | `http` | ✓ via `claude mcp add --transport http` |
| git-mcp / GitKraken | `stdio` / `gk mcp` | ⚠ Optional (local git proxy) |
| websearch | built-in | ✓ Oh My OpenCode |
| context7 | built-in | ✓ Oh My OpenCode |
| grep.app | built-in | ✓ Oh My OpenCode |

---

## §2 — Prerequisites

```bash
# Required
python3 >= 3.12   # python3 --version
uv                # curl -LsSf https://astral.sh/uv/install.sh | sh
claude            # Claude Code CLI

# Optional but recommended
jq                # JSON validation
gk                # GitKraken CLI (git proxy)
docker            # for containerised OpenHands
```

---

## §3 — OpenHands MCP Setup

```bash
# 1. Create virtual environment
uv venv
source .venv/bin/activate

# 2. Install dependencies
uv pip install -r requirements.txt

# 3. Verify server
python -c "from mcp_server import health_check; print(health_check())"
# Expected: ✓ OpenHands MCP Server is running in MOCK mode (v3.0 - June 2026)

# 4. Register to Oh My OpenCode (edit config path)
cp config/oh-my-opencode.json.example ~/.config/opencode/oh-my-opencode.json
# Edit: replace /absolute/path/to/opencode-openhands-integration/mcp_server.py
#       with the actual absolute path
```

---

## §4 — GitHub MCP Setup (Claude Code side)

```bash
# Create a PAT at: https://github.com/settings/personal-access-tokens/new
# Scopes: repo (Contents: Read), issues (Read), pull_requests (Read)

export GITHUB_PERSONAL_ACCESS_TOKEN=ghp_yourpat...

# Register
claude mcp add --transport http github https://api.githubcopilot.com/mcp/ \
  --header "Authorization: ******"

# Verify
claude mcp list        # should show 'github'
claude mcp get github  # should show URL + auth header (token redacted)
```

---

## §5 — Local Git MCP (proxy for GitKraken / git-mcp)

### Option A: GitKraken CLI

```bash
gk mcp   # starts MCP server on stdio; 27 git tools
```

### Option B: git-mcp via uvx

```bash
uvx mcp-server-git   # starts git MCP server; read-only by default
```

Register whichever is available in `~/.config/opencode/oh-my-opencode.json`.

---

## §5.4 — Validation Criteria

The validator (`scripts/validate_mcps.sh`) checks:

1. **Prerequisites**: `claude`, `python3 >= 3.12`, `uv` present.
2. **OpenHands health**: `health_check()` returns expected string (MOCK ok).
3. **Claude registry**: `github` MCP present (warn if absent, not fail).
4. **Git proxy**: GitKraken or git-mcp present (warn if absent).
5. **test.sh**: all tests pass (`✓ All tests passed!`).
6. **Config path**: `mcp_server.py` referenced in example config.

---

## §6 — doctrine-executor Integration

The doctrine-executor agent persona uses the following MCP surfaces:

```
@openhands execute_task  → OpenHands MCP (stdio)
@openhands research_codebase → OpenHands MCP (stdio)
github: list_pull_requests → GitHub MCP (http)
github: search_code → GitHub MCP (http, for 300-ref discovery)
grep.app → grep.app MCP (built-in, code search)
context7 → context7 MCP (built-in, docs)
```

**300-reference search workflow** (triggered by `high_impact: true`):

```
1. grep.app search: "affaan-m/ECC AGENTS.md patterns"
2. github search_code: "persona= site:github.com"
3. context7: "FastMCP 3.3.1 tool decorator examples"
4. @openhands research_codebase: top-3 repos identified above
5. Aggregate ≥ 300 references → verified ✓
```

---

## §7 — Full Validation Matrix

| Check | Tool | Pass Condition | Fail Handling |
|-------|------|----------------|---------------|
| python3 >= 3.12 | `python3 --version` | major=3, minor≥12 | exit 1 |
| uv present | `uv --version` | any version | exit 1 |
| claude present | `claude --version` | any version | exit 1 |
| fastmcp installed | `python -c "import fastmcp"` | no error | exit 1 |
| mcp_server.py syntax | `python -m py_compile` | exit 0 | exit 1 |
| health_check | python inline | "running" in output | exit 1 |
| github MCP | `claude mcp list` | "github" present | warn (strict: exit 1) |
| git proxy | `claude mcp list` | GitKraken or git-mcp | warn |
| test.sh | `bash test.sh` | "All tests passed" | exit 1 |
| config path | grep in example | mcp_server.py ref | warn |

Run full matrix:

```bash
bash scripts/validate_mcps.sh --strict --verbose
```

---

## §8 — Troubleshooting

### "MOCK mode" in health check

Expected until OpenHands SDK is installed. Install:

```bash
git clone https://github.com/fvegiard/OpenHands.git ~/openhands-sdk
cd ~/openhands-sdk && uv pip install -e .
```

### github MCP warning

Register with a PAT (see §4). The validator warns but does not fail unless
`--strict` is passed with `GITHUB_REQUIRED=true`.

### uv not found

```bash
curl -LsSf https://astral.sh/uv/install.sh | sh
source ~/.cargo/env  # or reload shell
```

---

## §9 — Gate Summary

```
ALL GATES GREEN (MCP Enablement):
✓ OpenHands MCP: running in MOCK mode (v3.0 - June 2026)
✓ test.sh: All tests passed!
✓ config: mcp_server.py reference present
✓ docs: MCP_ENABLEMENT_PLAN.md present (this file)
⚠ github MCP: register PAT for full enablement (optional for local dev)
⚠ git proxy: install gk or uvx mcp-server-git (optional)
```

---

*Last updated: June 2026 — doctrine-executor Iter 5/6 | continu-300ref-B*
*PLAN COMPLETE. See .agents/AGENTS.md for full gate checklist.*
