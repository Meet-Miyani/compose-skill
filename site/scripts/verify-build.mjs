#!/usr/bin/env node
/**
 * Asserts that `dist/` carries every SEO artefact the site promises.
 * Run by `npm run verify` after `npm run build`. Adapted from the AdMob CMP
 * docs site: the Dokka /api/ checks and the content-signal robots policy are
 * gone; per-page title/description uniqueness and the leak checks are new.
 */
import { readFile, readdir, stat } from 'node:fs/promises';
import { existsSync } from 'node:fs';
import path from 'node:path';

const DIST = path.resolve('dist');
const SITE = 'https://compose.avinya.dev';
const REPO = 'https://github.com/Meet-Miyani/compose-skill';
const EXPECTED_PAGES = [
  '',
  'install/',
  'install/claude-code/',
  'install/codex/',
  'install/cursor/',
  'install/github-copilot/',
  'install/gemini-cli-and-antigravity/',
  'install/opencode/',
  'skills/',
  'results/',
  'how-we-test/',
  'roadmap/',
];
const failures = [];

function check(condition, message) {
  if (condition) {
    console.log(`  ok   ${message}`);
  } else {
    console.error(`  FAIL ${message}`);
    failures.push(message);
  }
}

async function listHtmlPages(dir) {
  const out = [];
  for (const entry of await readdir(dir, { withFileTypes: true })) {
    const full = path.join(dir, entry.name);
    if (entry.isDirectory()) {
      if (entry.name === 'pagefind' || entry.name === '_astro' || entry.name === 'og') continue;
      out.push(...(await listHtmlPages(full)));
    } else if (entry.name === 'index.html') {
      out.push(full);
    }
  }
  return out;
}

const decode = (s) =>
  s.replace(/&amp;/g, '&').replace(/&quot;/g, '"').replace(/&#39;/g, "'").replace(/&lt;/g, '<').replace(/&gt;/g, '>');

console.log('sitemap');
const sitemapIndex = await readFile(path.join(DIST, 'sitemap-index.xml'), 'utf8');
check(sitemapIndex.includes(`${SITE}/sitemap-0.xml`), 'sitemap-index references sitemap-0.xml on the canonical host');
const sitemap = await readFile(path.join(DIST, 'sitemap-0.xml'), 'utf8');
const locs = [...sitemap.matchAll(/<loc>([^<]+)<\/loc>/g)].map((m) => m[1]);
check(locs.length === EXPECTED_PAGES.length, `sitemap lists ${locs.length} URLs (expected ${EXPECTED_PAGES.length})`);
for (const page of EXPECTED_PAGES) check(locs.includes(`${SITE}/${page}`), `sitemap includes ${SITE}/${page}`);
check(locs.every((l) => l.startsWith(`${SITE}/`)), `every sitemap URL is on ${SITE}`);
check(!sitemap.includes('pages.dev'), 'sitemap contains no *.pages.dev URL');
check(!locs.some((l) => l.includes('/og/')), 'sitemap excludes the /og/ image endpoints');

console.log('robots.txt');
const robots = await readFile(path.join(DIST, 'robots.txt'), 'utf8');
check(/^User-agent: \*\nAllow: \/$/m.test(robots), 'robots.txt allows every crawler');
check(!/^Disallow:/m.test(robots), 'robots.txt disallows nothing');
check(robots.includes(`Sitemap: ${SITE}/sitemap-index.xml`), 'robots.txt points at the sitemap index');

console.log('llms.txt');
for (const file of ['llms.txt', 'llms-full.txt', 'llms-small.txt']) {
  const full = path.join(DIST, file);
  check(existsSync(full), `${file} exists`);
  if (existsSync(full)) {
    const { size } = await stat(full);
    check(size > 500, `${file} is ${size} bytes (expected > 500)`);
  }
}
const llms = await readFile(path.join(DIST, 'llms.txt'), 'utf8');
check(llms.includes(REPO), 'llms.txt links the repository');
check(llms.includes('v6.1.0'), 'llms.txt states the current release');

console.log('per-page SEO');
const pages = await listHtmlPages(DIST);
check(pages.length === EXPECTED_PAGES.length, `${pages.length} HTML pages built (expected ${EXPECTED_PAGES.length})`);
const titles = new Map();
const descriptions = new Map();
for (const page of pages) {
  const rel = path.relative(DIST, page).replace(/index\.html$/, '').split(path.sep).join('/');
  const label = rel || '/';
  const html = await readFile(page, 'utf8');

  const title = html.match(/<title>([^<]*)<\/title>/)?.[1];
  check(Boolean(title), `${label} has a <title>`);
  if (title) titles.set(title, [...(titles.get(title) ?? []), label]);

  const description = html.match(/<meta name="description" content="([^"]*)"/)?.[1];
  check(Boolean(description) && decode(description).length <= 160, `${label} has a meta description of at most 160 chars`);
  if (description) descriptions.set(description, [...(descriptions.get(description) ?? []), label]);

  const canonicals = [...html.matchAll(/<link rel="canonical" href="([^"]+)"/g)].map((m) => m[1]);
  check(canonicals.length === 1, `${label} has exactly one canonical link`);
  check(canonicals[0] === `${SITE}/${rel}`, `${label} canonical is ${SITE}/${rel} (got ${canonicals[0]})`);

  const ogImage = html.match(/<meta property="og:image" content="([^"]+)"/)?.[1];
  check(Boolean(ogImage?.startsWith(`${SITE}/og/`)), `${label} has an absolute og:image on ${SITE}`);
  if (ogImage) {
    const imgPath = path.join(DIST, new URL(ogImage).pathname);
    check(existsSync(imgPath), `${label} og:image file exists at ${path.relative(DIST, imgPath)}`);
  }
  check(/<meta name="twitter:image" content="https:\/\/compose\.avinya\.dev\/og\//.test(html), `${label} has twitter:image`);
  check(html.includes('<meta property="og:title"'), `${label} has og:title`);
  check(html.includes('<meta property="og:description"'), `${label} has og:description`);

  check(html.includes('"@type":"BreadcrumbList"'), `${label} emits BreadcrumbList JSON-LD`);
  const wantsSoftware = rel === '';
  check(
    html.includes('"@type":"SoftwareSourceCode"') === wantsSoftware,
    `${label} ${wantsSoftware ? 'emits' : 'does not emit'} SoftwareSourceCode JSON-LD`
  );
  check(
    html.includes('"@type":"TechArticle"') === !wantsSoftware,
    `${label} ${wantsSoftware ? 'does not emit' : 'emits'} TechArticle JSON-LD`
  );
  for (const script of [...html.matchAll(/<script type="application\/ld\+json"[^>]*>([\s\S]*?)<\/script>/g)]) {
    let parsed = false;
    try {
      JSON.parse(script[1]);
      parsed = true;
    } catch {
      parsed = false;
    }
    check(parsed, `${label} JSON-LD block parses as JSON`);
  }
  check(!html.includes('class="language-mermaid"'), `${label} has no unrendered mermaid fence`);
  check(!/AdMob|admob/.test(html), `${label} carries nothing from the AdMob CMP site`);
}

