#!/usr/bin/env bash
set -e

# @env LLM_OUTPUT=/dev/stdout The output path

ROOT_DIR="${LLM_ROOT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"

# @cmd List all Docker services in the ~/workspace/docker directory on the homelab server
# @option --ssh-host The SSH host (user@hostname or hostname)
# @option --docker-dir The docker directory path on remote server (default: ~/workspace/docker)
homelab_list_services() {
    local ssh_host="${argc_ssh_host:-homelab}"
    local docker_dir="${argc_docker_dir:-~/workspace/docker}"
    
    echo "Listing Docker services in $docker_dir on $ssh_host..." >> "$LLM_OUTPUT"
    echo "" >> "$LLM_OUTPUT"
    
    ssh "$ssh_host" "if [ -d $docker_dir ]; then ls -1 $docker_dir; else echo 'Docker directory not found'; exit 1; fi" >> "$LLM_OUTPUT" 2>&1
}

# @cmd Read docker-compose.yml and .env files for a specific service on the homelab server
# @option --service! The service name (directory name in ~/workspace/docker)
# @option --ssh-host The SSH host (user@hostname or hostname)
# @option --docker-dir The docker directory path on remote server (default: ~/workspace/docker)
# @flag --env-only Only read the .env file
# @flag --compose-only Only read the docker-compose.yml file
homelab_read_service_config() {
    local ssh_host="${argc_ssh_host:-homelab}"
    local docker_dir="${argc_docker_dir:-~/workspace/docker}"
    local service_dir="$docker_dir/$argc_service"
    
    echo "Reading configuration for service: $argc_service" >> "$LLM_OUTPUT"
    echo "============================================" >> "$LLM_OUTPUT"
    echo "" >> "$LLM_OUTPUT"
    
    if ! ssh "$ssh_host" "[ -d $service_dir ]"; then
        echo "Error: Service directory '$argc_service' not found in $docker_dir" >> "$LLM_OUTPUT"
        exit 1
    fi
    
    if [ "${argc_compose_only:-0}" -eq 1 ] || [ "${argc_env_only:-0}" -eq 0 ]; then
        echo "--- docker-compose.yml ---" >> "$LLM_OUTPUT"
        if ssh "$ssh_host" "[ -f $service_dir/docker-compose.yml ]"; then
            ssh "$ssh_host" "cat $service_dir/docker-compose.yml" >> "$LLM_OUTPUT"
        else
            echo "docker-compose.yml not found" >> "$LLM_OUTPUT"
        fi
        echo "" >> "$LLM_OUTPUT"
    fi
    
    if [ "${argc_env_only:-0}" -eq 1 ] || [ "${argc_compose_only:-0}" -eq 0 ]; then
        echo "--- .env ---" >> "$LLM_OUTPUT"
        if ssh "$ssh_host" "[ -f $service_dir/.env ]"; then
            ssh "$ssh_host" "cat $service_dir/.env" >> "$LLM_OUTPUT"
        else
            echo ".env file not found" >> "$LLM_OUTPUT"
        fi
        echo "" >> "$LLM_OUTPUT"
    fi
    
    echo "--- Other files in service directory ---" >> "$LLM_OUTPUT"
    ssh "$ssh_host" "ls -la $service_dir" >> "$LLM_OUTPUT"
}

# @cmd Check the status of Docker containers on the homelab server
# @option --service The service name to filter containers (optional)
# @option --ssh-host The SSH host (user@hostname or hostname)
# @flag --all Show all containers including stopped ones
homelab_container_status() {
    local ssh_host="${argc_ssh_host:-homelab}"
    local docker_cmd="docker ps"
    
    if [ "${argc_all:-0}" -eq 1 ]; then
        docker_cmd="$docker_cmd -a"
    fi
    
    echo "Checking Docker container status on $ssh_host..." >> "$LLM_OUTPUT"
    echo "" >> "$LLM_OUTPUT"
    
    if [ -n "${argc_service:-}" ]; then
        echo "Filtering for service: $argc_service" >> "$LLM_OUTPUT"
        echo "" >> "$LLM_OUTPUT"
        ssh "$ssh_host" "$docker_cmd --filter name=$argc_service --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}\t{{.Image}}'" >> "$LLM_OUTPUT" 2>&1
    else
        ssh "$ssh_host" "$docker_cmd --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}\t{{.Image}}'" >> "$LLM_OUTPUT" 2>&1
    fi
}

