#!/usr/bin/env node

/**
 * Perform web research using SearXNG
 * @typedef {Object} Args
 * @property {string} query - User's research query
 * @property {string} [searxng_url="http://localhost:8080"] - SearXNG instance URL
 * @property {number} [num_results=3] - Number of search results to extract (1-10)
 * @property {string[]} [engines] - Specific search engines to use
 * @property {string} [language="en"] - Search language
 * @property {boolean} [safe_search=false] - Enable safe search
 * @property {number} [timeout=10000] - Request timeout in milliseconds
 * @param {Args} args
 */
exports.run = async function (args) {
const https = require('https');
const http = require('http');
const { URL } = require('url');
  const {
    query,
    searxng_url = process.env.SEARXNG_URL || 'http://localhost:8080',
    num_results = 3,
    engines,
    language = 'en',
    safe_search = false,
    timeout = 10000
  } = args;

  if (!query) {
    return JSON.stringify({ error: 'query parameter is required' });
  }

  const actualResults = Math.min(Math.max(1, num_results), 10);

  try {
    const keywords = generateKeywords(query);

    const searchResults = await searchSearXNG({
      url: searxng_url, query: keywords.join(' '), engines, language, safe_search, timeout
    });

    const topResults = searchResults.slice(0, actualResults);
    const extractedContent = await Promise.all(
      topResults.map(result => extractMarkdown(result, timeout))
    );

    const finalResult = {
      query, keywords, total_results_found: searchResults.length,
      extracted_count: extractedContent.length,
      results: extractedContent.map((content, idx) => ({
        rank: idx + 1, title: topResults[idx].title, url: topResults[idx].url,
        engine: topResults[idx].engine, snippet: topResults[idx].content || '',
        extracted_content: content.markdown, word_count: content.word_count,
        extraction_status: content.status
      }))
    };

    return JSON.stringify(finalResult);

  } catch (error) {
    return JSON.stringify({ error: error.message, query });
  }
};

/**
 * Generate search keywords from query
 */
function generateKeywords(query) {
  // Simple keyword extraction (in production, you'd use NLP)
  const stopWords = new Set(['a', 'an', 'the', 'is', 'are', 'was', 'were', 'be', 'been', 'being', 'have', 'has', 'had', 'do', 'does', 'did', 'will', 'would', 'should', 'could', 'may', 'might', 'can', 'to', 'of', 'in', 'on', 'at', 'by', 'for', 'with', 'from', 'as', 'into', 'what', 'how', 'why', 'when', 'where']);

  const words = query.toLowerCase()
    .replace(/[^\w\s]/g, ' ')
    .split(/\s+/)
    .filter(w => w.length > 2 && !stopWords.has(w));

  // Return unique keywords
  return [...new Set(words)].slice(0, 5);
}

/**
 * Search using SearXNG API
 */
function searchSearXNG(config) {
  return new Promise((resolve, reject) => {
    const { url, query, engines, language, safe_search, timeout } = config;

    const parsedUrl = new URL(url);
    const params = new URLSearchParams({
      q: query,
      format: 'json',
      language: language
    });

    if (engines && engines.length > 0) {
      params.append('engines', engines.join(','));
    }

    if (safe_search) {
      params.append('safesearch', '1');
    }

    const searchPath = `${parsedUrl.pathname}/search?${params.toString()}`;

    const options = {
      hostname: parsedUrl.hostname,
      port: parsedUrl.port || (parsedUrl.protocol === 'https:' ? 443 : 80),
      path: searchPath,
      method: 'GET',
      headers: {
        'User-Agent': 'aichat-research-tool',
        'Accept': 'application/json'
      }
    };

    const client = parsedUrl.protocol === 'https:' ? https : http;

    const req = client.request(options, (res) => {
      let data = '';

      res.on('data', (chunk) => {
        data += chunk;
      });

      res.on('end', () => {
        if (res.statusCode === 200) {
          try {
            const parsed = JSON.parse(data);
            resolve(parsed.results || []);
          } catch (e) {
            reject(new Error('Failed to parse SearXNG response'));
          }
        } else {
          reject(new Error(`SearXNG error: ${res.statusCode}`));
        }
      });
    });

    req.setTimeout(timeout, () => {
      req.destroy();
      reject(new Error('SearXNG request timeout'));
    });

    req.on('error', (e) => {
      reject(new Error(`SearXNG request failed: ${e.message}`));
    });

    req.end();
  });
}

/**
 * Extract markdown content from URL
 */
