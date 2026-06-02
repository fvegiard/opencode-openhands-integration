# Troubleshooting Guide

Common issues and solutions for OpenCode-OpenHands integration.

---

## MCP Server Not Connecting

**Problem:** `@openhands health_check` returns no response

**Solutions:**
1. Verify server is running: `ps aux | grep mcp_server.py`
2. Check config path in `~/.config/opencode/oh-my-opencode.json`
3. Ensure path is absolute, not relative
4. Test server directly: `python mcp_server.py`
5. Restart OpenCode

## OpenHands SDK Not Available

**Problem:** Health check shows "MOCK MODE"

**Solutions:**
1. Install OpenHands SDK:
   ```bash
   cd ~/openhands-sdk
   source .venv/bin/activate
   uv pip install -e .
   ```
2. Restart MCP server

## API Key Issues

**Problem:** "Invalid API key" errors

**Solutions:**
1. Verify key format: `echo $ANTHROPIC_API_KEY`
2. Should start with `sk-ant-`
3. Export in shell: `export ANTHROPIC_API_KEY="..."`
4. Or use `.env` file

## Configuration Not Loading

**Problem:** Changes don't take effect

**Solutions:**
1. Check JSON syntax: `cat ~/.config/opencode/oh-my-opencode.json | jq .`
2. Use absolute paths
3. Restart OpenCode
4. Check logs: `tail ~/.config/opencode/logs/mcp.log`

For detailed troubleshooting, see full documentation.

**Last Updated:** June 2026
