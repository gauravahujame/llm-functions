# Homelab Agent

An AI agent specialized in managing Docker containers on a homelab server via SSH.

## Overview

The Homelab Agent provides comprehensive Docker container management capabilities for remote homelab servers. It can discover services, manage container lifecycles, view logs, and create or update Docker Compose configurations.

## Capabilities

### 1. Service Discovery
- List all Docker services in `~/workspace/docker` directory
- Read docker-compose.yml and .env files
- View service configurations and dependencies

### 2. Container Management
- Check status of running containers
- Start, stop, and restart containers
- Monitor container health
- View container logs

### 3. Service Creation
- Create new Docker service directories
- Generate docker-compose.yml files
- Set up .env files with proper permissions
- Create data and config directories

### 4. Service Updates
- Update docker-compose.yml configurations
- Modify environment variables
- Backup existing configurations
- Apply changes safely

## Available Tools

### Core Homelab Tools

| Tool | Description |
|------|-------------|
| `homelab_list_services` | List all Docker services in ~/workspace/docker |
| `homelab_read_service_config` | Read docker-compose.yml and .env for a service |
| `homelab_container_status` | Check container status via SSH |
| `homelab_container_control` | Start, stop, restart containers |
| `homelab_container_logs` | View container logs |
| `homelab_create_service` | Create new Docker service |
| `homelab_update_service` | Update service configuration |

### General Tools
- `execute_command` - Execute shell commands (for SSH operations)
- `fs_read` - Read local files
- `fs_write` - Write to local files

## Usage Examples

### Starting the Agent

```bash
aichat --agent homelab-agent
```

### Example Conversations

1. **List all services:**
   ```
   > List all Docker services running on my homelab
   ```

2. **View service configuration:**
   ```
   > Show me the configuration for the nextcloud service
   ```

3. **Check container status:**
   ```
   > What's the status of all running containers?
   ```

4. **View logs:**
   ```
   > Show me the last 50 lines of logs for the nginx service
   ```

5. **Create a new service:**
   ```
   > Create a new Docker service for Portainer with the following setup:
   > - Port 9000 exposed
   > - Volume for Docker socket
   > - Restart policy: always
   ```

6. **Control containers:**
   ```
   > Stop the database container
   > Restart the nginx container
   > Start the plex service with rebuild
   ```

7. **Update a service:**
   ```
   > Update the environment variables for the nextcloud service:
   > MYSQL_PASSWORD=newpassword
   > NEXTCLOUD_ADMIN_USER=admin
   ```

## Configuration

### SSH Setup

The agent assumes SSH connectivity to your homelab server. By default, it uses the hostname `homelab`. You can customize this:

```bash
# In your ~/.ssh/config
Host homelab
    HostName 192.168.1.100
    User your-username
    IdentityFile ~/.ssh/homelab_key
```

### Directory Structure

Services should be organized in the following structure on your homelab:

```
~/workspace/docker/
├── service-name-1/
│   ├── docker-compose.yml
│   ├── .env
│   ├── data/
│   └── config/
├── service-name-2/
│   ├── docker-compose.yml
│   ├── .env
│   └── data/
└── ...
```

### Custom SSH Host

You can specify a different SSH host in your queries:

```
> List services on --ssh-host=production-server
```

## Tool Parameters

### Common Parameters

All homelab tools support these common parameters:

- `--ssh-host` - SSH host (default: "homelab")
- `--docker-dir` - Docker directory path (default: "~/workspace/docker")

### Tool-Specific Parameters

#### homelab_list_services
```bash
homelab_list_services [--ssh-host HOST] [--docker-dir DIR]
```

#### homelab_read_service_config
```bash
homelab_read_service_config --service SERVICE_NAME [--ssh-host HOST] [--env-only] [--compose-only]
```

#### homelab_container_status
```bash
homelab_container_status [--service SERVICE_NAME] [--ssh-host HOST] [--all]
```

#### homelab_container_control
```bash
homelab_container_control --service SERVICE_NAME --action ACTION [--ssh-host HOST] [--build]

Actions: start, stop, restart, down, up
```

#### homelab_container_logs
```bash
homelab_container_logs --service SERVICE_NAME [--ssh-host HOST] [--lines N] [--container NAME] [--follow]
```

#### homelab_create_service
```bash
homelab_create_service --service SERVICE_NAME --compose-content CONTENT [--env-content CONTENT] [--create-data-dir] [--create-config-dir]
```

#### homelab_update_service
```bash
homelab_update_service --service SERVICE_NAME [--compose-content CONTENT] [--env-content CONTENT] [--backup]
```

## Best Practices

1. **Always read before modify** - Use `homelab_read_service_config` before making changes
2. **Back up configurations** - Use the `--backup` flag when updating services
3. **Check status first** - Verify container status before performing operations
4. **Use .env files** - Never hardcode credentials in docker-compose.yml
5. **Test SSH connectivity** - Ensure SSH access is working before using the agent

## Security Considerations

- All .env files are created with 0600 permissions (read/write for owner only)
- Use SSH key-based authentication instead of passwords
- Keep Docker images updated for security patches
- Use Docker secrets for production credentials
- Regularly review container logs for anomalies

## Troubleshooting

### SSH Connection Issues
```
Error: Permission denied (publickey)
Solution: Verify SSH keys and ~/.ssh/config
```

### Docker Directory Not Found
```
Error: Docker directory not found
Solution: Check --docker-dir path or create ~/workspace/docker
```

### Container Won't Start
```
Solution: Check logs with homelab_container_logs --service SERVICE_NAME
```

### docker-compose Command Not Found
```
Solution: Ensure docker-compose is installed on the homelab server
```

## Version

Current version: 0.1.0

## License

This agent is part of the llm-functions framework.
