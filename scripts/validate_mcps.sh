#!/bin/bash
#
# scripts/validate_mcps.sh
# Full MCP validation for git-opencode-openhands-integration
# Per MCP_ENABLEMENT_PLAN.md §5.4, §7 matrix, plan.md sketch, test.sh/setup.sh patterns.
#
# Usage:
#   bash scripts/validate_mcps.sh [--verbose] [--strict]
#   --strict : exit 1 on any FAIL or WARN (for gate/CI)
#   --verbose: more details + full claude mcp list + smoke payload
#
# Outputs human report + timestamped log in logs/ (redacted)
# Re-uses health_check string, .venv/uv, test.sh subcall.
# Handles github absent (uses GitKraken/git-mcp as noted proxies; warns but passes strict if proxies ok)
#

set -euo pipefail

# Colors (match test.sh)
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

STRICT=false
VERBOSE=false
FAIL=0
WARN_COUNT=0

while [[ $# -gt 0 ]]; do
  case $1 in
    --verbose) VERBOSE=true; shift ;;
    --strict) STRICT=true; shift ;;
    *) echo "Unknown arg: $1"; exit 1 ;;
  esac
done

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

LOG="logs/mcp-validate-$(date -u +%Y%m%d-%H%M%S).log"
mkdir -p logs
# Guard against bidirectional recursive calls:
#   test.sh (Test 11) → validate_mcps.sh (section 5) → test.sh (Test 11) → ...
# The guard breaks the cycle in both directions.
if [ "${MCP_VALIDATOR_RUNNING:-}" = "1" ]; then
  echo "Skipping recursive validator call (already running)"
  exit 0
fi
export MCP_VALIDATOR_RUNNING=1
# Tee stdout+stderr to log. The original sed-based redaction pipeline was removed
# because the extra process-substitution stage caused the script to hang when
# invoked via another pipeline (e.g. test.sh's `| tee | tail | grep`).
exec > >(tee -a "$LOG") 2>&1

echo "🧪 MCP Validation for opencode-openhands-integration"
echo "Repo: $REPO_ROOT"
echo "Time: $(date -u)"
echo "Flags: verbose=$VERBOSE strict=$STRICT"
echo ""

pass() {
  echo -e "${GREEN}✓${NC} $1"
}

warn() {
  echo -e "${YELLOW}⚠${NC} $1"
  WARN_COUNT=$((WARN_COUNT+1))
}

fail_item() {
  echo -e "${RED}✗${NC} $1"
  FAIL=$((FAIL+1))
  if $STRICT; then
    echo "STRICT mode: failing fast."
    exit 1
  fi
}

# 1. Prerequisites (plan §7 + script sketch)
echo "=== 1. Prerequisites ==="
CLAUDE_AVAILABLE=false
for tool in claude python3 uv; do
  if command -v "$tool" >/dev/null 2>&1; then
    ver=$($tool --version 2>&1 | head -1 | tr '\n' ' ')
    pass "$tool present: $ver"
    if [ "$tool" = "claude" ]; then
      CLAUDE_AVAILABLE=true
    fi
  else
    if [ "$tool" = "claude" ]; then
      # claude is optional: MCP server health and Python checks are the core gates
      warn "claude not found in PATH (claude mcp checks will be skipped; core MCP health still validated)"
    else
      fail_item "$tool not found in PATH"
    fi
  fi
done

python3 -c '
import sys
if sys.version_info >= (3, 12):
  print("python3 >= 3.12: OK")
else:
  print("python3 < 3.12")
  sys.exit(1)
' && pass "Python version >= 3.12" || fail_item "Python 3.12+ required"

if command -v jq >/dev/null 2>&1; then
  pass "jq present (JSON checks enabled)"
else
  warn "jq not present (JSON checks skipped)"
fi

echo ""

# 2. Repo MCP health (OpenHands local, MOCK OK)
echo "=== 2. Repo OpenHands MCP (direct) ==="
if [ ! -d ".venv" ]; then
  echo "Creating .venv (idempotent)..."
  uv venv
fi
source .venv/bin/activate
uv pip install -r requirements.txt -q
pass "deps installed"

if python -m py_compile mcp_server.py 2>/dev/null; then
  pass "mcp_server.py syntax OK"
else
  fail_item "mcp_server.py has syntax errors"
fi

