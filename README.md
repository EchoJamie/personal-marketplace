# Personal Marketplace

A personal Claude Code marketplace containing custom development tools.

## Plugins

### java-dev-tools

Java/Maven development tools skills for Claude Code - optimized wrappers for shell scripts.

**Skills included:**
1. **java-code-search** - Smart code search (classes, methods, tests)
2. **maven-dependency-analyzer** - Maven module dependency analysis  
3. **maven-test-runner** - Test execution with formatted output
4. **java-project-stats** - Project statistics and metrics

**Requirements:**
These skills require the following scripts in your project's `scripts/` directory:
- `search.sh` - Smart code search tool
- `analyze-deps.sh` - Maven dependency analyzer
- `test.sh` - Test runner with formatted output
- `stats.sh` - Project statistics tool

## Installation

In Claude Code:
```bash
/plugin marketplace add EchoJamie/personal-marketplace
/plugin install java-dev-tools@personal-marketplace
```

## Author

EchoJamie <myz0104@163.com>
