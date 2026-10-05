#!/usr/bin/env node
/**
 * site/scripts/audit-content.mjs
 *
 * Content rules, adapted from the AdMob CMP docs site:
 *   - every page has a frontmatter title and a description of at most 160 chars;
 *   - no editorial-instruction leakage;
 *   - every internal link resolves to a page and ends in a slash;
 *   - NEW: every number on the site appears in the repository's evidence
 *     (README.md and the evals-v2 files it cites). The site must not invent,
 *     round differently, or add numbers.
 *
 * Usage: node scripts/audit-content.mjs (from site/). Exits 1 on any problem.
 */
import { readFileSync, readdirSync, existsSync } from 'node:fs';
import { join, resolve } from 'node:path';
import { exit } from 'node:process';

const DOCS = 'src/content/docs';
const REPO_ROOT = resolve('..');
const problems = [];

function pages(dir = DOCS) {
  const out = [];
  for (const entry of readdirSync(dir, { withFileTypes: true })) {
    const path = join(dir, entry.name);
    if (entry.isDirectory()) out.push(...pages(path));
    else if (entry.name.endsWith('.mdx') || entry.name.endsWith('.md')) out.push(path);
  }
  return out;
}

const files = pages();
const urlOf = (f) => {
  const slug = f.slice(DOCS.length + 1).replace(/\.mdx?$/, '').replace(/(^|\/)index$/, '');
  return slug ? `/${slug}/` : '/';
};
const validUrls = new Set(files.map(urlOf));

const LEAKED_DIRECTIVES = /\bThis\s+section\s+must\b|\bOne\s+short\s+paragraph\b|\bShow\s+it:\b|\bTODO\b|\bTBD\b|lorem ipsum/i;

for (const file of files) {
  const raw = readFileSync(file, 'utf8');
  const fm = raw.match(/^---\r?\n([\s\S]*?)\r?\n---/);
  if (!fm) {
    problems.push(`${file}: no frontmatter`);
    continue;
  }
  const front = fm[1];
  if (!/^title:\s*(.+)$/m.test(front)) problems.push(`${file}: no title in frontmatter`);
  const desc = front.match(/^description:\s*'?(.+?)'?$/m);
  if (!desc) problems.push(`${file}: no description`);
  else if (desc[1].trim().length > 160) problems.push(`${file}: description is ${desc[1].trim().length} chars (max 160)`);
  if (LEAKED_DIRECTIVES.test(raw)) problems.push(`${file}: contains an editorial placeholder or instruction phrase`);
}

// Internal links in pages and in the landing components.
const linkSources = [...files, 'src/components/Hero.astro', 'src/components/Header.astro', 'src/data/site.ts'];
for (const file of linkSources) {
  const body = readFileSync(file, 'utf8');
  for (const m of body.matchAll(/href="(\/[^"#]*)(#[^"]*)?"|\]\((\/[^)#]*)(#[^)]*)?\)|href: '(\/[^'#]*)'/g)) {
    const url = m[1] ?? m[3] ?? m[5];
    if (url.startsWith('/llms') || url.startsWith('/og/') || url.startsWith('/charts/') || url.startsWith('/fonts/')) continue;
    if (!url.endsWith('/')) problems.push(`${file}: internal link missing trailing slash: ${url}`);
    else if (!validUrls.has(url)) problems.push(`${file}: internal link has no page: ${url}`);
  }
}

// Numbers: every number the site states must appear in the evidence.
const EVIDENCE = [
  'README.md',
  'evals-v2/results-v5/VERDICT.md',
  'evals-v2/results-v5/kit-tokens.txt',
  'evals-v2/results-v5/erratum-sensitivity.txt',
  'evals-v2/method/preregistration-v5.md',
  'evals-v2/heldout-v5/tasks.md',
  'evals-v2/results-v6/VERDICT.md',
  'evals-v2/results-v6/score-output.txt',
  'evals-v2/results-v6/kit-tokens.txt',
  'evals-v2/results-v6/ADDONS.md',
  'evals-v2/results-v6/score-output-addons.txt',
];
const missingEvidence = EVIDENCE.filter((f) => !existsSync(join(REPO_ROOT, f)));
if (missingEvidence.length) {
  problems.push(`evidence files not found next to site/: ${missingEvidence.join(', ')}`);
} else {
  const norm = (s) => s.replace(/−/g, '-');
  const corpus = norm(EVIDENCE.map((f) => readFileSync(join(REPO_ROOT, f), 'utf8')).join('\n'));
  const numberSources = [...files, 'src/components/Hero.astro', 'src/components/AgentWindow.astro', 'src/data/site.ts', 'astro.config.mjs'];
  const seen = new Set();
  for (const file of numberSources) {
    let text = readFileSync(file, 'utf8');
    // In the config, only the llms.txt text is content; the rest is styling.
    if (file === 'astro.config.mjs') text = text.slice(text.indexOf('starlightLlmsTxt({'), text.indexOf('sidebar: ['));
    // Drop code that is not content: imports, URLs, SVG path data, chart sizes, attrs.
    text = text
      .replace(/'M[\d\s.,a-zA-Z-]+'/g, '')
      .replace(/^import .*$/gm, '')
      .replace(/<script[\s\S]*?<\/script>/g, '')
      .replace(/<style[\s\S]*?<\/style>/g, '')
      .replace(/\bstyle=\{`[^`]*`\}/g, '')
      .replace(/https?:\/\/[^\s"')\]]+/g, '')
      .replace(/\b(width|height|size|stroke-width|viewBox|cx|cy|r|rx|x|y|d)=("[^"]*"|\{[^}]*\})/g, '')
      .replace(/<svg[\s\S]*?<\/svg>/g, '');
    for (const m of norm(text).matchAll(/[+-]?\d+(?:[.,]\d+)*(?:%|k)?/g)) {
      const token = m[0];
      const bare = token.replace(/^[+-]/, '');
      if (/^\d$/.test(bare)) continue; // single digits match anything
      const key = `${file}:${token}`;
      if (seen.has(key)) continue;
      seen.add(key);
      if (!corpus.includes(token) && !corpus.includes(bare)) problems.push(`${file}: number "${token}" is not in the evidence files`);
    }
  }
}

if (problems.length === 0) {
  console.log(`AUDIT OK: ${files.length} pages, links resolve, every number is in the evidence`);
  exit(0);
}
for (const p of problems) console.error(p);
console.error(`\n${problems.length} problem(s)`);
exit(1);
