#!/usr/bin/env node
/**
 * Live SEO audit for the deployed site, adapted from the AdMob CMP docs site.
 * Run after DNS and the custom domain are live: `npm run audit:live-seo`.
 * Set PAGES_PREVIEW_HOST to the project's `<project>.pages.dev` host to also
 * check the preview-host redirect (e.g. PAGES_PREVIEW_HOST=compose-skill.pages.dev).
 */
import { pathToFileURL } from 'node:url';

const SITE = 'https://compose.avinya.dev';
const PREVIEW = process.env.PAGES_PREVIEW_HOST ? `https://${process.env.PAGES_PREVIEW_HOST}` : undefined;

async function get(fetchImpl, url, redirect = 'follow') {
  return fetchImpl(url, { redirect, headers: { 'user-agent': 'Compose-Kit-SEO-Audit/1.0' } });
}

function hasCanonical(html, url) {
  const escaped = url.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
  return new RegExp(`<link\\s+rel=["']canonical["']\\s+href=["']${escaped}["']\\s*/?>`, 'i').test(html);
}

export async function auditProductionSeo(fetchImpl = fetch) {
  const failures = [];
  const check = (condition, message) => {
    if (!condition) failures.push(message);
  };

  const [httpHome, robotsResponse, sitemapResponse, sitemapPagesResponse, homeResponse, claudeResponse, ogResponse] =
    await Promise.all([
      get(fetchImpl, 'http://compose.avinya.dev/', 'manual'),
      get(fetchImpl, `${SITE}/robots.txt`),
      get(fetchImpl, `${SITE}/sitemap-index.xml`),
      get(fetchImpl, `${SITE}/sitemap-0.xml`),
      get(fetchImpl, `${SITE}/`),
      get(fetchImpl, `${SITE}/install/claude-code/`),
      get(fetchImpl, `${SITE}/og/index.png`),
    ]);

  check([301, 308].includes(httpHome.status), 'HTTP homepage does not permanently redirect');
  check(httpHome.headers.get('location') === `${SITE}/`, 'HTTP homepage redirect does not target the canonical HTTPS URL');

  if (PREVIEW) {
    const previewHome = await get(fetchImpl, `${PREVIEW}/`, 'manual');
    check([301, 308].includes(previewHome.status), 'pages.dev production host does not permanently redirect');
    check(previewHome.headers.get('location') === `${SITE}/`, 'pages.dev redirect does not target the canonical host');
  }

  const robots = await robotsResponse.text();
  check(robotsResponse.ok, 'robots.txt did not return 200');
  check(!/Cloudflare Managed|BEGIN managed content/i.test(robots), 'robots.txt contains Cloudflare managed content');
  check(/User-agent: \*\nAllow: \//i.test(robots), 'robots.txt does not allow all crawlers');
  check(robots.includes(`Sitemap: ${SITE}/sitemap-index.xml`), 'robots.txt does not advertise the canonical sitemap');

  const sitemapIndex = await sitemapResponse.text();
  check(sitemapResponse.ok, 'sitemap index did not return 200');
  check(sitemapIndex.includes(`${SITE}/sitemap-0.xml`), 'sitemap index does not reference the canonical sitemap');
  const sitemapPages = await sitemapPagesResponse.text();
  check(sitemapPagesResponse.ok, 'page sitemap did not return 200');
  check(sitemapPages.includes(`${SITE}/install/claude-code/`), 'sitemap does not include the Claude Code install page');

  const home = await homeResponse.text();
  check(homeResponse.ok, 'canonical homepage did not return 200');
  check(/<title>[^<]*Compose Skill[^<]*<\/title>/i.test(home), 'homepage title is missing "Compose Skill"');
  check(hasCanonical(home, `${SITE}/`), 'homepage canonical link is missing or incorrect');

  const claude = await claudeResponse.text();
  check(claudeResponse.ok, 'Claude Code install page did not return 200');
  check(hasCanonical(claude, `${SITE}/install/claude-code/`), 'Claude Code install page canonical is missing or incorrect');

  check(ogResponse.ok, 'home OG image did not return 200');
  check(ogResponse.headers.get('content-type')?.includes('image/png'), 'home OG image is not served as image/png');

  return failures;
}

async function main() {
  const failures = await auditProductionSeo();
  if (failures.length > 0) {
    for (const failure of failures) console.error(`FAIL ${failure}`);
    console.error(`\nLIVE SEO AUDIT: FAIL (${failures.length} checks)`);
    process.exitCode = 1;
    return;
  }
  console.log('LIVE SEO AUDIT: PASS');
}

if (process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href) {
  await main();
}