# @cmd Start, stop, or restart Docker containers on the homelab server
# @option --service! The service name (directory name in ~/workspace/docker)
# @option --action! The action to perform (start, stop, restart, down, up)
# @option --ssh-host The SSH host (user@hostname or hostname)
# @option --docker-dir The docker directory path on remote server (default: ~/workspace/docker)
# @flag --build Force rebuild when using 'up' action
homelab_container_control() {
    "$ROOT_DIR/utils/guard_operation.sh"
    
    local ssh_host="${argc_ssh_host:-homelab}"
    local docker_dir="${argc_docker_dir:-~/workspace/docker}"
    local service_dir="$docker_dir/$argc_service"
    
    case "${argc_action}" in
        start|stop|restart|down|up)
            ;;
        *)
            echo "Error: Invalid action '${argc_action}'. Must be one of: start, stop, restart, down, up" >> "$LLM_OUTPUT"
            exit 1
            ;;
    esac
    
    echo "Performing '${argc_action}' on service: $argc_service" >> "$LLM_OUTPUT"
    echo "" >> "$LLM_OUTPUT"
    
    if ! ssh "$ssh_host" "[ -d $service_dir ]"; then
        echo "Error: Service directory '$argc_service' not found in $docker_dir" >> "$LLM_OUTPUT"
        exit 1
    fi
    
    local compose_cmd="cd $service_dir && docker-compose ${argc_action}"
    
    if [ "${argc_action}" = "up" ]; then
        compose_cmd="$compose_cmd -d"
        if [ "${argc_build:-0}" -eq 1 ]; then
            compose_cmd="$compose_cmd --build"
        fi
    fi
    
    ssh "$ssh_host" "$compose_cmd" >> "$LLM_OUTPUT" 2>&1
    
    echo "" >> "$LLM_OUTPUT"
    echo "Action '${argc_action}' completed successfully" >> "$LLM_OUTPUT"
}

# @cmd View Docker container logs on the homelab server
# @option --service! The service name (directory name in ~/workspace/docker)
# @option --ssh-host The SSH host (user@hostname or hostname)
# @option --docker-dir The docker directory path on remote server (default: ~/workspace/docker)
# @option --lines Number of log lines to show (default: 100)
# @option --container Specific container name within the service (optional)
# @flag --follow Follow log output (stream logs)
homelab_container_logs() {
    local ssh_host="${argc_ssh_host:-homelab}"
    local docker_dir="${argc_docker_dir:-~/workspace/docker}"
    local service_dir="$docker_dir/$argc_service"
    local lines="${argc_lines:-100}"
    
    echo "Viewing logs for service: $argc_service" >> "$LLM_OUTPUT"
    echo "============================================" >> "$LLM_OUTPUT"
    echo "" >> "$LLM_OUTPUT"
    
    if ! ssh "$ssh_host" "[ -d $service_dir ]"; then
        echo "Error: Service directory '$argc_service' not found in $docker_dir" >> "$LLM_OUTPUT"
        exit 1
    fi
    
    local logs_cmd="cd $service_dir && docker-compose logs --tail=$lines"
    
    if [ -n "${argc_container:-}" ]; then
        logs_cmd="$logs_cmd $argc_container"
    fi
    
    if [ "${argc_follow:-0}" -eq 1 ]; then
        logs_cmd="$logs_cmd -f"
        echo "Following logs (press Ctrl+C to stop)..." >> "$LLM_OUTPUT"
        echo "" >> "$LLM_OUTPUT"
    fi
    
    ssh "$ssh_host" "$logs_cmd" >> "$LLM_OUTPUT" 2>&1
}

