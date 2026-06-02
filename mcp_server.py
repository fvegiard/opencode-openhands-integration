"""
OpenHands MCP Server (June 2026)
Exposes OpenHands Agent SDK capabilities via Model Context Protocol.

Compatible with MCP Specification 2025-11-25
Uses FastMCP 3.3.1+ for decorator-based tool definitions
"""
from fastmcp import FastMCP
import asyncio
from typing import Optional
import os
import sys
import logging

# Configure logging to stderr (MCP best practice)
logging.basicConfig(
    level=logging.INFO,
    format='[%(asctime)s] %(levelname)s - %(message)s',
    stream=sys.stderr
)
logger = logging.getLogger(__name__)

# Initialize FastMCP server
mcp = FastMCP("openhands-agent-server")

# Note: OpenHands SDK imports will be added once the SDK is installed
# For now, we provide a mock implementation that can be replaced
try:
    from openhands.core.main import run_controller
    from openhands.core.config import AppConfig, AgentConfig
    from openhands.core.logger import openhands_logger
    OPENHANDS_AVAILABLE = True
except ImportError:
    logger.warning("OpenHands SDK not available. Using mock implementation.")
    OPENHANDS_AVAILABLE = False


async def mock_execute_task(task_description: str, model: str, max_iterations: int) -> str:
    """Mock implementation when OpenHands SDK is not available"""
    logger.info(f"[MOCK] Would execute: {task_description}")
    return f"""✓ Task completed (MOCK MODE - Install OpenHands SDK for real execution)
Task: {task_description}
Model: {model}
Max iterations: {max_iterations}

To enable real execution:
1. Clone OpenHands: git clone https://github.com/fvegiard/OpenHands.git
2. Install: cd OpenHands && uv pip install -e .
3. Set API keys: export ANTHROPIC_API_KEY=your_key
4. Restart this MCP server
"""


@mcp.tool()
async def execute_task(
    task_description: str,
    model: str = "anthropic/claude-sonnet-4-20250514",
    max_iterations: int = 30,
    workspace_path: str = "."
) -> str:
    """
    Execute a development task using OpenHands agent.
    
    Args:
        task_description: Natural language description of the task
        model: LLM model to use (default: Claude Sonnet 4)
        max_iterations: Max agent iterations (default: 30)
        workspace_path: Working directory for the task (default: current dir)
    
    Returns:
        Execution result summary
    """
    logger.info(f"[MCP] Executing task: {task_description[:100]}...")
    
    if not OPENHANDS_AVAILABLE:
        return await mock_execute_task(task_description, model, max_iterations)
    
    try:
        # Configure OpenHands
        config = AppConfig(
            llm=AgentConfig(model=model),
            workspace_base=os.path.abspath(workspace_path),
            max_iterations=max_iterations
        )
        
        result = await run_controller(
            config=config,
            initial_user_action=task_description,
            exit_on_message=True
        )
        
        return f"""✓ Task completed
Iterations: {result.metrics.get('iterations', 0)}
Status: {result.state}
Model: {model}
"""
    
    except Exception as e:
        logger.error(f"[MCP] Task execution failed: {e}", exc_info=True)
        return f"✗ Task failed: {str(e)}"


@mcp.tool()
async def analyze_code(
    file_path: str,
    analysis_type: str = "full"
) -> str:
    """
    Analyze code file(s) using OpenHands.
    
    Args:
        file_path: Path to file or directory
        analysis_type: "full", "security", "performance", or "structure"
    
    Returns:
        Analysis report
    """
    logger.info(f"[MCP] Analyzing {file_path} ({analysis_type})")
    
    task = f"""Analyze the code at {file_path}. 
    
Analysis focus: {analysis_type}

Provide a detailed report covering:
- Code structure and organization
- Potential issues or bugs
- Security considerations
- Performance optimization opportunities
- Best practices adherence
"""
    
    return await execute_task(
        task_description=task,
        max_iterations=10
    )


@mcp.tool()
async def debug_issue(
    issue_description: str,
    stack_trace: Optional[str] = None,
    context_files: Optional[list[str]] = None
) -> str:
    """
    Debug an issue using OpenHands agent.
    
    Args:
        issue_description: Description of the bug/issue
        stack_trace: Optional stack trace
        context_files: Optional list of relevant file paths
    
    Returns:
        Debug analysis and suggested fixes
    """
    logger.info(f"[MCP] Debugging issue: {issue_description[:100]}...")
    
    task = f"Debug this issue: {issue_description}\n"
    if stack_trace:
        task += f"\nStack trace:\n{stack_trace}\n"
    if context_files:
        task += f"\nRelevant files: {', '.join(context_files)}\n"
    
    task += "\nProvide:\n1. Root cause analysis\n2. Fix suggestions with code\n3. Prevention strategies"
    
    return await execute_task(
        task_description=task,
        max_iterations=20
    )


