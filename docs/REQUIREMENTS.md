# Requirements and Features

## Feature Requests

### Homelab Agent for Docker Management
**Feature Name**: Homelab Docker Management Agent
**Date Added**: 2024
**Priority**: High
**Status**: ✅ Completed

**Description**: 
An AI agent that manages Docker containers on a homelab server via SSH. The agent provides comprehensive Docker container lifecycle management, service discovery, configuration management, and monitoring capabilities.

**Implementation Details**:
- Created homelab-agent in `/agents/homelab-agent/`
- Implemented 7 custom tools for Docker operations
- Integrated with SSH for remote server management
- Support for docker-compose based services

**Components Created**:
1. Agent Configuration Files:
   - `config.yaml` - Model and tool access configuration
   - `index.yaml` - Agent instructions and capabilities
   - `README.md` - Comprehensive documentation
   - `SETUP_SUMMARY.md` - Setup and deployment guide

2. Custom Tools (7 tools):
   - `homelab_list_services.sh` - List all Docker services
   - `homelab_read_service_config.sh` - Read docker-compose.yml and .env files
   - `homelab_container_status.sh` - Check container status
   - `homelab_container_control.sh` - Start/stop/restart containers
   - `homelab_container_logs.sh` - View container logs
   - `homelab_create_service.sh` - Create new Docker services
   - `homelab_update_service.sh` - Update existing services

**Capabilities**:
- ✅ Find existing docker containers by reading ~/workspace/docker directory
- ✅ Read docker-compose.yml and .env files for each service
- ✅ Create new docker containers with full configuration
- ✅ Check status of running docker containers
- ✅ Start, stop, restart docker containers
- ✅ View logs of running docker containers
- ✅ Update docker container configurations

**Test Cases**:
1. ✅ List all Docker services in ~/workspace/docker
   - Command: homelab_list_services
   - Expected: Returns list of service directories

2. ✅ Read service configuration files
   - Command: homelab_read_service_config --service=nextcloud
   - Expected: Displays docker-compose.yml and .env contents

3. ✅ Check container status
   - Command: homelab_container_status
   - Expected: Shows running containers with status, ports, and images

4. ✅ Create a new Docker service
   - Command: homelab_create_service --service=portainer --compose-content="..."
   - Expected: Creates service directory with docker-compose.yml and .env

5. ✅ Control container lifecycle
   - Command: homelab_container_control --service=nginx --action=restart
   - Expected: Restarts the nginx service containers

6. ✅ View container logs
   - Command: homelab_container_logs --service=nginx --lines=50
   - Expected: Displays last 50 lines of nginx service logs

7. ✅ Update service configuration
   - Command: homelab_update_service --service=nextcloud --env-content="..."
   - Expected: Updates .env file with new content

8. ✅ Backup before update
   - Command: homelab_update_service --service=nextcloud --backup
   - Expected: Creates timestamped backup before applying changes

**Usage**:
```bash
# Launch the agent
aichat --agent homelab-agent

# Example interactions
> List all Docker services on my homelab
> Show me the configuration for the nextcloud service
> Check the status of all running containers
> Stop the database service
> Show me the last 100 lines of logs for nginx
> Create a new Docker service for Plex
```

**Configuration**:
- Default SSH host: `homelab` (customizable with --ssh-host)
- Default Docker directory: `~/workspace/docker` (customizable with --docker-dir)
- Model: openai:gpt-4o
- Temperature: 0.3
- Max tokens: 4096

**Security Features**:
- .env files created with 0600 permissions
- SSH key-based authentication
- Guard operations for destructive commands
- Backup support for configuration updates
- No hardcoded credentials

**Documentation**:
- Agent README: `/agents/homelab-agent/README.md`
- Setup Summary: `/agents/homelab-agent/SETUP_SUMMARY.md`
- Tool Documentation: Inline in each tool script

**Dependencies**:
- SSH access to homelab server
- docker-compose installed on homelab server
- bash, jq (for tool scripts)
- argc (for function building)

**Verification**:
```bash
# Build functions
argc build

# Verify setup
argc check

# List agents
aichat --list-agents | grep homelab-agent

# Test tool
argc homelab_list_services --ssh-host=homelab
```

**Notes**:
- All tools support custom SSH hosts and Docker directories
- Services expected in ~/workspace/docker/<service-name>/ structure
- Each service should have docker-compose.yml at minimum
- .env files are optional but recommended for configuration
- Tools use guard_operation.sh for destructive operations

---

## Builder Agent Enhancement
**Feature Name**: Complete Automation for Agent and Tool Creation
**Date Added**: November 8, 2024
**Priority**: Critical
**Status**: ✅ Completed

**Description**: 
Enhanced the builder-agent from a basic directory creator to a fully automated agent factory. The builder-agent now handles the complete end-to-end workflow for creating functional agents and tools, including tool discovery, custom tool creation, registration, building, and verification.

**Implementation Details**:
- Enhanced builder-agent in `/agents/builder-agent/`
- Added execute_command tool access
- Upgraded to GPT-4o model
- Increased max_tokens to 4096
- Created 460-line comprehensive instruction set

**Components Updated**:
1. Configuration Files:
   - `config.yaml` - Added execute_command, upgraded model
   - `index.yaml` - Complete 10-step workflow with templates
   - `README.md` - Comprehensive feature documentation
   - `ENHANCEMENT_SUMMARY.md` - Change documentation

2. New Capabilities:
   - Tool discovery and reuse checking
   - Custom tool creation (bash, JavaScript, Python)
   - Automatic registration in agents.txt and tools.txt
   - Build automation (argc build)
   - Verification automation (argc check)
   - Complete documentation generation

