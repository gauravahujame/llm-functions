---
name: llm-functions
description: Create tools and agents for the llm-functions framework. Use this skill whenever the user wants to create new tools, agents, or work with the llm-functions repository structure. ALWAYS trigger on phrases like "create a tool", "new agent", "llm-functions", "aichat tool", "argc tool", "modify build system", "debug tools", "work with MCP", or when working in a directory containing tools.txt, agents.txt, Argcfile.sh, or functions.json with llm-functions patterns. Even if the user doesn't explicitly mention "llm-functions", trigger this skill when they're working with tool/agent creation, JSON schema generation from comments, or argc-based build systems.
compatibility: Requires argc CLI tool, supports Bash/JavaScript/Python
---

# LLM Functions Skill

A framework for building LLM tools and agents using Bash, JavaScript, or Python with automatic JSON schema generation from comments.

## Repository Structure

```
llm-functions/
    tools/              # Shared tools (one function per file)
    agents/             # Agents (prompt + tools + documents)
    mcp/                # MCP server and bridge
    scripts/            # Build and run scripts
    utils/              # Utility scripts
    bin/                # Compiled binaries (symlinks)
    tools.txt           # List of tools to include
    agents.txt          # List of agents to include
    functions.json      # Auto-generated function declarations
    Argcfile.sh         # Build commands (argc)
```

## Choosing a Language

- **Bash**: Use for simple scripts, system operations, file I/O, and when dependencies are minimal
- **JavaScript**: Use for complex logic, data processing, HTTP requests, and when npm packages are needed
- **Python**: Use for data science, ML, complex data structures, and when Python libraries are required

## Creating Tools

### Bash Tool (`tools/<name>.sh`)

```bash
#!/usr/bin/env bash
set -e

# @describe Brief description of what the tool does
# @option --param!               Required string parameter
# @option --param-enum![a|b|c]   Required enum parameter
# @option --param-opt            Optional string parameter
# @flag --boolean-flag           Boolean flag
# @option --count! <INT>         Required integer
# @option --ratio! <NUM>         Required number/float
# @option --items+ <VALUE>       Required array (use +)
# @option --tags*                Optional array (use *)

# @env LLM_OUTPUT=/dev/stdout The output path

main() {
    echo "param: $argc_param" >> "$LLM_OUTPUT"
}

eval "$(argc --argc-eval "$0" "$@")"
```

**Key patterns:**
- `!` suffix = required
- `+` suffix = required array
- `*` suffix = optional array
- `<INT>` = integer type, `<NUM>` = number/float
- `[a|b|c]` = enum constraint
- Output goes to `$LLM_OUTPUT`
- Access params as `$argc_<param_name>` (underscores replace hyphens)

**Error handling:**
```bash
main() {
    if [[ -z "$argc_param" ]]; then
        echo "Error: param is required" >> "$LLM_OUTPUT"
        exit 1
    fi
    # Your logic here
}
```

### JavaScript Tool (`tools/<name>.js`)

```javascript
/**
 * Brief description of what the tool does.
 * @typedef {Object} Args
 * @property {string} param - Required string parameter
 * @property {'a'|'b'|'c'} param_enum - Required enum parameter
 * @property {string} [param_opt] - Optional string parameter (brackets)
 * @property {boolean} boolean_flag - Boolean parameter
 * @property {Integer} count - Required integer (capital I)
 * @property {number} ratio - Required number/float
 * @property {string[]} items - Required array
 * @property {string[]} [tags] - Optional array (brackets)
 * @param {Args} args
 */
exports.run = function (args) {
  return `param: ${args.param}`;
};
```

**Key patterns:**
- `[optional]` = brackets indicate optional
- `Integer` (capital I) = integer type
- `'a'|'b'` = enum union type
- `string[]` = array type
- Return string or write to stdout

**Error handling:**
```javascript
exports.run = function (args) {
  if (!args.param) {
    return JSON.stringify({ error: "param is required" });
  }
  // Your logic here
  return result;
};
```

### Python Tool (`tools/<name>.py`)

```python
from typing import List, Literal, Optional

def run(
    param: str,
    param_enum: Literal["a", "b", "c"],
    boolean_flag: bool,
    count: int,
    ratio: float,
    items: List[str],
    param_opt: Optional[str] = None,
    tags: Optional[List[str]] = None,
):
    """Brief description of what the tool does.
    Args:
        param: Required string parameter
        param_enum: Required enum parameter
        boolean_flag: Boolean parameter
        count: Required integer
        ratio: Required number/float
        items: Required array
        param_opt: Optional string parameter
        tags: Optional array
    """
    return f"param: {param}"
```

**Key patterns:**
- `Optional[T]` = optional parameter with default `None`
- `Literal["a", "b"]` = enum type
- `List[str]` = array type
- Docstring describes each parameter

**Error handling:**
```python
def run(param: str, ...):
    if not param:
        return json.dumps({"error": "param is required"})
    # Your logic here
    return result
```

## Creating Agents

### Directory Structure

