#!/bin/bash
#
# capture-baseline.sh
#
# Reusable baseline capture logic for MCP enablement fan-out (devops worker #06).
# Implements plan §5.1 baseline, devops parts of 5.4 (logs, hygiene), worktree/git notes.
#
# - Captures: versions (python/uv/claude/opencode), claude mcp list, test.sh run (as subcheck),
#   relevant ~/.config/* (opencode, claude), git status/worktree, env hygiene, etc.
# - Saves timestamped redacted log to logs/baseline-*.log (never leaks tokens/PATs/Bearer).
# - POSIX bash, strict mode, colors matching test.sh/setup.sh.
# - --verbose: extra detail (doctor summaries, pip list, which -a, full configs).
# - --no-test: skip running test.sh (for validator to control subcheck order).
# - Reusable: can be SOURCED by sibling validator (e.g. scripts/validate_mcps.sh) to share
#   functions or trigger baseline automatically on --verbose.
#   Example integration in validator:
#     if $VERBOSE; then
#       bash "$(dirname "$0")/capture-baseline.sh" --no-test --verbose || true
#     fi
#   Or: source "$(dirname "$0")/capture-baseline.sh"  # defines capture_* funcs + REDACT etc.
#   Validator can also run test.sh itself as explicit subcheck (plan 5.4).
# - Always safe, read-only (no writes except the log itself), idempotent.
# - Supports gate: run this first, then validate steps reuse outputs if wanted.
#
# Usage (standalone):
#   bash scripts/capture-baseline.sh [--verbose] [--no-test]
#
# After merge of mcp/06-devops-baseline: validator (from 01) will be able to call/source this.
#
# Per CLAUDE.md §04/05/12/16: gate, hygiene, logs in .gitignore, completion via todos, narrow diff.
#
# DO NOT EDIT without also updating the calling validator and re-capturing baseline.

set -euo pipefail

# Colors (reuse from test.sh / setup.sh)
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Resolve repo root relative to this script (works even if sourced from sibling tree)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$REPO_ROOT"

TIMESTAMP=$(date -u +%Y%m%d-%H%M%S)
LOG_DIR="logs"
LOG_FILE="${LOG_DIR}/baseline-${TIMESTAMP}.log"

VERBOSE=false
RUN_TEST=true

REDACT_SED='s/(Bearer[ =:]+|sk-ant-[A-Za-z0-9_-]+|ANTHROPIC_API_KEY[ =:]+|OPENAI_API_KEY[ =:]+|GITHUB_PERSONAL_ACCESS_TOKEN[ =:]+|GITHUB_PAT[ =:]+)[^ ]+/\1[REDACTED]/g; s/("Authorization"[[:space:]]*:[[:space:]]*"Bearer )[^"]+/\1[REDACTED]"/g; s/(Authorization: Bearer )[^ ]+/\1[REDACTED]/g; s/(api[_-]?key|token|secret)[ =:]+[^ ]+/\1[REDACTED]/gi'

print_header() {
  echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
  echo -e "${GREEN}   MCP/DevOps Baseline Capture (worker #06) - $(date -u +%Y-%m-%dT%H:%M:%SZ)${NC}"
  echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
  echo "Repo: $REPO_ROOT"
  echo "Branch: $(git branch --show-current 2>/dev/null || echo 'detached')"
  echo "Log will be: $LOG_FILE (redacted)"
  echo ""
}

usage() {
  echo "capture-baseline.sh - reusable devops baseline + logs hygiene"
  echo "Usage: $0 [--verbose|-v] [--no-test] [--help|-h]"
  echo "  --verbose   Include extended captures (claude doctor, pip list, which -a, full configs)"
  echo "  --no-test   Skip sub-invocation of test.sh (let caller/validator drive it)"
  echo ""
  echo "Integration notes for validator (see top of file):"
  echo "  - Call with --no-test to avoid duplicate test runs."
  echo "  - Pass --verbose to capture more when validator --verbose."
  echo "  - Source for functions: source scripts/capture-baseline.sh ; capture_versions"
  echo "  - Or always capture baseline first in validator --verbose path."
  exit 0
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --verbose|-v) VERBOSE=true; shift ;;
    --no-test) RUN_TEST=false; shift ;;
    --help|-h) usage ;;
    *) echo -e "${RED}Unknown arg: $1${NC}"; usage ;;
  esac
done

# Ensure dirs
mkdir -p "$LOG_DIR"

# Redact helper (pipe stdin)
redact() {
  sed -E "$REDACT_SED"
}

# Append a section to log (redacted) + echo label to stdout
append_section() {
  local title="$1"; shift
  {
    echo ""
    echo "=== ${title} @ $(date -u +%H:%M:%S) ==="
    if [[ "$#" -gt 0 ]]; then
      ( "$@" 2>&1 || echo "[exit code: $?]" ) | redact
    fi
  } >> "$LOG_FILE"
  echo -e "${YELLOW}[capture]${NC} ${title}"
}

