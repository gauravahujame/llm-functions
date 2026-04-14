#!/usr/bin/env node

/**
 * Docker container operations - list, inspect, create, start, stop, restart, logs
 * @typedef {Object} Args
 * @property {"list"|"inspect"|"create"|"start"|"stop"|"restart"|"logs"} action - Action to perform
 * @property {string|string[]} [containers] - Container name(s) or ID(s) for targeted actions
 * @property {boolean} [all=false] - Include stopped containers in list
 * @property {string} [format="json"] - Output format: json, table, or compact
 * @property {number} [log_lines=50] - Number of log lines to return (for logs action)
 * @property {string} [create_config] - Configuration for creating containers (JSON string)
 * @param {Args} args
 */
exports.run = async function (args) {
const { exec } = require('child_process');
const { promisify } = require('util');
const execAsync = promisify(exec);
  const {
    action,
    containers,
    all = false,
    format = 'json',
    log_lines = 50,
    create_config
  } = args;

  if (!action) {
    return JSON.stringify({ error: 'action parameter is required' });
  }

  try {
    let result;

    switch (action) {
      case 'list':
        result = await listContainers(all, format);
        break;
      case 'inspect':
        result = await inspectContainers(containers);
        break;
      case 'create':
        result = await createContainer(create_config);
        break;
      case 'start':
        result = await controlContainers('start', containers);
        break;
      case 'stop':
        result = await controlContainers('stop', containers);
        break;
      case 'restart':
        result = await controlContainers('restart', containers);
        break;
      case 'logs':
        result = await getContainerLogs(containers, log_lines);
        break;
      default:
        throw new Error(`Unknown action: ${action}`);
    }

    return typeof result === 'string' ? result : JSON.stringify(result, null, 2);

  } catch (error) {
    return JSON.stringify({ error: error.message, action, containers });
  }
};

async function listContainers(all, format) {
  const cmd = all ? 'docker ps -a --format json' : 'docker ps --format json';
  const { stdout } = await execAsync(cmd);

  const containers = stdout.trim().split('\n')
    .filter(line => line)
    .map(line => JSON.parse(line));

  if (format === 'compact') {
    return {
      total: containers.length,
      containers: containers.map(c => ({
        id: c.ID.substring(0, 12),
        name: c.Names,
        image: c.Image,
        status: c.State,
        ports: c.Ports || 'none'
      }))
    };
  }

  if (format === 'table') {
    const table = containers.map(c =>
      `${c.ID.substring(0, 12)} | ${c.Names.padEnd(20)} | ${c.Image.padEnd(30)} | ${c.State.padEnd(10)} | ${c.Ports || 'none'}`
    ).join('\n');

    return {
      total: containers.length,
      table: `ID           | Name                 | Image                          | Status     | Ports\n${'-'.repeat(100)}\n${table}`
    };
  }

  return { total: containers.length, containers };
}

async function inspectContainers(containers) {
  if (!containers || (Array.isArray(containers) && containers.length === 0)) {
    throw new Error('containers parameter required for inspect action');
  }

  const containerList = Array.isArray(containers) ? containers : [containers];
  const results = [];

  for (const container of containerList) {
    try {
      const { stdout } = await execAsync(`docker inspect ${container}`);
      const data = JSON.parse(stdout)[0];

      results.push({
        id: data.Id.substring(0, 12),
        name: data.Name.replace(/^\//, ''),
        image: data.Config.Image,
        state: data.State.Status,
        running: data.State.Running,
        started_at: data.State.StartedAt,
        finished_at: data.State.FinishedAt,
        exit_code: data.State.ExitCode,
        ports: data.NetworkSettings.Ports,
        networks: Object.keys(data.NetworkSettings.Networks),
        mounts: data.Mounts.map(m => ({ type: m.Type, source: m.Source, destination: m.Destination })),
        env: data.Config.Env,
        cmd: data.Config.Cmd,
        entrypoint: data.Config.Entrypoint,
        restart_policy: data.HostConfig.RestartPolicy
      });
    } catch (error) {
      results.push({ container, error: error.message });
    }
  }

  return { inspected: results.length, results };
}

async function controlContainers(action, containers) {
  if (!containers || (Array.isArray(containers) && containers.length === 0)) {
    throw new Error(`containers parameter required for ${action} action`);
  }

  const containerList = Array.isArray(containers) ? containers : [containers];
  const results = [];

  for (const container of containerList) {
    try {
      await execAsync(`docker ${action} ${container}`);
      results.push({ container, action, success: true });
    } catch (error) {
      results.push({ container, action, success: false, error: error.message });
    }
  }

  return {
    action,
    total: results.length,
    successful: results.filter(r => r.success).length,
    failed: results.filter(r => !r.success).length,
    results
  };
}

async function createContainer(config) {
  if (!config) {
    throw new Error('create_config parameter required for create action');
  }

  const { name, image, ports = [], volumes = [], env = [], network, restart = 'unless-stopped', command } = config;

  if (!name || !image) {
    throw new Error('name and image are required in create_config');
  }

  let cmd = `docker create --name ${name}`;
  if (restart) cmd += ` --restart ${restart}`;
  if (network) cmd += ` --network ${network}`;
  ports.forEach(p => cmd += ` -p ${p}`);
  volumes.forEach(v => cmd += ` -v ${v}`);
  env.forEach(e => cmd += ` -e ${e}`);
  cmd += ` ${image}`;
  if (command) cmd += ` ${command}`;

  try {
    const { stdout } = await execAsync(cmd);
    return { success: true, container_id: stdout.trim().substring(0, 12), name, image, command: cmd };
  } catch (error) {
    throw new Error(`Failed to create container: ${error.message}`);
  }
}

async function getContainerLogs(containers, lines) {
  if (!containers) {
    throw new Error('containers parameter required for logs action');
  }

  const container = Array.isArray(containers) ? containers[0] : containers;

  try {
    const { stdout } = await execAsync(`docker logs --tail ${lines} ${container}`);
    return { container, lines, logs: stdout };
  } catch (error) {
    throw new Error(`Failed to get logs: ${error.message}`);
  }
}
