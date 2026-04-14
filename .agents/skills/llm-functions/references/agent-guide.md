# Agent Creation Reference

## Directory Structure

```
agents/<name>/
├── index.yaml      # Required: Agent definition
├── tools.{sh,js,py} # Optional: Agent-specific tools
├── tools.txt       # Optional: Shared tools to include
└── functions.json  # Auto-generated (don't edit)
```

## index.yaml Structure

```yaml
name: AgentName
description: Brief description
version: 0.1.0
instructions: |
  You are an AI agent that...
  
  <tools>
  {{__tools__}}
  </tools>
  
  Guidelines:
  - Use appropriate tools
  - Handle errors gracefully

variables:
  - name: user_pref
    description: User preference
    default: value

documents:
  - README.md
  - docs/

conversation_starters:
  - What can you do?
```

## Agent Tools vs Common Tools

| Aspect | Common Tools | Agent Tools |
|--------|--------------|-------------|
| Location | `tools/<name>.{sh,js,py}` | `agents/<name>/tools.{sh,js,py}` |
| Functions | Single `main()` | Multiple named functions |
| Annotation | `# @describe` | `# @cmd` |
| Subcommands | N/A | Multiple `@cmd` functions |

## Bash Agent Tools Example

```bash
#!/usr/bin/env bash
set -e

# @env LLM_OUTPUT=/dev/stdout

# @cmd First action
# @option --param! Description
action_one() {
    echo "result" >> "$LLM_OUTPUT"
}

# @cmd Second action
# @option --param! Description
action_two() {
    echo "result" >> "$LLM_OUTPUT"
}

eval "$(argc --argc-eval "$0" "$@")"
```

## Variables

### Built-in (reserved)
- `__os__`, `__os_family__`, `__arch__`, `__shell__`
- `__locale__`, `__now__`, `__cwd__`, `__tools__`

### Usage
- In `index.yaml` instructions: `{{variable_name}}`
- In tool scripts: `$LLM_AGENT_VAR_VARIABLE_NAME`

## Build Commands

```bash
argc build@agent <name>     # Build specific agent
argc build                  # Build all agents from agents.txt
argc run@agent <name> <action> '{"param":"val"}'  # Test
```