async function extractMarkdown(result, timeout) {
  try {
    const html = await fetchUrl(result.url, timeout);
    const markdown = htmlToMarkdown(html);

    return {
      markdown,
      word_count: markdown.split(/\s+/).length,
      status: 'success'
    };
  } catch (error) {
    return {
      markdown: result.content || result.title,
      word_count: 0,
      status: `failed: ${error.message}`
    };
  }
}

/**
 * Fetch URL content
 */
function fetchUrl(url, timeout) {
  return new Promise((resolve, reject) => {
    const parsedUrl = new URL(url);
    const client = parsedUrl.protocol === 'https:' ? https : http;

    const options = {
      hostname: parsedUrl.hostname,
      port: parsedUrl.port,
      path: parsedUrl.pathname + parsedUrl.search,
      method: 'GET',
      headers: {
        'User-Agent': 'Mozilla/5.0 (compatible; aichat-research/1.0)',
        'Accept': 'text/html,application/xhtml+xml'
      }
    };

    const req = client.request(options, (res) => {
      // Follow redirects
      if (res.statusCode >= 300 && res.statusCode < 400 && res.headers.location) {
        return fetchUrl(res.headers.location, timeout).then(resolve).catch(reject);
      }

      if (res.statusCode !== 200) {
        reject(new Error(`HTTP ${res.statusCode}`));
        return;
      }

      let data = '';
      res.setEncoding('utf8');

      res.on('data', (chunk) => {
        data += chunk;
        // Limit size to prevent memory issues
        if (data.length > 500000) {
          req.destroy();
          reject(new Error('Content too large'));
        }
      });

      res.on('end', () => {
        resolve(data);
      });
    });

    req.setTimeout(timeout, () => {
      req.destroy();
      reject(new Error('Request timeout'));
    });

    req.on('error', (e) => {
      reject(new Error(`Fetch failed: ${e.message}`));
    });

    req.end();
  });
}

/**
 * Convert HTML to Markdown (simplified)
 */
function htmlToMarkdown(html) {
  // Remove scripts, styles, nav, footer
  let text = html
    .replace(/<script[^>]*>[\s\S]*?<\/script>/gi, '')
    .replace(/<style[^>]*>[\s\S]*?<\/style>/gi, '')
    .replace(/<nav[^>]*>[\s\S]*?<\/nav>/gi, '')
    .replace(/<footer[^>]*>[\s\S]*?<\/footer>/gi, '')
    .replace(/<header[^>]*>[\s\S]*?<\/header>/gi, '');

  // Convert common elements
  text = text
    .replace(/<h1[^>]*>(.*?)<\/h1>/gi, '\n# $1\n')
    .replace(/<h2[^>]*>(.*?)<\/h2>/gi, '\n## $1\n')
    .replace(/<h3[^>]*>(.*?)<\/h3>/gi, '\n### $1\n')
    .replace(/<h4[^>]*>(.*?)<\/h4>/gi, '\n#### $1\n')
    .replace(/<p[^>]*>(.*?)<\/p>/gi, '\n$1\n')
    .replace(/<br\s*\/?>/gi, '\n')
    .replace(/<li[^>]*>(.*?)<\/li>/gi, '- $1\n')
    .replace(/<code[^>]*>(.*?)<\/code>/gi, '`$1`')
    .replace(/<pre[^>]*>(.*?)<\/pre>/gi, '\n``````\n')
    .replace(/<a[^>]*href=["']([^"']*)["'][^>]*>(.*?)<\/a>/gi, '[$2]($1)')
    .replace(/<strong[^>]*>(.*?)<\/strong>/gi, '**$1**')
    .replace(/<b[^>]*>(.*?)<\/b>/gi, '**$1**')
    .replace(/<em[^>]*>(.*?)<\/em>/gi, '*$1*')
    .replace(/<i[^>]*>(.*?)<\/i>/gi, '*$1*');

  // Remove remaining HTML tags
  text = text.replace(/<[^>]+>/g, '');

  // Decode HTML entities
  text = text
    .replace(/&amp;/g, '&')
    .replace(/&lt;/g, '<')
    .replace(/&gt;/g, '>')
    .replace(/&quot;/g, '"')
    .replace(/&#39;/g, "'")
    .replace(/&nbsp;/g, ' ');

  // Clean up whitespace
  text = text
    .replace(/\n{3,}/g, '\n\n')
    .replace(/^\s+|\s+$/g, '')
    .replace(/[ \t]+/g, ' ');

  return text;
}
