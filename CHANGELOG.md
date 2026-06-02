# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2026-06-02

### Added
- Initial release of OpenCode-OpenHands MCP integration
- FastMCP 3.3.1+ based MCP server implementation
- Support for MCP Specification 2025-11-25
- Five core MCP tools:
  - `execute_task`: Autonomous task execution
  - `analyze_code`: Code analysis and review
  - `debug_issue`: Bug investigation and diagnosis
  - `research_codebase`: Codebase research and documentation
  - `refactor_code`: Behavior-preserving refactoring
- Automated setup script (`setup.sh`)
- Comprehensive documentation:
  - README with installation and usage
  - ARCHITECTURE with system design
  - EXAMPLES with real-world use cases
  - TROUBLESHOOTING with common issues
  - QUICKSTART for 5-minute setup
- Configuration templates for OpenCode and Oh My OpenCode
- STDIO and HTTP transport support
- Mock mode for testing without OpenHands SDK
- Health check and capability discovery tools

### Documentation
- Complete installation guide
- Architecture documentation with diagrams
- 10+ usage examples
- Troubleshooting guide
- Contributing guidelines

### Developer Experience
- Python 3.12+ support
- Type hints throughout
- Proper async/await handling
- Comprehensive logging
- Environment variable configuration

---

## Future Releases

### [1.1.0] - Planned
- MCP enablement: added scripts/validate_mcps.sh, GitHub MCP support in docs, full validation matrix, aligned all docs. (see MCP_ENABLEMENT_PLAN.md).
- Async task support (MCP 2025-11-25 async tasks)
- Progress tracking for long-running tasks
- Enhanced caching for token reduction
- WebSocket transport support

### [1.2.0] - Planned
- Team collaboration features
- Shared agent configurations
- Telemetry dashboard
- Advanced monitoring

### [2.0.0] - Planned
- Multi-workspace support
- Custom model endpoints
- Plugin system for MCP tools
- Production deployment guides

---

[1.0.0]: https://github.com/fvegiard/opencode-openhands-integration/releases/tag/v1.0.0
