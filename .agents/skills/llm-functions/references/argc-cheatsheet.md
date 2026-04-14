# Argc Command Cheatsheet

## Essential Commands

```bash
# Build
argc build                    # Build tools and agents
argc build@tool tool.sh       # Build specific tool
argc build@agent agent-name   # Build specific agent

# Run
argc run@tool tool_name '{"param":"val"}'
argc run@agent agent_name action '{"param":"val"}'

# Check
argc check                    # Check everything
argc check@tool               # Check tools
argc check@agent              # Check agents
argc mcp check                # Check MCP

# List
argc list@tool                # List available tools
argc list@agent               # List available agents

# Clean
argc clean                    # Clean all
argc clean@tool               # Clean tools
argc clean@agent              # Clean agents

# Create
argc create@tool name.sh param! array+

# Link
argc link-web-search web_search_perplexity.sh
argc link-code-interpreter execute_py_code.py

# MCP
argc mcp merge-functions -S   # Merge MCP functions
```

## Common @option Patterns

| Pattern | Meaning | JSON Schema |
|---------|---------|-------------|
| `--name!` | Required string | `{"type":"string"}` |
| `--name` | Optional string | `{"type":"string"}` |
| `--name! <INT>` | Required integer | `{"type":"integer"}` |
| `--name! <NUM>` | Required number | `{"type":"number"}` |
| `--name! [a\|b]` | Required enum | `{"type":"string","enum":["a","b"]}` |
| `--name+` | Required array | `{"type":"array"}` |
| `--name*` | Optional array | `{"type":"array"}` |
| `--name! <FILE>` | File path | `{"type":"string","format":"path"}` |
| `--name@` | Positional arg | Parameter |

## Bash Special Cases

```bash
# Multiple positional args
# @arg files+                 # Required array of files

# Command with subcommands (agents only)
# @cmd Subcommand name
# @option --param! Description
subcommand() { ... }

# Environment variables
# @env VAR!                  # Required env var
# @env VAR=default           # Optional with default
# @env LLM_OUTPUT=/dev/stdout Tool output path
```

## Environment Variables

- `LLM_OUTPUT` - Where to write tool output
- `LLM_ROOT_DIR` - Repository root
- `LLM_TOOL_NAME` - Current tool name
- `LLM_TOOL_CACHE_DIR` - Tool-specific cache

## Array Handling

```bash
# Required array (--items+ v1 v2 v3)
# @option --items+ <VALUE>
for item in "${argc_items[@]}"; do
    echo "$item"
done

# Optional array (--tags* t1 t2)
# @option --tags*
for tag in "${argc_tags[@]}"; do
    echo "$tag"
done
```