# --- REUSABLE CAPTURE FUNCTIONS (for sourcing/integration) ---

capture_versions() {
  append_section "VERSIONS" bash -c '
    echo "python3: $(python3 --version 2>&1)"
    echo "python: $(python --version 2>&1 || echo missing)"
    echo "uv: $(uv --version 2>&1 || echo missing)"
    echo "claude: $(claude --version 2>&1 || echo missing)"
    echo "opencode: $(opencode --version 2>&1 || echo missing)"
    echo "git: $(git --version 2>&1)"
    echo "bash: $BASH_VERSION"
    echo "shell: $SHELL"
    command -v python3 uv claude opencode git bash | cat
  '
  if $VERBOSE; then
    append_section "VERSIONS_VERBOSE" bash -c '
      echo "which -a python3:"; which -a python3 2>/dev/null || true
      echo "which -a uv:"; which -a uv 2>/dev/null || true
      echo "which -a claude:"; which -a claude 2>/dev/null || true
      echo "which -a opencode:"; which -a opencode 2>/dev/null || true
      echo "uv python list (if any):"; uv python list 2>/dev/null | head -5 || true
      python3 -c "
import sys
print('python_version_info:', sys.version_info)
print('free_threaded_gil_disabled:', not getattr(sys, \"_is_gil_enabled\", lambda: True)())
print('executable:', sys.executable)
" 2>/dev/null || true
    '
  fi
}

capture_claude_mcp() {
  append_section "CLAUDE_MCP_LIST" timeout 20s claude mcp list 2>&1 || echo "[TIMEOUT or error after 20s on claude mcp list (common: health checks on 16+ MCPs; run manually for full)]" 
  if $VERBOSE; then
    append_section "CLAUDE_MCP_VERBOSE" bash -c '
      echo "claude mcp --help head:"; claude mcp --help 2>&1 | head -10 || true
      echo "claude doctor (head):"; timeout 8s claude doctor 2>&1 | head -30 || echo "[doctor slow/partial after timeout]" 
      echo "claude --version --verbose-ish:"; claude --version 2>&1 || true
    '
  fi
}

capture_test_sh() {
  if ! $RUN_TEST; then
    echo -e "${YELLOW}[capture]${NC} test.sh skipped (--no-test)"
    append_section "TEST_SH_SKIPPED" echo "test.sh invocation skipped per --no-test (validator may run it separately)"
    return 0
  fi
  if [ -x "./test.sh" ]; then
    append_section "TEST_SH_RUN" bash "./test.sh" 2>&1 || true
  else
    append_section "TEST_SH_RUN" echo "test.sh not executable or missing at ./test.sh"
  fi
}

capture_configs() {
  append_section "CONFIG_OPENCODE_LS" ls -la ~/.config/opencode/ 2>/dev/null || echo "no ~/.config/opencode dir"
  append_section "CONFIG_OPENCODE_CATS" bash -c '
    for f in $(ls ~/.config/opencode/*.json ~/.config/opencode/*.jsonc ~/.config/opencode/*.example 2>/dev/null || true); do
      echo "=== CONTENT: $f ==="
      cat "$f" 2>/dev/null || true
      echo ""
    done
  '
  append_section "CONFIG_CLAUDE_LS" ls -la ~/.claude/settings*.json ~/.config/claude/ 2>/dev/null || echo "no claude config dirs"
  append_section "CONFIG_CLAUDE_CATS" bash -c '
    for f in $(ls ~/.claude/settings*.json 2>/dev/null || true); do
      echo "=== CONTENT: $f (truncated) ==="
      head -c 2048 "$f" 2>/dev/null || true
      echo "..."
    done
    echo "=== claude plugin mcp examples ==="
    find ~/.claude/plugins -name "*.mcp.json" 2>/dev/null | head -3 | cat || true
  '
}

capture_git_hygiene() {
  append_section "GIT_STATUS" git status --porcelain -b --ahead-behind --untracked-files=all 2>&1 || true
  append_section "GIT_WORKTREE" git worktree list 2>&1 || true
  append_section "GIT_BRANCH" git branch -vv 2>&1 || true
  append_section "GIT_LOG" git log --oneline -3 2>&1 || true
  append_section "GIT_REMOTE" git remote -v 2>&1 || true
  if $VERBOSE; then
    append_section "GIT_VERBOSE" bash -c '
      echo "git config --list (local, redacted):"
      git config --list --local 2>/dev/null | grep -v -iE "token|key|secret|pass" | head -30 || true
      echo "git rev-parse HEAD:"
      git rev-parse HEAD 2>/dev/null || true
      echo "git describe --always:"
      git describe --always 2>/dev/null || true
    '
  fi
}

capture_env_hygiene() {
  append_section "ENV_HYGIENE" bash -c '
    echo "PATH (first 5):"; echo "$PATH" | tr ":" "\n" | head -5
    echo "SHELL: $SHELL ; PWD: $PWD"
    echo "USER: $USER ; HOME: $HOME"
    echo "python in PATH priority:"
    command -v python3 ; python3 -c "import sys;print(sys.executable)" 2>/dev/null || true
    echo "claude in PATH priority:"
    command -v claude ; which -a claude 2>/dev/null | head -3 || true
  '
  append_section "SENSITIVE_ENV_REDACTED" bash -c '
    echo "Known secret-ish vars present (redacted values):"
    for var in ANTHROPIC_API_KEY OPENAI_API_KEY GITHUB_PERSONAL_ACCESS_TOKEN GITHUB_PAT MCP_TRANSPORT; do
      if [ -n "${!var:-}" ]; then
        echo "$var=***present*** (value redacted in log)"
      fi
    done
    env | grep -iE "(_KEY|_TOKEN|_PAT|SECRET)" | sed -E "s/=.*/=[REDACTED]/" || true
  '
}

capture_extra_hygiene() {
  append_section "SYSTEM" bash -c '
    echo "date: $(date)"
    echo "uname: $(uname -a)"
    echo "id: $(id)"
    echo "df -h . :"; df -h . 2>/dev/null | cat
    echo "free -h (head):"; free -h 2>/dev/null | head -2 || true
  '
  if $VERBOSE; then
    append_section "DEPS_IN_VENV" bash -c '
      if [ -d ".venv" ]; then
        source .venv/bin/activate
        echo "uv pip list (head):"; uv pip list 2>/dev/null | head -20 || true
        echo "python -m pip list (head if present):"; python -m pip list 2>/dev/null | head -10 || true
        deactivate 2>/dev/null || true
      else
        echo "no .venv"
      fi
    '
    append_section "OTHER_MCP_PRESENCE" bash -c '
      echo "gk (GitKraken cli) version:"; gk --version 2>/dev/null || echo "no gk"
      echo "docker:"; docker --version 2>/dev/null || echo "no docker"
      echo "jq:"; jq --version 2>/dev/null || echo "no jq (used by test.sh optional)"
    '
  fi
}

# Main capture orchestration
main() {
  print_header

  # Header to log (redacted)
  {
    echo "MCP ENABLEMENT FAN-OUT WORKER #06 - BASELINE CAPTURE"
    echo "plan: 01-baseline, 5.1, devops parts of 5.4, worktree/git hygiene, logs/"
    echo "timestamp_utc: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
    echo "script: $0"
    echo "worktree: $(git branch --show-current 2>/dev/null)"
    echo "commit: $(git rev-parse --short HEAD 2>/dev/null)"
    echo "REDACTION: applied via $REDACT_SED"
  } | redact > "$LOG_FILE"

  echo -e "${YELLOW}Capturing baseline (redacted output to $LOG_FILE)...${NC}"

  capture_versions
  capture_claude_mcp
  capture_test_sh
  capture_configs
  capture_git_hygiene
  capture_env_hygiene
  capture_extra_hygiene

  {
    echo ""
    echo "=== BASELINE CAPTURE COMPLETE @ $(date -u +%Y-%m-%dT%H:%M:%SZ) ==="
    echo "Log file: $LOG_FILE"
    echo "Size: $(wc -c < "$LOG_FILE" 2>/dev/null || echo 0) bytes"
    echo "Next: run validator (when present), re-capture after changes, gate with test.sh + validate --strict"
  } >> "$LOG_FILE"

  echo ""
  echo -e "${GREEN}✓ Baseline captured: $LOG_FILE${NC}"
  echo -e "  (contains redacted versions, mcp list, test.sh output, configs, git status, hygiene)"
  if $VERBOSE; then
    echo ""
    echo -e "${YELLOW}=== LOG EXCERPT (tail -30) ===${NC}"
    tail -30 "$LOG_FILE" | cat
  fi
  echo ""
  echo "To verify: cat $LOG_FILE | head -100"
  echo "For validator integration see comments at top of this script."
}

# If sourced (for validator reuse of functions), export helpers and do not auto-run full.
# If executed directly, run main.
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
  # Always success for capture (failures inside are logged as notes)
  exit 0
else
  # Sourced mode: make functions available + print note
  echo "capture-baseline.sh sourced into current shell (reusable funcs: capture_versions, capture_claude_mcp, capture_test_sh, capture_git_hygiene, capture_configs, ...)"
  echo "REPO_ROOT=$REPO_ROOT ; LOG_FILE will be set on next capture call if using main logic."
  # Do not call main automatically when sourced. Do not exit (caller continues).
fi
