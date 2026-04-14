#!/usr/bin/env bash
set -e

# Use LLM_ROOT_DIR which is automatically set and expanded correctly
GENIE_LLM_DIR="${LLM_ROOT_DIR:-$HOME/.config/llm-functions}"

# @cmd Create agent directory structure
# @option --name! Agent name (lowercase-with-dashes)
genie_create_agent_dir() {
    agent_path="$GENIE_LLM_DIR/agents/$argc_name"

    if [ -d "$agent_path" ]; then
        echo "⚠️  Agent directory already exists: $agent_path" >> "$LLM_OUTPUT"
        return 1
    fi

    mkdir -p "$agent_path"
    echo "✓ Created agent directory: $agent_path" >> "$LLM_OUTPUT"
}

# @cmd Create index.yaml for agent
# @option --name! Agent name
# @option --display-name! Human-readable name
# @option --description! One-line description
# @option --purpose! Detailed purpose explanation
# @option --variables JSON array of variables (optional)
# @option --starters JSON array of conversation starters (optional)
genie_create_index_yaml() {
    agent_path="$GENIE_LLM_DIR/agents/$argc_name"

    # Parse variables if provided
    variables_yaml=""
    if [ -n "$argc_variables" ]; then
        # Parse JSON and format with proper indentation
        while IFS= read -r line; do
            variables_yaml+="$line"$'\n'
        done < <(echo "$argc_variables" | jq -r '.[] | "  - name: \(.name)\n    description: \(.description)\n    default: \"\(.default)\""')
    else
        # Default variables with proper indentation
        read -r -d '' variables_yaml << 'VARS' || true
  - name: auto_approve
    description: Automatically approve operations without confirmation
    default: "false"
  - name: verbose
    description: Enable verbose output
    default: "false"
VARS
    fi

    # Parse conversation starters
    starters_yaml=""
    if [ -n "$argc_starters" ]; then
        while IFS= read -r line; do
            starters_yaml+="$line"$'\n'
        done < <(echo "$argc_starters" | jq -r '.[] | "  - \"\(.)\"" ')
    else
        starters_yaml="  - \"Help me with $argc_display_name\""
    fi

    # Create index.yaml with proper formatting
    cat > "$agent_path/index.yaml" << YAML
name: $argc_display_name
description: $argc_description
version: 0.1.0

instructions: |
  $argc_purpose

  You have access to custom tools specific to this agent.
  Use them to accomplish user requests efficiently.

  Always ask for clarification if user intent is unclear.
  Provide clear feedback after each operation.

variables:
$variables_yaml

conversation_starters:
$starters_yaml
YAML

    echo "✓ Created index.yaml for $argc_name" >> "$LLM_OUTPUT"
}

# @cmd Create tools.sh with custom tools
# @option --name! Agent name
# @option --tools! JSON array of tool definitions
genie_create_tools_sh() {
    agent_path="$GENIE_LLM_DIR/agents/$argc_name"
    tools_file="$agent_path/tools.sh"

    # Validate tools parameter
    if [ -z "$argc_tools" ] || [ "$argc_tools" = "null" ]; then
        echo "⚠️  No custom tools provided, skipping tools.sh" >> "$LLM_OUTPUT"
        return 0
    fi

    # Start tools.sh file
    cat > "$tools_file" << 'HEADER'
#!/usr/bin/env bash
set -e

HEADER

    # Generate each tool function
    echo "$argc_tools" | jq -c '.[]' | while read -r tool; do
        tool_name=$(echo "$tool" | jq -r '.name')
        tool_desc=$(echo "$tool" | jq -r '.description')

        # Start function
        echo "" >> "$tools_file"
        echo "# @cmd $tool_desc" >> "$tools_file"

        # Add options
        if echo "$tool" | jq -e '.options' > /dev/null 2>&1; then
            echo "$tool" | jq -c '.options[]?' 2>/dev/null | while read -r option; do
                opt_name=$(echo "$option" | jq -r '.name')
                opt_type=$(echo "$option" | jq -r '.type')
                opt_desc=$(echo "$option" | jq -r '.description')

                if [ "$opt_type" = "required" ]; then
                    echo "# @option --${opt_name}! $opt_desc" >> "$tools_file"
                elif [ "$opt_type" = "flag" ]; then
                    echo "# @flag --${opt_name} $opt_desc" >> "$tools_file"
                else
                    echo "# @option --${opt_name} $opt_desc" >> "$tools_file"
                fi
            done
        fi

        # Add function body
        cat >> "$tools_file" << FUNC
${tool_name}() {
    # TODO: Implement function logic
    echo "Executing: ${tool_name}" >> "\$LLM_OUTPUT"

    # Access parameters with: \$argc_parameter_name
    # Access flags with: \$argc_flag_name
    # Access agent variables with: \$LLM_AGENT_VAR_VARIABLE_NAME

    # Example implementation:
    # result=\$(some-command)
    # echo "\$result" >> "\$LLM_OUTPUT"
}

FUNC
    done

    # Add argc eval line
    echo 'eval "$(argc --argc-eval "$0" "$@")"' >> "$tools_file"

    chmod +x "$tools_file"

    tool_count=$(echo "$argc_tools" | jq 'length' 2>/dev/null || echo "0")
    echo "✓ Created tools.sh with $tool_count tools" >> "$LLM_OUTPUT"
}

