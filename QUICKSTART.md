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