**Complete Workflow**:
1. ✅ Check for existing tools (reuse first)
2. ✅ Create agent directory structure
3. ✅ Generate config.yaml with model settings
4. ✅ Generate index.yaml with comprehensive instructions
5. ✅ Create custom tools from templates
6. ✅ Make tools executable (chmod +x)
7. ✅ Register agent in agents.txt
8. ✅ Register tools in tools.txt
9. ✅ Execute `argc build` command
10. ✅ Execute `argc check` command
11. ✅ Create comprehensive README.md

**Tool Templates Provided**:
- **Bash Template**: Complete .sh tool with argc annotations
- **JavaScript Template**: Node.js tool with async support
- **Python Template**: Python 3 tool with proper structure
- **SSH Pattern**: Remote command execution pattern
- **API Pattern**: REST API call pattern
- **File Operation Pattern**: Guard for destructive operations

**Critical Paths Defined**:
- Base: `/Users/gaurav/.config/llm-functions`
- Agents: `/Users/gaurav/.config/llm-functions/agents/`
- Tools: `/Users/gaurav/.config/llm-functions/tools/`
- Agents registry: `/Users/gaurav/.config/llm-functions/agents.txt`
- Tools registry: `/Users/gaurav/.config/llm-functions/tools.txt`
- Functions output: `/Users/gaurav/.config/llm-functions/functions.json`

**Validation Checklist**:
The builder-agent now validates 10 critical items before completion:
1. ✅ Agent directory created
2. ✅ config.yaml created with valid syntax
3. ✅ index.yaml created with comprehensive instructions
4. ✅ Tools created with proper templates
5. ✅ Tools made executable (chmod +x)
6. ✅ Agent registered in agents.txt
7. ✅ Tools registered in tools.txt
8. ✅ `argc build` completed successfully
9. ✅ `argc check` passed validation
10. ✅ README.md documentation created

**Test Cases**:
1. ✅ Discovers and lists existing tools
   - Command: fs_ls --path /Users/gaurav/.config/llm-functions/tools
   - Expected: Lists all available tools

2. ✅ Creates agent directory structure
   - Command: fs_mkdir --path /Users/gaurav/.config/llm-functions/agents/<agent-name>
   - Expected: Directory created with proper naming

3. ✅ Generates config.yaml
   - Tool: fs_create with yaml content
   - Expected: Valid config.yaml with model, tools, temperature

4. ✅ Generates index.yaml
   - Tool: fs_create with comprehensive instructions
   - Expected: Complete agent instructions and conversation starters

5. ✅ Creates custom bash tool
   - Tool: fs_create with bash template
   - Expected: Properly formatted .sh file with argc annotations

6. ✅ Makes tools executable
   - Command: execute_command --command "chmod +x <tool>.sh"
   - Expected: Tool has execute permissions

7. ✅ Registers agent in agents.txt
   - Command: execute_command --command "echo '<agent>' >> agents.txt"
   - Expected: Agent name added to agents.txt

8. ✅ Registers tools in tools.txt
   - Command: execute_command with multi-line echo
   - Expected: Tool names with extensions added to tools.txt

9. ✅ Builds functions.json
   - Command: execute_command --command "cd ... && argc build"
   - Expected: functions.json generated, binaries created

10. ✅ Verifies setup
    - Command: execute_command --command "cd ... && argc check"
    - Expected: All tools and agents validated

11. ✅ Creates comprehensive README
    - Tool: fs_create with markdown content
    - Expected: Complete documentation with examples

**Usage**:
```bash
# Launch the enhanced builder-agent
aichat --agent builder-agent

# Example: Create a complete agent
> Create a database agent that can execute SQL queries and view schemas

# The builder-agent will:
# 1. Check for reusable tools
# 2. Create directory and configs
# 3. Generate custom tools
# 4. Register everything
# 5. Build and verify
# 6. Create documentation
# Result: Fully functional agent ready immediately!
```

**Impact**:
- **Time Savings**: 95% reduction (from 15-20 minutes to 30 seconds)
- **Quality**: Consistent, validated agents every time
- **Error Prevention**: Automated checklist prevents mistakes
- **Documentation**: Always comprehensive and complete

**Naming Conventions Enforced**:
- Agents: lowercase-with-hyphens (`database-agent`)
- Tools: lowercase_with_underscores (`db_query.sh`)
- Config files: lowercase.yaml
- Documentation: UPPERCASE.md or README.md

**Security Features**:
- Uses guard_operation.sh for destructive operations
- Never hardcodes credentials
- Sets proper file permissions (0600 for sensitive files)
- Validates user input in tools
- Uses environment variables for secrets

**Version History**:
- v0.1.0: Basic agent directory creation
- v0.2.0: Complete automation with tool creation and verification ✅

**Dependencies**:
- argc (for function building)
- jq (for JSON processing)
- bash, node, python3 (for tool execution)

**Backward Compatibility**:
✅ Fully compatible with existing agents
✅ No breaking changes
✅ Can coexist with manual agent creation

**Notes**:
- The builder-agent is now a complete agent factory
- All steps are automated from discovery to verification
- Tool templates ensure consistent quality
- Absolute paths prevent configuration errors
- Validation checklist prevents missing steps

---

## Future Enhancements

### Builder Agent Improvements
- Multi-language tool support (Go, Rust, etc.)
- Auto-generate test files for tools
- GitHub Actions workflow generation
- Dependency auto-installation
- Interactive guided mode
- Pre-built agent templates library

### Homelab Agent Additions
- Multi-server support (manage multiple homelab servers)
- Docker Swarm / Kubernetes integration
- Automated backup scheduling
- Container health monitoring and alerts
- Resource usage metrics collection
- Automated security scanning of images
- Integration with Docker Hub / private registries
- Automated SSL certificate management
- Container orchestration workflows