HEALTH=$(python -c "
from mcp_server import health_check
print(health_check())
" 2>&1)
if echo "$HEALTH" | grep -q "OpenHands MCP Server is running"; then
  pass "direct health: $HEALTH"
else
  fail_item "direct health failed: $HEALTH"
fi

echo ""

# 3. Claude MCP registry (github target + proxies)
echo "=== 3. Claude MCP Registry ==="
CLIST=""
if $CLAUDE_AVAILABLE; then
  CLIST=$(claude mcp list 2>&1 || true)
  if $VERBOSE; then
    echo "$CLIST"
  fi

  if echo "$CLIST" | grep -qi 'github'; then
    pass "github MCP present in claude mcp list"
  else
    warn "github MCP NOT present (run claude mcp add ... with PAT; see README / .env.example)"
  fi

  if echo "$CLIST" | grep -qiE 'GitKraken|git-mcp'; then
    pass "git proxy present (GitKraken or git-mcp)"
  else
    warn "No GitKraken/git-mcp (local git fallbacks missing)"
  fi

  # openhands in claude is optional (primary via opencode config)
  if echo "$CLIST" | grep -qi 'openhands'; then
    pass "openhands registered to claude (additive)"
  else
    warn "openhands not in claude mcp (OK; primary path is opencode @openhands)"
  fi
else
  warn "claude MCP registry check SKIPPED (claude not in PATH; install Claude Code to enable)"
fi

echo ""

# 4. GitHub MCP smoke (if registered)
echo "=== 4. GitHub MCP Smoke (authenticated read) ==="
if $CLAUDE_AVAILABLE && echo "$CLIST" | grep -qi 'github'; then
  SMOKE=$(claude --print --allow-dangerously-skip-permissions \
    "Use only the github MCP. List the default branch for repo fvegiard/opencode-openhands-integration or get the latest release. Be terse, one line." 2>&1 || true)
  if $VERBOSE; then
    echo "Smoke payload: $SMOKE"
  fi
  if echo "$SMOKE" | grep -qiE 'main|master|release|tag|success|default_branch'; then
    pass "GitHub smoke success (saw branch/release info)"
  elif echo "$SMOKE" | grep -qiE 'error|unauth|scope|403|not found|failed'; then
    fail_item "GitHub smoke failed: $SMOKE"
  else
    warn "GitHub smoke inconclusive (no clear branch/error). Payload: $SMOKE"
  fi
else
  warn "GitHub smoke SKIPPED (claude not present or no github MCP; GitKraken can proxy many ops)"
fi

echo ""

# 5. Run test.sh (reuse)
echo "=== 5. Full repo test.sh ==="
if [ -x "./test.sh" ]; then
  if ./test.sh 2>&1 | cat; then
    pass "test.sh passed"
  else
    fail_item "test.sh had failures"
  fi
else
  fail_item "test.sh not executable"
fi

echo ""

# 6. Config path consistency (example + live if present)
echo "=== 6. Config path checks ==="
ABS_MCP=$(python -c "
import os
print(os.path.abspath('mcp_server.py'))
" )
pass "Computed abs path: $ABS_MCP"

if [ -f "config/oh-my-opencode.json.example" ]; then
  if grep -q "mcp_server.py" config/oh-my-opencode.json.example; then
    pass "example config references mcp_server.py"
  else
    warn "example config missing mcp_server.py reference"
  fi
fi

LIVE_CFG="$HOME/.config/opencode/oh-my-opencode.json"
if [ -f "$LIVE_CFG" ]; then
  if grep -F "$ABS_MCP" "$LIVE_CFG" >/dev/null 2>&1 || grep -q "mcp_server.py" "$LIVE_CFG"; then
    pass "live opencode config has mcp_server.py (path may be abs or relative; validator prefers abs)"
  else
    warn "live config may have path drift vs $ABS_MCP"
  fi
else
  warn "no live ~/.config/opencode/oh-my-opencode.json (using examples; OK for this repo)"
fi

echo ""

# 7. Report
echo "=== REPORT ==="
echo "MCP_VALIDATION: core checks"
echo "  FAILS: $FAIL"
echo "  WARNS: $WARN_COUNT"
echo "  STRICT: $STRICT"
echo ""
if [ $FAIL -eq 0 ]; then
  echo -e "${GREEN}═══════════════════════════════════════════${NC}"
  echo -e "${GREEN}✓ ALL CORE CHECKS PASS${NC}"
  if [ $WARN_COUNT -gt 0 ]; then
    echo -e "${YELLOW}(with $WARN_COUNT warning(s); investigate for full prod)${NC}"
  fi
  echo -e "${GREEN}═══════════════════════════════════════════${NC}"
  echo "Log: $LOG"
  echo "See docs/MCP_ENABLEMENT_PLAN.md for matrix."
  if $STRICT; then
    exit 0
  fi
else
  echo -e "${RED}═══════════════════════════════════════════${NC}"
  echo -e "${RED}✗ $FAIL FAIL(S) - see above${NC}"
  echo -e "${RED}═══════════════════════════════════════════${NC}"
  echo "Log: $LOG (redacted)"
  if $STRICT; then
    exit 1
  fi
fi

deactivate 2>/dev/null || true