```
agents/<agent-name>/
    index.yaml      # Agent definition (required)
    tools.{sh,js,py} # Agent-specific tools (optional)
    tools.txt       # Shared tools to include (optional)
    functions.json  # Auto-generated (don't edit)
```

### index.yaml

```yaml
name: AgentName
description: Brief description of what the agent does
version: 0.1.0
instructions: |
  You are a helpful agent that...

  Available tools:
  - tool_name: Description of what it does

  Guidelines:
  - Always use the appropriate tool
  - Handle errors gracefully

variables:
  - name: user_preference
    description: User's preference setting
    default: default_value

documents:
  - README.md
  - docs/

conversation_starters:
  - What can you help me with?
  - Show me the available options
```

**Built-in variables (don't redefine):**
- `__os__`, `__os_family__`, `__arch__`, `__shell__`
- `__locale__`, `__now__`, `__cwd__`, `__tools__`

**Access variables:**
- In instructions: `{{variable_name}}`
- In scripts: `$LLM_AGENT_VAR_VARIABLE_NAME`

### Agent Tools (`tools.{sh,js,py}`)

Agent tools can have **multiple functions** (unlike shared tools which have one):

```bash
#!/usr/bin/env bash
set -e

# @env LLM_OUTPUT=/dev/stdout The output path

# @cmd First tool function
# @option --param! Description
tool_function_one() {
    echo "result" >> "$LLM_OUTPUT"
}

# @cmd Second tool function
# @option --param! Description
tool_function_two() {
    echo "result" >> "$LLM_OUTPUT"
}

eval "$(argc --argc-eval "$0" "$@")"
```

**Key difference:** Use `# @cmd` instead of `# @describe`, and named functions instead of `main()`.

## Build Commands

```bash
# Build all tools and agents
argc build

# Build specific tool
argc build@tool tools/my_tool.sh

# Build specific agent
argc build@agent my_agent

# Run a tool directly
argc run@tool my_tool '{"param": "value"}'

# Run an agent action
argc run@agent my_agent action_name '{"param": "value"}'

# Check dependencies
argc check

# List available tools
argc list@tool

# List available agents
argc list@agent

# Create tool boilerplate
argc create@tool new_tool.sh param1 param2! array_param+
```

## Environment Variables

Tools receive these environment variables:
- `LLM_OUTPUT`: Path to write output (default: `/dev/stdout`)
- `LLM_ROOT_DIR`: Repository root directory
- `LLM_TOOL_NAME`: Current tool name
- `LLM_TOOL_CACHE_DIR`: Cache directory for tool
- `LLM_AGENT_VAR_*`: Agent variables (in agent tools)

Required env vars are declared with:
```bash
# @env API_KEY! Required API key
# @env OPTIONAL_VAR=default Default value
```

## MCP Integration

### mcp.json (for external MCP tools)

```json
{
  "mcpServers": {
    "server-name": {
      "command": "path/to/server",
      "args": ["--arg"],
      "prefix": true
    }
  }
}
```

### Expose tools via MCP

```bash
node mcp/server/index.js /path/to/llm-functions [agent-name]
```

## Quick Reference

| Task | Command/Pattern |
|------|-----------------|
| Create bash tool | `argc create@tool name.sh param! array+` |
| Create js tool | `argc create@tool name.js param! array+` |
| Create py tool | `argc create@tool name.py param! array+` |
| Add tool to project | Add filename to `tools.txt` |
| Add agent to project | Add agent name to `agents.txt` |
| Build everything | `argc build` |
| Check setup | `argc check` |
| Test tool | `argc run@tool tool_name '{"param":"val"}'` |

## Common Patterns

### Error handling

Always validate inputs and handle errors gracefully:

```bash
# Check required parameters
if [[ -z "$argc_required_param" ]]; then
    echo "Error: required_param is required" >> "$LLM_OUTPUT"
    exit 1
fi

# Check file existence
if [[ ! -f "$file_path" ]]; then
    echo "Error: file not found: $file_path" >> "$LLM_OUTPUT"
    exit 1
fi

# Return error JSON
echo "{\"error\": \"description\"}" >> "$LLM_OUTPUT"
exit 1
```

### Guard operations (destructive actions)

```bash
# In tools or agent tools
"$ROOT_DIR/utils/guard_path.sh" "$target_path" "Operation description?"
"$ROOT_DIR/utils/guard_operation.sh" "Confirm destructive operation?"
```

### File operations

```bash
# Read file
cat "$file_path" >> "$LLM_OUTPUT"

# Write file
printf "%s" "$content" > "$file_path"
echo "File written: $file_path" >> "$LLM_OUTPUT"

# Append to file
echo "$content" >> "$file_path"
```

### HTTP requests

```bash
# GET request
curl -fsSL "$url" >> "$LLM_OUTPUT"

# POST request
curl -fsSL -X POST -H "Content-Type: application/json" -d "$data" "$url" >> "$LLM_OUTPUT"
```

### JSON processing

```bash
# Parse JSON argument
value=$(echo "$json_data" | jq -r '.key')

# Output JSON
echo "{\"result\": \"$value\"}" >> "$LLM_OUTPUT"
```
