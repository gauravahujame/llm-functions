/**
 * Read a UTF-8 text file and return its contents.
 * @typedef {Object} Args
 * @property {string} path - Path to the file to read
 * @returns {string}
 */
exports.run = function (args) {
  const fs = require('fs');
  const p = args && args.path;
  if (!p) return 'ERROR: missing required parameter `path`';
  try {
    return fs.readFileSync(p, 'utf8');
  } catch (e) {
    return `ERROR: ${e.message}`;
  }
}