for (const [title, where] of titles) check(where.length === 1, `title is unique: "${decode(title)}" (${where.join(', ')})`);
for (const [d, where] of descriptions) check(where.length === 1, `description is unique (${where.join(', ')}): "${decode(d).slice(0, 50)}…"`);

const home = await readFile(path.join(DIST, 'index.html'), 'utf8');
check(/<h1[^>]*>Compose Skill<\/h1>/.test(home), 'home page H1 is "Compose Skill"');
check(home.includes(`"codeRepository":"${REPO}"`), 'SoftwareSourceCode names the repository');
check(home.includes('"programmingLanguage":"Kotlin"'), 'SoftwareSourceCode programmingLanguage is Kotlin');
check(home.includes('"license":"https://opensource.org/license/mit"'), 'SoftwareSourceCode license is MIT');
check(home.includes(`href="${REPO}"`), 'home page links the GitHub repository');
check(home.includes('Star on GitHub'), 'home page has a "Star on GitHub" link');

console.log('leaks');
async function walk(dir) {
  const out = [];
  for (const entry of await readdir(dir, { withFileTypes: true })) {
    const full = path.join(dir, entry.name);
    if (entry.isDirectory()) out.push(...(await walk(full)));
    else if (/\.(html|txt|xml|svg|css|js|json)$/.test(entry.name)) out.push(full);
  }
  return out;
}
// Built from parts so this file does not itself match the pattern it checks.
const leakPattern = new RegExp(['/Us' + 'ers/', '/pri' + 'vate/', 'hand' + 'off'].join('|'));
const leaks = [];
for (const file of await walk(DIST)) {
  if (leakPattern.test(await readFile(file, 'utf8'))) leaks.push(path.relative(DIST, file));
}
check(leaks.length === 0, `no local paths or private-record references in dist/ (${leaks.join(', ') || 'none'})`);

console.log('search');
check(existsSync(path.join(DIST, 'pagefind', 'pagefind.js')), 'Pagefind index was generated');

if (failures.length > 0) {
  console.error(`\n${failures.length} check(s) failed.`);
  process.exit(1);
}
console.log('\nAll checks passed.');
