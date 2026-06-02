#!/bin/bash
#
# OpenCode-OpenHands Integration Setup Script
# This script automates the installation of OpenCode, Oh My OpenCode, and OpenHands MCP Server
#
# Usage: bash setup.sh [options]
# Options:
#   --skip-opencode     Skip OpenCode installation
#   --skip-openhands    Skip OpenHands SDK installation
#   --dev               Install development dependencies
#

set -e  # Exit on error

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Configuration
SKIP_OPENCODE=false
SKIP_OPENHANDS=false
INSTALL_DEV=false
OPENHANDS_REPO="https://github.com/fvegiard/OpenHands.git"
OPENHANDS_DIR="$HOME/openhands-sdk"

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --skip-opencode)
      SKIP_OPENCODE=true
      shift
      ;;
    --skip-openhands)
      SKIP_OPENHANDS=true
      shift
      ;;
    --dev)
      INSTALL_DEV=true
      shift
      ;;
    *)
      echo -e "${RED}Unknown option: $1${NC}"
      exit 1
      ;;
  esac
done

echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}   OpenCode-OpenHands Integration Setup (June 2026)${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
echo ""

# Check prerequisites
echo -e "${YELLOW}[1/6] Checking prerequisites...${NC}"
command -v python3 >/dev/null 2>&1 || { echo -e "${RED}Python 3.12+ is required but not installed.${NC}"; exit 1; }
PYTHON_VERSION=$(python3 --version | cut -d' ' -f2 | cut -d'.' -f1,2)
echo "   ✓ Python $PYTHON_VERSION found"

command -v git >/dev/null 2>&1 || { echo -e "${RED}Git is required but not installed.${NC}"; exit 1; }
echo "   ✓ Git found"

# Install uv (Python package manager)
if ! command -v uv >/dev/null 2>&1; then
    echo -e "${YELLOW}[2/6] Installing uv (Python package manager)...${NC}"
    curl -LsSf https://astral.sh/uv/install.sh | sh
    export PATH="$HOME/.local/bin:$PATH"
    echo "   ✓ uv installed"
else
    echo -e "${YELLOW}[2/6] uv already installed${NC}"
fi

# Install OpenCode
if [ "$SKIP_OPENCODE" = false ]; then
    echo -e "${YELLOW}[3/6] Installing OpenCode...${NC}"
    
    # Try Homebrew first (macOS/Linux)
    if command -v brew >/dev/null 2>&1; then
        echo "   Using Homebrew..."
        brew install anomalyco/tap/opencode || true
    else
        # Fall back to curl install
        echo "   Using curl installer..."
        curl -fsSL https://opencode.ai/install | bash
    fi
    
    # Verify installation
    if command -v opencode >/dev/null 2>&1; then
        OPENCODE_VERSION=$(opencode --version 2>&1 || echo "unknown")
        echo "   ✓ OpenCode installed: $OPENCODE_VERSION"
    else
        echo -e "${RED}   ✗ OpenCode installation failed${NC}"
        echo "   Please install manually: https://opencode.ai/docs"
    fi
else
    echo -e "${YELLOW}[3/6] Skipping OpenCode installation${NC}"
fi

# Install OpenHands SDK
if [ "$SKIP_OPENHANDS" = false ]; then
    echo -e "${YELLOW}[4/6] Installing OpenHands SDK...${NC}"
    
    if [ ! -d "$OPENHANDS_DIR" ]; then
        echo "   Cloning OpenHands repository..."
        git clone "$OPENHANDS_REPO" "$OPENHANDS_DIR"
    else
        echo "   OpenHands directory exists, pulling latest..."
        cd "$OPENHANDS_DIR" && git pull && cd -
    fi
    
    echo "   Creating virtual environment..."
    cd "$OPENHANDS_DIR"
    uv venv
    source .venv/bin/activate
    
    echo "   Installing OpenHands SDK..."
    uv pip install -e .
    
    echo "   ✓ OpenHands SDK installed at $OPENHANDS_DIR"
    deactivate
else
    echo -e "${YELLOW}[4/6] Skipping OpenHands SDK installation${NC}"
fi

# Install MCP Server dependencies
echo -e "${YELLOW}[5/6] Installing MCP Server dependencies...${NC}"
cd "$(dirname "$0")"

# Create virtual environment for MCP server
if [ ! -d ".venv" ]; then
    uv venv
fi

source .venv/bin/activate
uv pip install -r requirements.txt

if [ "$INSTALL_DEV" = true ]; then
    echo "   Installing development dependencies..."
    uv pip install pytest pytest-asyncio black ruff mypy
fi

echo "   ✓ MCP Server dependencies installed"

# Create configuration directory
echo -e "${YELLOW}[6/6] Setting up configuration...${NC}"
mkdir -p ~/.config/opencode

# Copy example configuration if it doesn't exist
if [ ! -f ~/.config/opencode/oh-my-opencode.json ]; then
    echo "   Creating Oh My OpenCode configuration..."
    cat > ~/.config/opencode/oh-my-opencode.json <<EOF
{
  "mcps": {
    "openhands": {
      "command": "python",
      "args": ["$(pwd)/mcp_server.py"],
      "transport": "stdio"
    }
  },
  "agents": {
    "sisyphus": {
      "model": "anthropic/claude-opus-4.5-high",
      "system_prompt_additions": [
        "When facing multi-file refactoring, complex debugging, or deep codebase research tasks,",
        "use the @openhands MCP to delegate to OpenHands agent.",
        "Example: '@openhands execute_task: Refactor authentication system to use JWT'",
        "OpenHands excels at SWE-Bench-style tasks."
      ]
    }
  },
  "experimental": {
    "ultrawork_default": true
  }
}
EOF
    echo "   ✓ Configuration created at ~/.config/opencode/oh-my-opencode.json"
else
    echo "   Configuration already exists, skipping..."
fi

# Final instructions
echo ""
echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}   Installation Complete!${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
echo ""
echo "Next steps:"
echo ""
echo "1. Set your API keys:"
echo "   export ANTHROPIC_API_KEY='your-key-here'"
echo "   export OPENAI_API_KEY='your-key-here'"
echo ""
echo "2. Start the MCP server:"
echo "   cd $(pwd)"
echo "   source .venv/bin/activate"
echo "   python mcp_server.py"
echo ""
echo "3. In OpenCode, test the connection:"
echo "   @openhands health_check"
echo ""
echo "4. Try a simple task:"
echo "   @openhands execute_task: Create a Python hello world script"
echo ""
echo -e "${YELLOW}For detailed usage instructions, see: README.md${NC}"
echo ""

deactivate 2>/dev/null || true
