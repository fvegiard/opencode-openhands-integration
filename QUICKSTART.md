# Quick Start Guide

Get up and running with OpenCode-OpenHands integration in 5 minutes.

---

## Prerequisites

- **Python 3.12+**
- **Git**
- **Homebrew** (macOS/Linux) or **npm**
- **API Key:** Anthropic Claude (required)

---

## Installation (Automated)

```bash
# 1. Clone repository
git clone https://github.com/fvegiard/opencode-openhands-integration.git
cd opencode-openhands-integration

# 2. Run setup script
bash setup.sh

# 3. Set API key
export ANTHROPIC_API_KEY="sk-ant-your-key-here"

# 4. Start MCP server
source .venv/bin/activate
python mcp_server.py

# Keep this terminal open!
```

---

## First Test

Open a new terminal and run OpenCode:

```bash
opencode
```

In OpenCode, test the connection:

```
@openhands health_check
```

**Expected:** `✓ OpenHands MCP Server is running`

---

## MCP Fast Validation Checks

Run these *minimum fast checks* (copy-paste) after "First Test" (use venv for python step):

```bash
# 1. Claude MCP registry (target: github; also openhands if registered to claude, GitKraken/git proxies)
claude mcp list | grep -E 'github|openhands|GitKraken'
```

```bash
# 2. Direct repo MCP health (activate venv first)
source .venv/bin/activate
python -c 'from mcp_server import health_check; print(health_check())'
```

```bash
# 3. Full strict validator (will be created by sibling worker in this fan-out)
bash scripts/validate_mcps.sh --strict
```

**Notes for copy-paste consistency:**
- Use full `python -c 'from mcp_server import health_check; print(health_check())'` (grep for "running" internally in validator).
- `validate_mcps.sh --strict` exits 0 only on green (covers prereqs, .venv, deps, py compile, health, claude mcp presence, GitHub smoke if PAT, config paths).
- See TROUBLESHOOTING.md "MCP Validation Failures" for exact remediation matching the validator output.

---

## First Task

```
@openhands execute_task: Create a Python script that prints "Hello from OpenHands!"
```

---

## What's Next?

- **Learn more:** See [EXAMPLES.md](docs/EXAMPLES.md)
- **Troubleshooting:** See [TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md)
- **Architecture:** See [ARCHITECTURE.md](docs/ARCHITECTURE.md)
- **Full guide:** See [README.md](README.md)

---

## Need Help?

- **Documentation:** https://github.com/fvegiard/opencode-openhands-integration
- **OpenCode Docs:** https://opencode.ai/docs
- **OpenHands Docs:** https://docs.openhands.dev

---

**Happy coding! 🚀**
