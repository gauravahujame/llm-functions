/**
 * A simple web search stub for demonstration. Returns canned search results.
 * This is a safe fallback that avoids calling external APIs.
 * @typedef {Object} Args
 * @property {string} query - Search query
 * @returns {Object}
 */
exports.run = function (args) {
  const q = args && args.query;
  if (!q) return { error: 'missing required parameter `query`' };
  // Return a small, structured mock response. Agents can parse this.
  return {
    query: q,
    provider: 'stub',
    results: [
      { title: `Top result for ${q}`, url: 'https://example.com/', snippet: `This is a stubbed result for query: ${q}` },
      { title: `Another result for ${q}`, url: 'https://example.org/', snippet: `More stub data about ${q}` }
    ]
  };
}