# @cmd Create tools.txt with global tool references
# @option --name! Agent name
# @option --global-tools! JSON array of global tool names
genie_create_tools_txt() {
    agent_path="$GENIE_LLM_DIR/agents/$argc_name"
    tools_file="$agent_path/tools.txt"

    # Validate parameter
    if [ -z "$argc_global_tools" ] || [ "$argc_global_tools" = "null" ]; then
        echo "⚠️  No global tools provided, skipping tools.txt" >> "$LLM_OUTPUT"
        return 0
    fi

    # Write one tool per line (NOT JSON)
    echo "$argc_global_tools" | jq -r '.[]' > "$tools_file"

    tool_count=$(wc -l < "$tools_file" | tr -d ' ')
    echo "✓ Created tools.txt with $tool_count global tools" >> "$LLM_OUTPUT"
}

# @cmd Generate README.md for agent
# @option --name! Agent name
# @option --display-name! Human-readable name
# @option --description! Description
# @option --features! JSON array of feature descriptions
genie_create_readme() {
    agent_path="$GENIE_LLM_DIR/agents/$argc_name"
    readme_file="$agent_path/README.md"

    # Parse features
    features_md=""
    if [ -n "$argc_features" ] && [ "$argc_features" != "null" ]; then
        features_md=$(echo "$argc_features" | jq -r '.[] | "- \(.)"')
    else
        features_md="- Agent functionality"
    fi

    cat > "$readme_file" << README
# $argc_display_name

$argc_description

## Features

$features_md

## Installation

This agent is part of the llm-functions framework.

## Usage

### With AIChat

\`\`\`bash
aichat --agent $argc_name "your query here"
\`\`\`

### Direct Tool Execution

\`\`\`bash
cd ~/.config/llm-functions
argc run@agent $argc_name tool_name '{"param": "value"}'
\`\`\`

## Available Tools

See \`tools.sh\` for custom tools and \`tools.txt\` for global tools used by this agent.

## Configuration

Variables can be set in the agent's index.yaml:

- \`auto_approve\`: Skip confirmation prompts
- \`verbose\`: Enable detailed output

## Examples

\`\`\`bash
# Example 1
aichat --agent $argc_name "help me get started"

# Example 2
aichat --agent $argc_name "perform main task"
\`\`\`

## Development

To modify this agent:

1. Edit \`index.yaml\` for instructions and metadata
2. Edit \`tools.sh\` for custom tool implementations
3. Edit \`tools.txt\` to add/remove global tools
4. Rebuild: \`cd ~/.config/llm-functions && argc build\`

## License

Part of llm-functions framework.
README

    echo "✓ Created README.md" >> "$LLM_OUTPUT"
}

# @cmd Register agent in agents.txt
# @option --name! Agent name
genie_register_agent() {
    agents_file="$GENIE_LLM_DIR/agents.txt"

    # Check if already registered
    if grep -q "^$argc_name$" "$agents_file" 2>/dev/null; then
        echo "⚠️  Agent already registered in agents.txt" >> "$LLM_OUTPUT"
        return 0
    fi

    echo "$argc_name" >> "$agents_file"
    echo "✓ Registered $argc_name in agents.txt" >> "$LLM_OUTPUT"
}

# @cmd Build agent and generate functions.json
# @option --name! Agent name
genie_build_agent() {
    cd "$GENIE_LLM_DIR"

    if ! command -v argc &> /dev/null; then
        echo "✗ argc not found. Install with: brew install argc" >> "$LLM_OUTPUT"
        return 1
    fi

    # Run argc build and capture output
    build_output=$(argc build 2>&1)
    build_status=$?

    if [ $build_status -ne 0 ]; then
        echo "✗ Build failed:" >> "$LLM_OUTPUT"
        echo "$build_output" >> "$LLM_OUTPUT"
        return 1
    fi

    agent_path="$GENIE_LLM_DIR/agents/$argc_name"
    if [ -f "$agent_path/functions.json" ]; then
        func_count=$(jq '.tools | length' "$agent_path/functions.json" 2>/dev/null || echo "0")
        echo "✓ Built agent successfully - $func_count functions generated" >> "$LLM_OUTPUT"

        # Show function names
        if [ "$func_count" -gt 0 ]; then
            echo "  Functions:" >> "$LLM_OUTPUT"
            jq -r '.tools[].name' "$agent_path/functions.json" | sed 's/^/    - /' >> "$LLM_OUTPUT"
        fi
    else
        echo "⚠️  functions.json not generated - check for errors" >> "$LLM_OUTPUT"
    fi
}

# @cmd Create AIChat config for agent
# @option --name! Agent name
# @option --model Model to use (default: from variable)
# @option --temperature Temperature setting (default: 0.3)
# @option --max-tokens Max tokens (default: 4096)
genie_create_aichat_config() {
    aichat_agent_dir="$HOME/.config/aichat/agents/$argc_name"
    mkdir -p "$aichat_agent_dir"

    model="${argc_model:-${LLM_AGENT_VAR_DEFAULT_MODEL:-gemini:gemini-2.5-flash-lite}}"
    temperature="${argc_temperature:-0.3}"
    max_tokens="${argc_max_tokens:-4096}"

    cat > "$aichat_agent_dir/config.yaml" << YAML
model: $model
temperature: $temperature
max_tokens: $max_tokens
# Agent tools are pulled from llm-functions automatically
YAML

    echo "✓ Created AIChat config at $aichat_agent_dir/config.yaml" >> "$LLM_OUTPUT"
}

# @cmd Complete agent creation workflow
# @option --name! Agent name (lowercase-with-dashes)
# @option --display-name! Human-readable name
# @option --description! One-line description
# @option --purpose! Detailed purpose
# @option --tools JSON array of custom tool definitions (optional)
# @option --global-tools JSON array of global tool names (optional)
# @option --features JSON array of features for README (optional)
genie_create_complete_agent() {
    echo "🧞 Creating agent: $argc_name..." >> "$LLM_OUTPUT"
    echo "" >> "$LLM_OUTPUT"

    # Step 1: Create directory
    if ! genie_create_agent_dir --name="$argc_name"; then
        return 1
    fi

    # Step 2: Create index.yaml
    genie_create_index_yaml \
        --name="$argc_name" \
        --display-name="$argc_display_name" \
        --description="$argc_description" \
        --purpose="$argc_purpose"

    # Step 3: Create tools.sh (if custom tools provided)
    if [ -n "$argc_tools" ] && [ "$argc_tools" != "null" ]; then
        genie_create_tools_sh --name="$argc_name" --tools="$argc_tools"
    fi

    # Step 4: Create tools.txt (if global tools provided)
    if [ -n "$argc_global_tools" ] && [ "$argc_global_tools" != "null" ]; then
        genie_create_tools_txt --name="$argc_name" --global-tools="$argc_global_tools"
    fi

    # Step 5: Create README
    genie_create_readme \
        --name="$argc_name" \
        --display-name="$argc_display_name" \
        --description="$argc_description" \
        --features="${argc_features:-null}"

    # Step 6: Register
    genie_register_agent --name="$argc_name"

    # Step 7: Build
    if ! genie_build_agent --name="$argc_name"; then
        echo "⚠️  Build encountered issues, but agent files were created" >> "$LLM_OUTPUT"
    fi

    # Step 8: Create AIChat config
    genie_create_aichat_config --name="$argc_name"

    echo "" >> "$LLM_OUTPUT"
    echo "✨ Agent creation complete!" >> "$LLM_OUTPUT"
    echo "" >> "$LLM_OUTPUT"
    echo "📍 Location: ~/.config/llm-functions/agents/$argc_name" >> "$LLM_OUTPUT"
    echo "" >> "$LLM_OUTPUT"
    echo "🧪 Test with:" >> "$LLM_OUTPUT"
    echo "   aichat --agent $argc_name \"your query\"" >> "$LLM_OUTPUT"
}

# @cmd List all available global tools
genie_list_global_tools() {
    tools_dir="$GENIE_LLM_DIR/tools"

    echo "Available Global Tools:" >> "$LLM_OUTPUT"
    echo "======================" >> "$LLM_OUTPUT"
    echo "" >> "$LLM_OUTPUT"

    for tool in "$tools_dir"/*; do
        if [ -f "$tool" ]; then
            tool_name=$(basename "$tool")
            tool_desc=$(grep -h "^# @describe" "$tool" 2>/dev/null | sed 's/^# @describe //' || echo "No description")
            printf "%-30s %s\n" "$tool_name" "$tool_desc" >> "$LLM_OUTPUT"
        fi
    done
}

eval "$(argc --argc-eval "$0" "$@")"