# @cmd Create a new Docker service directory with docker-compose.yml and .env files
# @option --service! The service name (directory name to create)
# @option --ssh-host The SSH host (user@hostname or hostname)
# @option --docker-dir The docker directory path on remote server (default: ~/workspace/docker)
# @option --compose-content! The content of docker-compose.yml file
# @option --env-content The content of .env file (optional)
# @flag --create-data-dir Create a data directory for persistent volumes
# @flag --create-config-dir Create a config directory for service configuration
homelab_create_service() {
    "$ROOT_DIR/utils/guard_operation.sh"
    
    local ssh_host="${argc_ssh_host:-homelab}"
    local docker_dir="${argc_docker_dir:-~/workspace/docker}"
    local service_dir="$docker_dir/$argc_service"
    
    echo "Creating new Docker service: $argc_service" >> "$LLM_OUTPUT"
    echo "" >> "$LLM_OUTPUT"
    
    if ssh "$ssh_host" "[ -d $service_dir ]"; then
        echo "Error: Service directory '$argc_service' already exists in $docker_dir" >> "$LLM_OUTPUT"
        exit 1
    fi
    
    echo "Creating service directory..." >> "$LLM_OUTPUT"
    ssh "$ssh_host" "mkdir -p $service_dir" >> "$LLM_OUTPUT" 2>&1
    
    echo "Creating docker-compose.yml..." >> "$LLM_OUTPUT"
    ssh "$ssh_host" "cat > $service_dir/docker-compose.yml" <<< "$argc_compose_content" >> "$LLM_OUTPUT" 2>&1
    
    if [ -n "${argc_env_content:-}" ]; then
        echo "Creating .env file..." >> "$LLM_OUTPUT"
        ssh "$ssh_host" "cat > $service_dir/.env && chmod 600 $service_dir/.env" <<< "$argc_env_content" >> "$LLM_OUTPUT" 2>&1
    fi
    
    if [ "${argc_create_data_dir:-0}" -eq 1 ]; then
        echo "Creating data directory..." >> "$LLM_OUTPUT"
        ssh "$ssh_host" "mkdir -p $service_dir/data" >> "$LLM_OUTPUT" 2>&1
    fi
    
    if [ "${argc_create_config_dir:-0}" -eq 1 ]; then
        echo "Creating config directory..." >> "$LLM_OUTPUT"
        ssh "$ssh_host" "mkdir -p $service_dir/config" >> "$LLM_OUTPUT" 2>&1
    fi
    
    echo "" >> "$LLM_OUTPUT"
    echo "Service '$argc_service' created successfully!" >> "$LLM_OUTPUT"
    echo "Location: $service_dir" >> "$LLM_OUTPUT"
    echo "" >> "$LLM_OUTPUT"
    echo "To start the service, use: homelab_container_control --service=$argc_service --action=up" >> "$LLM_OUTPUT"
}

# @cmd Update an existing Docker service configuration
# @option --service! The service name (directory name in ~/workspace/docker)
# @option --ssh-host The SSH host (user@hostname or hostname)
# @option --docker-dir The docker directory path on remote server (default: ~/workspace/docker)
# @option --compose-content The new content of docker-compose.yml (optional)
# @option --env-content The new content of .env file (optional)
# @flag --backup Create backup of existing files before updating
homelab_update_service() {
    "$ROOT_DIR/utils/guard_operation.sh"
    
    local ssh_host="${argc_ssh_host:-homelab}"
    local docker_dir="${argc_docker_dir:-~/workspace/docker}"
    local service_dir="$docker_dir/$argc_service"
    
    echo "Updating Docker service: $argc_service" >> "$LLM_OUTPUT"
    echo "" >> "$LLM_OUTPUT"
    
    if ! ssh "$ssh_host" "[ -d $service_dir ]"; then
        echo "Error: Service directory '$argc_service' not found in $docker_dir" >> "$LLM_OUTPUT"
        exit 1
    fi
    
    if [ "${argc_backup:-0}" -eq 1 ]; then
        local timestamp=$(date +%Y%m%d_%H%M%S)
        echo "Creating backups with timestamp: $timestamp" >> "$LLM_OUTPUT"
        
        if ssh "$ssh_host" "[ -f $service_dir/docker-compose.yml ]"; then
            ssh "$ssh_host" "cp $service_dir/docker-compose.yml $service_dir/docker-compose.yml.backup_$timestamp" >> "$LLM_OUTPUT" 2>&1
            echo "Backed up docker-compose.yml" >> "$LLM_OUTPUT"
        fi
        
        if ssh "$ssh_host" "[ -f $service_dir/.env ]"; then
            ssh "$ssh_host" "cp $service_dir/.env $service_dir/.env.backup_$timestamp" >> "$LLM_OUTPUT" 2>&1
            echo "Backed up .env" >> "$LLM_OUTPUT"
        fi
        echo "" >> "$LLM_OUTPUT"
    fi
    
    if [ -n "${argc_compose_content:-}" ]; then
        echo "Updating docker-compose.yml..." >> "$LLM_OUTPUT"
        ssh "$ssh_host" "cat > $service_dir/docker-compose.yml" <<< "$argc_compose_content" >> "$LLM_OUTPUT" 2>&1
    fi
    
    if [ -n "${argc_env_content:-}" ]; then
        echo "Updating .env file..." >> "$LLM_OUTPUT"
        ssh "$ssh_host" "cat > $service_dir/.env && chmod 600 $service_dir/.env" <<< "$argc_env_content" >> "$LLM_OUTPUT" 2>&1
    fi
    
    echo "" >> "$LLM_OUTPUT"
    echo "Service '$argc_service' updated successfully!" >> "$LLM_OUTPUT"
    echo "" >> "$LLM_OUTPUT"
    echo "To apply changes, restart the service using:" >> "$LLM_OUTPUT"
    echo "  homelab_container_control --service=$argc_service --action=down" >> "$LLM_OUTPUT"
    echo "  homelab_container_control --service=$argc_service --action=up" >> "$LLM_OUTPUT"
}

eval "$(argc --argc-eval "$0" "$@")"