@mcp.tool()
async def research_codebase(
    query: str,
    repo_path: str = "."
) -> str:
    """
    Research codebase to answer architectural or flow questions.
    
    Args:
        query: Question about the codebase
        repo_path: Path to repository (default: current dir)
    
    Returns:
        Research findings
    """
    logger.info(f"[MCP] Researching: {query[:100]}...")
    
    task = f"""Research the codebase at {repo_path} to answer this question:

{query}

Use available tools (grep, LSP, file analysis) to:
1. Locate relevant code sections
2. Trace execution flows
3. Document key components
4. Provide a comprehensive answer with file paths and line numbers
"""
    
    return await execute_task(
        task_description=task,
        max_iterations=15,
        workspace_path=repo_path
    )


@mcp.tool()
async def refactor_code(
    description: str,
    target_files: Optional[list[str]] = None,
    preserve_behavior: bool = True
) -> str:
    """
    Refactor code using OpenHands agent.
    
    Args:
        description: Description of the refactoring to perform
        target_files: Optional list of files to refactor (None = auto-detect)
        preserve_behavior: Ensure behavior is preserved (default: True)
    
    Returns:
        Refactoring result summary
    """
    logger.info(f"[MCP] Refactoring: {description[:100]}...")
    
    task = f"Refactor the code: {description}\n"
    
    if target_files:
        task += f"\nTarget files: {', '.join(target_files)}\n"
    
    if preserve_behavior:
        task += "\nIMPORTANT: Preserve existing behavior. Add tests to verify if needed.\n"
    
    return await execute_task(
        task_description=task,
        max_iterations=30
    )


@mcp.tool()
def health_check() -> str:
    """Check if OpenHands MCP server is running."""
    status = "with OpenHands SDK" if OPENHANDS_AVAILABLE else "in MOCK mode"
    return f"✓ OpenHands MCP Server is running {status} (v3.0 - June 2026)"


@mcp.tool()
def get_capabilities() -> dict:
    """List all available MCP tools and their capabilities."""
    return {
        "server": "OpenHands MCP Server",
        "version": "3.0.0",
        "mcp_spec": "2025-11-25",
        "fastmcp_version": "3.3.1+",
        "openhands_available": OPENHANDS_AVAILABLE,
        "tools": [
            {
                "name": "execute_task",
                "description": "Execute development tasks autonomously",
                "use_cases": ["Feature implementation", "Bug fixes", "Code generation"]
            },
            {
                "name": "analyze_code",
                "description": "Analyze code for issues and improvements",
                "use_cases": ["Code review", "Security audit", "Performance analysis"]
            },
            {
                "name": "debug_issue",
                "description": "Debug and diagnose issues",
                "use_cases": ["Bug investigation", "Stack trace analysis", "Error diagnosis"]
            },
            {
                "name": "research_codebase",
                "description": "Research and understand codebases",
                "use_cases": ["Architecture discovery", "Flow tracing", "Documentation"]
            },
            {
                "name": "refactor_code",
                "description": "Refactor code while preserving behavior",
                "use_cases": ["Code cleanup", "Architecture improvements", "Tech debt reduction"]
            },
            {
                "name": "health_check",
                "description": "Check server health",
                "use_cases": ["Monitoring", "Debugging connections"]
            },
            {
                "name": "get_capabilities",
                "description": "List all available capabilities",
                "use_cases": ["Discovery", "Documentation"]
            }
        ]
    }


if __name__ == "__main__":
    # Determine transport mode from command line or environment
    transport = os.getenv("MCP_TRANSPORT", "stdio")
    port = int(os.getenv("MCP_PORT", "8765"))
    
    if len(sys.argv) > 1 and sys.argv[1] in ["http", "stdio"]:
        transport = sys.argv[1]
    
    logger.info(f"🚀 Starting OpenHands MCP Server")
    logger.info(f"   Transport: {transport}")
    logger.info(f"   MCP Spec: 2025-11-25")
    logger.info(f"   FastMCP: 3.3.1+")
    logger.info(f"   OpenHands SDK: {'Available' if OPENHANDS_AVAILABLE else 'Not Available (Mock Mode)'}")
    
    if transport == "http":
        logger.info(f"   HTTP Port: {port}")
        logger.info(f"   URL: http://localhost:{port}")
        mcp.run(transport="http", port=port)
    else:
        logger.info(f"   STDIO: Ready for client connection")
        mcp.run()
