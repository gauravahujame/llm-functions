#!/usr/bin/env bash
set -e

# @cmd Scan directory and create organization plan (returns JSON)
# @option --dir! Directory to scan
# @flag --recursive Scan subdirectories
organizer_scan() {
    local dir="${argc_dir}"
    local recursive="${argc_recursive:-false}"

    # Normalize path
    dir="${dir/#\~/$HOME}"
    dir="${dir%/}"  # Remove trailing slash

    if [[ ! -d "$dir" ]]; then
        echo "{\"error\": \"Directory not found: $dir\"}" >> "$LLM_OUTPUT"
        return 1
    fi

    # Category definitions
    declare -A categories=(
        ["Documents"]="pdf txt md rtf epub doc docx xls xlsx ppt pptx"
        ["Images"]="jpg jpeg png gif webp svg heic bmp"
        ["Videos"]="mp4 mkv mov avi webm flv"
        ["Music"]="mp3 flac wav m4a ogg aac"
        ["Archives"]="zip tar gz rar 7z bz2"
        ["Applications"]="dmg exe msi app deb rpm pkg"
    )

    # Find files
    local find_cmd="find \"$dir\" -maxdepth 1 -type f ! -name '.*'"
    if [[ "$recursive" == "true" ]]; then
        find_cmd="find \"$dir\" -type f ! -name '.*'"
    fi

    # Build plan
    local plan="["
    local first=true
    local file_count=0

    while IFS= read -r filepath; do
        # Skip if empty
        [[ -z "$filepath" ]] && continue

        local filename=$(basename "$filepath")
        local rel_path="${filepath#$dir/}"

        # Skip if already in a category folder
        local parent_dir=$(basename "$(dirname "$filepath")")
        if [[ " ${!categories[@]} " =~ " $parent_dir " ]] || [[ "$parent_dir" == "Misc" ]]; then
            continue
        fi

        # Get extension
        local ext="${filename##*.}"
        ext="${ext,,}"  # lowercase

        # Determine category
        local category="Misc"
        for cat in "${!categories[@]}"; do
            if [[ " ${categories[$cat]} " =~ " $ext " ]]; then
                category="$cat"
                break
            fi
        done

        # Build destination path
        local dest_dir="$dir/$category"
        local dest_path="$dest_dir/$filename"

        # Add to plan
        if [[ "$first" == "false" ]]; then
            plan+=","
        fi
        first=false
        file_count=$((file_count + 1))

        # Escape paths for JSON
        local json_from=$(printf '%s' "$filepath" | sed 's/\\/\\\\/g; s/"/\\"/g')
        local json_to=$(printf '%s' "$dest_path" | sed 's/\\/\\\\/g; s/"/\\"/g')
        local json_cat=$(printf '%s' "$category" | sed 's/\\/\\\\/g; s/"/\\"/g')

        plan+="{\"from\":\"$json_from\",\"to\":\"$json_to\",\"category\":\"$json_cat\"}"

    done < <(eval "$find_cmd" 2>/dev/null)

    plan+="]"

    # Write plan
    if [[ "$file_count" -eq 0 ]]; then
        echo "{\"message\":\"No files to organize in $dir\",\"plan\":[]}" >> "$LLM_OUTPUT"
    else
        echo "{\"scanned\":\"$dir\",\"total_files\":$file_count,\"plan\":$plan}" >> "$LLM_OUTPUT"
    fi
}

# @cmd Execute organization plan (move files)
# @option --plan-json! JSON plan from organizer_scan (exact string)
organizer_execute() {
    local plan_json="${argc_plan_json}"

    if [[ -z "$plan_json" || "$plan_json" == "[]" || "$plan_json" == "{}" ]]; then
        echo "{\"error\":\"No plan provided or plan is empty\"}" >> "$LLM_OUTPUT"
        return 1
    fi

    # Verify jq is available
    if ! command -v jq &> /dev/null; then
        echo "{\"error\":\"jq is required but not installed\"}" >> "$LLM_OUTPUT"
        return 1
    fi

    # Validate JSON
    if ! echo "$plan_json" | jq empty 2>/dev/null; then
        echo "{\"error\":\"Invalid JSON in plan_json parameter\",\"received\":\"${plan_json:0:200}...\"}" >> "$LLM_OUTPUT"
        return 1
    fi

    # Extract plan array
    local plan_array
    if echo "$plan_json" | jq -e '.plan' > /dev/null 2>&1; then
        plan_array=$(echo "$plan_json" | jq -c '.plan')
    else
        plan_array="$plan_json"
    fi

    local total=$(echo "$plan_array" | jq 'length')
    
    if [[ "$total" -eq 0 ]]; then
        echo "{\"message\":\"No files to move\",\"moved\":0}" >> "$LLM_OUTPUT"
        return 0
    fi

    # Execute moves
    local moved=0
    local failed=0
    local results="["
    local first=true

    for i in $(seq 0 $((total - 1))); do
        local item=$(echo "$plan_array" | jq -c ".[$i]")
        local from=$(echo "$item" | jq -r '.from')
        local to=$(echo "$item" | jq -r '.to')
        local category=$(echo "$item" | jq -r '.category // "Unknown"')

        # Create destination directory
        local dest_dir=$(dirname "$to")
        mkdir -p "$dest_dir"

        # Move file
        if mv "$from" "$to" 2>/dev/null; then
            moved=$((moved + 1))
            
            [[ "$first" == "false" ]] && results+=","
            first=false
            results+="{\"file\":\"$(basename "$from")\",\"category\":\"$category\",\"status\":\"moved\"}"
        else
            failed=$((failed + 1))
            
            [[ "$first" == "false" ]] && results+=","
            first=false
            results+="{\"file\":\"$(basename "$from")\",\"category\":\"$category\",\"status\":\"failed\"}"
        fi
    done

    results+="]"

    echo "{\"total\":$total,\"moved\":$moved,\"failed\":$failed,\"results\":$results}" >> "$LLM_OUTPUT"
}

# @cmd Show category statistics without moving files (dry run)
# @option --dir! Directory to analyze
organizer_preview() {
    local dir="${argc_dir}"
    dir="${dir/#\~/$HOME}"

    if [[ ! -d "$dir" ]]; then
        echo "{\"error\":\"Directory not found: $dir\"}" >> "$LLM_OUTPUT"
        return 1
    fi

    # Run scan but don't execute
    argc_dir="$dir" organizer_scan

    # Get the plan and summarize
    local output=$(cat "$LLM_OUTPUT")
    
    if command -v jq &> /dev/null && echo "$output" | jq -e '.plan' > /dev/null 2>&1; then
        local summary=$(echo "$output" | jq -r '.plan | group_by(.category) | map({category: .[0].category, count: length}) | .[] | "\(.category): \(.count) files"')
        echo "" >> "$LLM_OUTPUT"
        echo "Preview (dry run):" >> "$LLM_OUTPUT"
        echo "$summary" >> "$LLM_OUTPUT"
    fi
}

eval "$(argc --argc-eval "$0" "$@")"

