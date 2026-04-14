# 🧞 Genie Agent

Meta-agent that creates new llm-functions agents with complete file structure, tools, and configuration.

## Features

- **Complete Agent Scaffolding**: Creates all necessary files (index.yaml, tools.sh, tools.txt, README.md)
- **Custom Tool Generation**: Generates argc-based tool functions with proper syntax
- **Global Tool Integration**: References existing tools from tools/ directory
- **AIChat Integration**: Automatically creates aichat config
- **Validation**: Builds and validates agents after creation
- **Interactive Workflow**: Guides users through agent creation process

## Usage

### Create a Complete Agent

```
aichat --agent genie-agent "Create a Docker management agent that can list containers, view logs, and restart services"
```

### Create Agent with Specific Tools

```
aichat --agent genie-agent "I need a Git helper agent with tools to: check status, create branches, commit changes, and push to remote"
```

### List Available Global Tools

```
aichat --agent genie-agent "Show me all available global tools I can use"
```

## Custom Tools

- `genie_create_agent_dir` - Create agent directory
- `genie_create_index_yaml` - Generate agent metadata
- `genie_create_tools_sh` - Create custom tool functions
- `genie_create_tools_txt` - Link global tools
- `genie_create_readme` - Generate documentation
- `genie_register_agent` - Add to agents.txt
- `genie_build_agent` - Build and generate functions.json
- `genie_create_aichat_config` - Create AIChat integration
- `genie_create_complete_agent` - All-in-one workflow
- `genie_list_global_tools` - Show available tools

## Examples

### Example 1: File Organizer Agent

```
aichat --agent genie-agent "Create an agent called 'file-organizer' that can sort files by type, move files to directories, and clean up duplicate files"
```

**Result**: Creates complete agent with:

- Custom tools: `fileorg_sort_by_type`, `fileorg_move_files`, `fileorg_find_duplicates`
- Global tools: `fs_ls.sh`, `fs_mkdir.sh`, `execute_command.sh`
- Full documentation and AIChat integration

### Example 2: System Monitor Agent

```
aichat --agent genie-agent "Build a system-monitor agent to check CPU usage, memory stats, disk space, and running processes"
```

**Result**: Agent with tools for system metrics monitoring

### Example 3: Blog Manager Agent

```
aichat --agent genie-agent "I need a blog-manager agent that can create posts, list drafts, publish posts, and generate RSS feed"
```

## Agent Creation Workflow

The genie-agent follows this process:

1. **Understand** - Ask clarifying questions about agent purpose
2. **Design** - Determine tools needed (custom + global)
3. **Create** - Generate all required files
4. **Build** - Run argc build to generate functions.json
5. **Integrate** - Create AIChat configuration
6. **Validate** - Confirm successful creation
7. **Guide** - Provide usage instructions

## Configuration

Variables:

- `auto_approve`: Skip confirmation prompts (default: false)
- `default_model`: Model for new agents (default: gemini:gemini-2.5-flash-lite)
- `llm_functions_dir`: Path to llm-functions (default: ~/.config/llm-functions)

## Development

To extend genie-agent:

1. Edit `tools.sh` to add new creation tools
2. Update `instructions` in `index.yaml` for better guidance
3. Rebuild: `cd ~/.config/llm-functions && argc build`

## Tips

- Use descriptive agent names: `docker-manager`, `git-helper`, `file-organizer`
- Start simple - add tools iteratively
- Test agents immediately after creation
- Review generated files before use
- Use `auto_approve: true` variable for rapid development

## Created Agents Location

All agents are created in: `~/.config/llm-functions/agents/[agent-name]/`

Each contains:

- `index.yaml` - Metadata and instructions
- `tools.sh` - Custom tool implementations
- `tools.txt` - Global tool references
- `functions.json` - Auto-generated function declarations
- `README.md` - Documentation

## License

Part of llm-functions framework.
