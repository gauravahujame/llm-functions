#!/usr/bin/env node

/**
 * Search GitHub code or files
 * @typedef {Object} Args
 * @property {string} query - Search query (code content or filename)
 * @property {"code"|"file"} [type="code"] - Search type: code content or filename
 * @property {string} [language] - Filter by programming language (e.g., "javascript", "python")
 * @property {string} [repo] - Limit to specific repo (format: owner/repo)
 * @property {number} [limit=10] - Maximum results to return (1-30)
 * @property {boolean} [include_content=false] - Include file content preview
 * @param {Args} args
 */
exports.run = async function (args) {
const https = require('https');
  const { query, type = 'code', language, repo, limit = 10, include_content = false } = args;

  if (!query) {
    return JSON.stringify({ error: 'query parameter is required' });
  }

  const actualLimit = Math.min(Math.max(1, limit), 30);

  try {
    let searchQuery = query;
    if (language) searchQuery += ` language:${language}`;
    if (repo) searchQuery += ` repo:${repo}`;

    const endpoint = type === 'file'
      ? `/search/code?q=filename:${encodeURIComponent(searchQuery)}`
      : `/search/code?q=${encodeURIComponent(searchQuery)}`;

    const results = await githubApiRequest(`${endpoint}&per_page=${actualLimit}`);

    if (!results.items || results.items.length === 0) {
      return JSON.stringify({ query, type, total: 0, results: [], message: 'No results found' });
    }

    const formattedResults = await Promise.all(
      results.items.slice(0, actualLimit).map(async (item) => {
        const result = {
          file: item.name, path: item.path, repo: item.repository.full_name,
          repo_url: item.repository.html_url, file_url: item.html_url,
          size: item.size, language: item.language || 'unknown',
          score: Math.round(item.score * 100) / 100
        };

        if (include_content && item.url) {
          try {
            const content = await githubApiRequest(item.url.replace('https://api.github.com', ''));
            const decoded = Buffer.from(content.content, 'base64').toString('utf-8');
            result.preview = decoded.split('\n').slice(0, 10).join('\n');
            result.lines_total = decoded.split('\n').length;
          } catch (err) {
            result.preview_error = 'Failed to fetch content';
          }
        }
        return result;
      })
    );

    return JSON.stringify({ query, type, total: results.total_count, returned: formattedResults.length, results: formattedResults });

  } catch (error) {
    return JSON.stringify({ error: error.message, query, type });
  }
};

function githubApiRequest(path) {
  return new Promise((resolve, reject) => {
    const token = process.env.GITHUB_TOKEN || process.env.GH_TOKEN;

    const options = {
      hostname: 'api.github.com', path, method: 'GET',
      headers: { 'User-Agent': 'aichat-github-search', 'Accept': 'application/vnd.github.v3+json' }
    };

    if (token) options.headers['Authorization'] = `token ${token}`;

    const req = https.request(options, (res) => {
      let data = '';
      res.on('data', (chunk) => { data += chunk; });
      res.on('end', () => {
        if (res.statusCode === 200) {
          try { resolve(JSON.parse(data)); }
          catch (e) { reject(new Error('Failed to parse GitHub response')); }
        } else if (res.statusCode === 403) {
          reject(new Error('GitHub API rate limit exceeded. Set GITHUB_TOKEN env var.'));
        } else {
          reject(new Error(`GitHub API error: ${res.statusCode} - ${data}`));
        }
      });
    });

    req.on('error', (e) => { reject(new Error(`GitHub API request failed: ${e.message}`)); });
    req.end();
  });
}
