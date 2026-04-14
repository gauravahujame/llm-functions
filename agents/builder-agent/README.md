# Builder Agent

An agent that automates the complete creation of new agents and tools in the llm-functions framework, from directory setup to validation.

## Overview

The Builder Agent is a specialized, comprehensive agent designed to automate the **entire process** of creating fully functional agents within the llm-functions framework. It handles everything from checking for existing tools, creating directories, generating configurations, building custom tools, registering components, and verifying the complete setup.

## Key Features

### Complete Automation
- ✅ **Tool Discovery**: Checks for existing tools to maximize reuse
- ✅ **Directory Creation**: Sets up proper agent structure with absolute paths
- ✅ **Configuration Generation**: Creates config.yaml and index.yaml with detailed instructions
- ✅ **Custom Tool Creation**: Generates bash, JavaScript, or Python tools with templates
- ✅ **Registration**: Adds agents to agents.txt and tools to tools.txt
- ✅ **Build & Verify**: Executes `argc build` and `argc check` automatically
- ✅ **Documentation**: Creates comprehensive README.md files

### Tool Creation Support
- **Bash Tools** (.sh): Shell script tools with argc annotations
- **JavaScript Tools** (.js): Node.js tools with async support
- **Python Tools** (.py): Python tools with proper structure
- **Template Provided**: Complete templates for all tool types
- **SSH Patterns**: Built-in patterns for remote operations

### Validation & Quality
- Validates all configurations before finalization
- Ensures proper file permissions (chmod +x for executables)
- Verifies tool registration in tools.txt
- Confirms agent registration in agents.txt
- Runs complete build and check cycle

## Usage

```bash
aichat --agent builder-agent
```

### Example Requests

#### Create a Complete Agent
```
> Create a new agent named 'database-agent' that can:
> - Execute SQL queries
> - View database schemas
> - Export data to CSV
> Include all necessary tools and configurations
```

#### Create an SSH-Based Agent
```
> Build a Git agent that manages repositories via SSH with tools for:
> - Cloning repositories
> - Checking status
> - Creating commits
> - Pushing changes
```

#### Create an API Agent
```
> Set up a REST API testing agent that can:
> - Make HTTP requests (GET, POST, PUT, DELETE)
> - Parse JSON responses
> - Save test results
```

## Complete Workflow

The Builder Agent follows this comprehensive 10-step process:

### 1. Check Existing Tools
- Lists all available tools in `/Users/gaurav/.config/llm-functions/tools/`
- Reviews tools.txt for registered tools
- Identifies reusable tools to avoid duplication

### 2. Create Agent Directory
- Creates directory at `/Users/gaurav/.config/llm-functions/agents/<agent-name>/`
- Uses proper naming (lowercase-with-hyphens)

### 3. Generate config.yaml
- Sets model (openai:gpt-4o, etc.)
- Configures temperature (0.2-0.7)
- Lists tools without extensions
- Sets max_tokens (2048-8192)

### 4. Generate index.yaml
- Creates comprehensive agent instructions
- Includes tool descriptions and usage
- Adds workflow guidelines
- Provides conversation starters

### 5. Create Custom Tools
- Generates bash/JS/Python tools as needed
- Uses proper templates with argc annotations
- Implements SSH patterns for remote tools
- Includes error handling and validation

### 6. Register Agent
- Adds agent name to `/Users/gaurav/.config/llm-functions/agents.txt`
- Ensures proper formatting (one per line)

### 7. Register Tools
- Adds tool files to `/Users/gaurav/.config/llm-functions/tools.txt`
- Includes file extensions (.sh, .js, .py)

### 8. Build Functions
- Executes `argc build` command
- Generates functions.json with tool schemas
- Creates executable binaries in bin/ directory

### 9. Verify Setup
- Runs `argc check` command
- Validates all tools and dependencies
- Confirms agent configuration

### 10. Create Documentation
- Generates comprehensive README.md
- Includes usage examples and parameters
- Documents all tools and capabilities

## Tool Templates

### Bash Tool Template
```bash
#!/usr/bin/env bash
set -e

# @describe Brief description
# @option --param! Required parameter
# @option --optional Optional parameter
# @flag --flag Boolean flag
# @env LLM_OUTPUT=/dev/stdout

ROOT_DIR="${LLM_ROOT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"

main() {
    echo "Output" >> "$LLM_OUTPUT"
}

eval "$(argc --argc-eval "$0" "$@")"
```

