#!/usr/bin/env node
/**
 * Pre-renders every src/diagrams/*.mmd to an inline-ready src/diagrams/*.svg
 * with rehype-mermaid (the same plugin and light-theme config the AdMob CMP
 * docs use at build time).
 *
 * Why not at build time: rehype-mermaid drives a headless Chromium, and the
 * Cloudflare Pages build image does not ship one. The SVGs are committed, so
 * `npm run build` needs no browser. Run `npm run diagrams` after editing a
 * .mmd file (needs `npx playwright install chromium` once).
 *
 * The light palette is baked in here; src/styles/mermaid.css re-tints the
 * same SVG for the dark theme. Keep these values in sync with tokens.css.
 */
import { readdir, readFile, writeFile } from 'node:fs/promises';
import path from 'node:path';
import { unified } from 'unified';
import rehypeParse from 'rehype-parse';
import rehypeStringify from 'rehype-stringify';
import rehypeMermaid from 'rehype-mermaid';

const DIR = new URL('../src/diagrams/', import.meta.url);

const processor = unified()
  .use(rehypeParse, { fragment: true })
  .use(rehypeMermaid, {
    strategy: 'inline-svg',
    css: new URL('diagram-fonts.css', DIR),
    mermaidConfig: {
      theme: 'base',
      fontFamily: 'Inter, -apple-system, BlinkMacSystemFont, Segoe UI, Helvetica Neue, Arial, sans-serif',
      themeVariables: {
        background: '#ffffff',
        primaryColor: '#ebecea',
        primaryTextColor: '#16181a',
        primaryBorderColor: '#d8dad6',
        secondaryColor: '#ffffff',
        tertiaryColor: '#ebecea',
        lineColor: '#5a5f63',
        textColor: '#16181a',
      },
    },
  })
  .use(rehypeStringify);

const escape = (s) => s.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');

for (const name of await readdir(DIR)) {
  if (!name.endsWith('.mmd')) continue;
  const source = await readFile(new URL(name, DIR), 'utf8');
  const html = `<pre><code class="language-mermaid">${escape(source)}</code></pre>`;
  // A label line break comes out as `<br></br>`; an HTML parser reads the
  // stray `</br>` as a second <br>, which adds a blank line that the label box
  // was not sized for. Write a single <br>.
  const out = String(await processor.process(html))
    .trim()
    .replace(/<br>\s*(?:<\/br>|<br>)/g, '<br>');
  if (!out.startsWith('<svg')) throw new Error(`${name}: rehype-mermaid did not return an SVG`);
  const target = name.replace(/\.mmd$/, '.svg');
  await writeFile(new URL(target, DIR), `${out}\n`);
  console.log(`rendered ${path.join('src/diagrams', target)} (${out.length} bytes)`);
}
