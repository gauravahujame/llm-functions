# Coding Agent

This agent demonstrates a lightweight coding workflow that uses JavaScript tools available in `tools/`.

Capabilities
- Read files (`fs_read.js`)
- Write files (`fs_write.js`)
- Execute commands (`execute_command.js`)
- Perform simple web lookups (`web_search_stub.js`)

Configuration
- The agent is configured in `config.yaml` and lists the `use_tools` it expects.

Usage
- Add `coding-agent` to the top-level `agents.txt` to enable it for `argc build` and related workflows.