### JavaScript Tool Template
```javascript
#!/usr/bin/env node

/**
 * @describe Brief description
 * @option --param <param> Required parameter
 * @env LLM_OUTPUT=/dev/stdout
 */

const fs = require('fs');

exports.main = async function main(args) {
    const output = process.env.LLM_OUTPUT || '/dev/stdout';
    fs.appendFileSync(output, 'Output\n');
};

if (require.main === module) {
    const { argc } = require('@sigoden/argc');
    argc(exports);
}
```

### Python Tool Template
```python
#!/usr/bin/env python3

"""
@describe Brief description
@option --param! <param> Required parameter
@env LLM_OUTPUT=/dev/stdout
"""

import os

def main(param):
    output = os.environ.get('LLM_OUTPUT', '/dev/stdout')
    with open(output, 'a') as f:
        f.write('Output\n')

if __name__ == '__main__':
    import argc
    argc.run(main)
```

## Critical Paths

All paths are absolute for consistency:

- **Base**: `/Users/gaurav/.config/llm-functions`
- **Agents**: `/Users/gaurav/.config/llm-functions/agents/`
- **Tools**: `/Users/gaurav/.config/llm-functions/tools/`
- **Agents Registry**: `/Users/gaurav/.config/llm-functions/agents.txt`
- **Tools Registry**: `/Users/gaurav/.config/llm-functions/tools.txt`
- **Functions**: `/Users/gaurav/.config/llm-functions/functions.json`

## Available Tools

| Tool | Purpose | Parameters |
|------|---------|------------|
| `fs_mkdir` | Create directories | --path (required) |
| `fs_create` | Create files | --path, --contents (required) |
| `fs_patch` | Modify files | --path, --regexp, --replacement |
| `fs_cat` | Read files | --path (required) |
| `fs_ls` | List directories | --path (required) |
| `execute_command` | Run shell commands | --command (required) |

## Common Patterns

### SSH-Based Tools
```bash
ssh "$ssh_host" "cd $remote_dir && command" >> "$LLM_OUTPUT" 2>&1
```

### File Operations
```bash
"$ROOT_DIR/utils/guard_operation.sh"  # For destructive ops
```

### API Tools
```bash
curl -X POST "$api_url" -H "Authorization: Bearer $token" >> "$LLM_OUTPUT"
```

## Validation Checklist

Before completion, the agent verifies:

- ✓ Agent directory exists
- ✓ config.yaml created with valid syntax
- ✓ index.yaml created with comprehensive instructions
- ✓ Tools created with proper templates
- ✓ Tools are executable (chmod +x)
- ✓ Agent registered in agents.txt
- ✓ Tools registered in tools.txt
- ✓ `argc build` completed successfully
- ✓ `argc check` passed validation
- ✓ README.md documentation created

## Naming Conventions

- **Agents**: lowercase-with-hyphens (`database-agent`, `homelab-agent`)
- **Tools**: lowercase_with_underscores (`db_query.sh`, `homelab_list.sh`)
- **Configs**: lowercase.yaml
- **Docs**: UPPERCASE.md or README.md

## Security Features

1. Uses `guard_operation.sh` for destructive operations
2. Never hardcodes credentials
3. Sets proper file permissions (0600 for sensitive files)
4. Validates input parameters
5. Uses environment variables for secrets

## Error Handling

### If argc build fails:
- Checks tool syntax with `bash -n <tool>.sh`
- Verifies @describe and @option annotations
- Ensures tools are listed in tools.txt

### If argc check fails:
- Checks for missing dependencies
- Verifies tool paths are correct
- Validates config.yaml syntax

## Example Agent Creation

```
User: Create a monitoring agent that checks system health

Builder Agent:
1. Checks for existing tools (execute_command, fs_read)
2. Creates /Users/gaurav/.config/llm-functions/agents/monitoring-agent/
3. Generates config.yaml with system monitoring tools
4. Creates index.yaml with detailed instructions
5. Creates system_health.sh tool for health checks
6. Makes tool executable (chmod +x)
7. Registers 'monitoring-agent' in agents.txt
8. Registers 'system_health.sh' in tools.txt
9. Runs 'argc build' to generate functions.json
10. Runs 'argc check' to verify setup
11. Creates comprehensive README.md

Result: ✅ Fully functional monitoring-agent ready to use!
```

## Version History

- **0.2.0** (Current): Complete automation with tool creation, registration, and verification
- **0.1.0**: Basic agent directory and configuration creation

## Support

For issues or questions:
1. Check the agent's index.yaml for detailed workflow
2. Verify paths are absolute
3. Ensure argc and jq are installed
4. Review logs from argc build and argc check 