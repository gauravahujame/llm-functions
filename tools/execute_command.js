/**
 * Execute a shell command and return stdout (or stderr on error).
 * @typedef {Object} Args
 * @property {string} cmd - The shell command to execute
 * @property {number} [timeout] - Optional timeout in milliseconds
 * @returns {string}
 */
exports.run = function (args) {
  const { cmd, timeout } = args || {};
  if (!cmd) return 'ERROR: missing required parameter `cmd`';
  const { execSync } = require('child_process');
  try {
    const out = execSync(cmd, { encoding: 'utf8', timeout: timeout || 30_000 });
    return out;
  } catch (e) {
    // Provide useful debugging info but keep it safe
    const stderr = e.stderr ? e.stderr.toString() : '';
    return `ERROR: ${e.message}\n${stderr}`;
  }
}
