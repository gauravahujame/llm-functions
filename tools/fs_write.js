/**
 * Write text to a file. Overwrites by default; can append.
 * @typedef {Object} Args
 * @property {string} path - Path to write to
 * @property {string} content - Content to write
 * @property {boolean} [append] - If true, append instead of overwrite
 * @returns {string}
 */
exports.run = function (args) {
  const fs = require('fs');
  const p = args && args.path;
  const content = args && args.content;
  const append = args && args.append;
  if (!p) return 'ERROR: missing required parameter `path`';
  if (typeof content === 'undefined') return 'ERROR: missing required parameter `content`';
  try {
    if (append) {
      fs.appendFileSync(p, content, 'utf8');
    } else {
      fs.writeFileSync(p, content, 'utf8');
    }
    return 'OK';
  } catch (e) {
    return `ERROR: ${e.message}`;
  }
}
