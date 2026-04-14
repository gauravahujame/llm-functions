#!/usr/bin/env bash
set -e

# @cmd Query yabai information (spaces, windows, displays)
# @option --type![spaces|windows|displays] Type of information to query
yabai_query() {
    # Check if user wants auto-approval
    if [[ "${LLM_AGENT_VAR_AUTO_APPROVE,,}" != "true" ]]; then
        echo "About to query yabai --query $argc_type"
        read -p "Proceed? [y/N] " -n 1 -r
        echo
        [[ ! $REPLY =~ ^[Yy]$ ]] && exit 1
    fi

    result=$(yabai -m query --$argc_type 2>&1)
    echo "$result" >> "$LLM_OUTPUT"
}

# @cmd Move window to specific space
# @option --window-id! Window ID to move
# @option --space! <INT> Target space number
yabai_move_window() {
    if [[ "${LLM_AGENT_VAR_AUTO_APPROVE,,}" != "true" ]]; then
        echo "About to move window $argc_window_id to space $argc_space"
        read -p "Proceed? [y/N] " -n 1 -r
        echo
        [[ ! $REPLY =~ ^[Yy]$ ]] && exit 1
    fi

    yabai -m window "$argc_window_id" --space "$argc_space"
    echo "Window $argc_window_id moved to space $argc_space" >> "$LLM_OUTPUT"
}

# @cmd Get current workspace layout
yabai_get_layout() {
    current_layout=$(yabai -m query --spaces --space | jq -r '.type')
    echo "Current layout: $current_layout" >> "$LLM_OUTPUT"
}

# @cmd Focus on specific space
# @option --space! <INT> Space number to focus
yabai_focus_space() {
    yabai -m space --focus "$argc_space"
    echo "Focused on space $argc_space" >> "$LLM_OUTPUT"
}

eval "$(argc --argc-eval "$0" "$@")"
