/**
 * Build-time OpenGraph cards (1200×630 PNG), one per docs entry, at
 * /og/<entry id>.png (the path `ogImagePath()` in src/lib/seo.ts points at).
 *
 * The card follows the avinya.dev share-card layout (satori + resvg, as on the
 * studio site): flat paper, the wordmark top left with the section eyebrow on
 * the right, a large Space Grotesk title, the description, and the host with
 * the accent dot. OG images are static, so the palette is literal here; it
 * mirrors the light theme in src/styles/tokens.css.
 */
import type { APIRoute, GetStaticPaths } from 'astro';
import { getCollection } from 'astro:content';
import { readFile } from 'node:fs/promises';
import satori from 'satori';
import { Resvg } from '@resvg/resvg-js';
import { normalizeEntryId } from '../../lib/seo';

const C = { paper: '#F3F4F2', ink: '#16181A', slate: '#5A5F63', hair: '#D8DAD6', accent: '#EE3A20' };

/** Eyebrow per top-level path segment. Mirrors the sidebar groups. */
function eyebrowFor(id: string): string {
  if (id === 'index') return 'Agent skills';
  if (id.startsWith('install')) return 'Get started';
  if (id === 'skills') return 'Kit';
  if (id === 'results' || id === 'how-we-test') return 'Evidence';
  return 'Project';
}

const MARK = `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 64 64"><path d="M46.43 18.57 A19 19 0 1 0 46.43 45.43" fill="none" stroke="${C.ink}" stroke-width="9" stroke-linecap="round"/><circle cx="50" cy="32" r="6" fill="${C.accent}"/></svg>`;
const MARK_URI = `data:image/svg+xml;base64,${Buffer.from(MARK).toString('base64')}`;

export const getStaticPaths = (async () => {
  const entries = await getCollection('docs');
  return entries.map((entry) => {
    const id = normalizeEntryId(entry.id);
    const isHome = id === 'index';
    return {
      params: { route: `${id}.png` },
      props: {
        id,
        title: isHome ? (entry.data.hero?.title ?? entry.data.title) : entry.data.title,
        description: entry.data.description ?? '',
      },
    };
  });
}) satisfies GetStaticPaths;

let fonts: Promise<[Buffer, Buffer]> | undefined;
const loadFonts = () =>
  (fonts ??= Promise.all([
    readFile('src/og-fonts/SpaceGrotesk-SemiBold.ttf'),
    readFile('src/og-fonts/JetBrainsMono-Regular.ttf'),
  ]));

const div = (style: Record<string, unknown>, children: unknown) => ({ type: 'div', props: { style, children } });
// No children at all: satori counts an empty array as "more than one child".
const dot = (size: number) => ({
  type: 'div',
  props: { style: { display: 'flex', width: size, height: size, borderRadius: 999, backgroundColor: C.accent } },
});

export const GET: APIRoute = async ({ props }) => {
  const { id, title, description } = props as { id: string; title: string; description: string };
  const [grotesk, mono] = await loadFonts();
  const isHome = id === 'index';

  const tree = div(
    {
      width: '1200px',
      height: '630px',
      display: 'flex',
      flexDirection: 'column',
      justifyContent: 'space-between',
      padding: '80px 88px',
      backgroundColor: C.paper,
      color: C.ink,
      fontFamily: 'Space Grotesk',
    },
    [
      // Top row: the Compose Kit lockup and the section eyebrow.
      div({ display: 'flex', alignItems: 'center', justifyContent: 'space-between', width: '100%' }, [
        div({ display: 'flex', alignItems: 'center', gap: 14, fontSize: 34, letterSpacing: '-0.03em' }, [
          { type: 'img', props: { src: MARK_URI, width: 44, height: 44 } },
          { type: 'span', props: { children: 'Compose Kit' } },
        ]),
        div(
          {
            display: 'flex',
            fontFamily: 'JetBrains Mono',
            fontSize: 18,
            letterSpacing: '0.1em',
            textTransform: 'uppercase',
            color: C.slate,
          },
          eyebrowFor(id)
        ),
      ]),
      // Middle: the title, then the description.
      div({ display: 'flex', flexDirection: 'column', gap: 28 }, [
        div(
          {
            display: 'flex',
            fontSize: isHome ? 128 : title.length > 34 ? 68 : 80,
            lineHeight: 1,
            letterSpacing: '-0.04em',
            maxWidth: '1024px',
          },
          title
        ),
        div(
          { display: 'flex', fontSize: 30, lineHeight: 1.3, letterSpacing: '-0.015em', color: C.slate, maxWidth: '980px' },
          description
        ),
      ]),
      // Bottom row: the host, with the avinya.dev accent dot.
      div(
        {
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'space-between',
          width: '100%',
          paddingTop: 24,
          borderTop: `1px solid ${C.hair}`,
          fontFamily: 'JetBrains Mono',
          fontSize: 19,
          color: C.slate,
        },
        [
          div({ display: 'flex', alignItems: 'center', gap: 10 }, [dot(10), { type: 'span', props: { children: 'compose.avinya.dev' } }]),
          div({ display: 'flex' }, 'github.com/Meet-Miyani/compose-skill'),
        ]
      ),
    ]
  );

  const svg = await satori(tree as Parameters<typeof satori>[0], {
    width: 1200,
    height: 630,
    fonts: [
      { name: 'Space Grotesk', data: grotesk, weight: 600, style: 'normal' },
      { name: 'JetBrains Mono', data: mono, weight: 400, style: 'normal' },
    ],
  });
  const png = new Resvg(svg).render().asPng();
  return new Response(new Uint8Array(png), { headers: { 'content-type': 'image/png' } });
};
