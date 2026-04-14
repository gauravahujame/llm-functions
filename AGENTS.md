# LLM Functions Repository Learnings

## Skills Integration

The llm-functions framework has a companion skill for AI agents at `.agents/skills/llm-functions/SKILL.md`.

### For AI Agents

- **Primary skill**: `.agents/skills/llm-functions/SKILL.md` - Comprehensive framework guide
- Reference the skill when creating: new tools, agents, or modifying the build system

### For Framework Users

- Tools: Single-function files in `tools/` (Bash/JS/Python supported)
- Agents: Directories in `agents/` with `index.yaml` + optional `tools.{sh,js,py}`
- Build: `argc build` generates `functions.json` and symlinks in `bin/`
- For detailed documentation, see the companion skill at `.agents/skills/llm-functions/`

## Tool Definition Patterns

- Bash tools use `# @describe` + `main()` function; Agent tools use `# @cmd` + named functions
- Parameter names in kebab-case (`--my-param`) become `argc_my_param` (underscore) in bash
- `!` suffix marks required params, `+` for required arrays, `*` for optional arrays
- `Integer` (capital I) in JSDoc generates integer JSON schema; lowercase `int` doesn't
- Python `Literal["a","b"]` generates enum schema; `Optional[T]` with `None` default makes optional

## Build System

- `argc build` reads `tools.txt` and `agents.txt` to determine what to build
- `functions.json` is auto-generated - never edit manually
- Build creates symlinks in `bin/` pointing to `scripts/run-tool.{sh,js,py}`
- Python tools with `.venv/` get special shim that activates venv

## Agent Variables

- User-defined variables accessible as `{{var_name}}` in `index.yaml` instructions
- Same variables available as `$LLM_AGENT_VAR_VAR_NAME` in tool scripts
- Built-in vars (`__os__`, `__cwd__`, etc.) must not be redefined in `variables:`

## MCP Bridge

- `mcp.json` defines external MCP servers to consume
- `mcp/bridge/index.js` runs HTTP server on port 8808 (configurable via `MCP_BRIDGE_PORT`)
- Tool names from MCP servers prefixed with server name unless `prefix: false`

## Output Handling

- All output must go to `$LLM_OUTPUT` (default: `/dev/stdout`)
- Tools can set `LLM_OUTPUT` to temp file for multi-step operations
- `LLM_DUMP_RESULTS` env var controls result display for specific tools

## Guards

- `utils/guard_path.sh <path> <message>` prompts user before path operations
- `utils/guard_operation.sh <message>` prompts for destructive operations
- Guards help prevent accidental data loss from LLM-initiated actions

## Web Search Tool Pattern

- No single `web_search.sh` - must link via `argc link-web-search web_search_*.sh`
- Same for `code_interpreter` - link via `argc link-code-interpreter execute_*_code.*`
