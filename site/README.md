# compose.avinya.dev

The project site for Compose Skill (Compose Kit): Astro + Starlight, static output, hosted on Cloudflare Pages.
The stack is copied from the AdMob CMP docs site (ads.avinya.dev) and styled after the avinya.dev studio site.

Every number, claim and install command on the site comes from `../README.md` and the `../evals-v2/` files it cites.
`npm run verify` fails if a page states a number those files do not contain.

## Run locally

Needs Node 22.12 or newer.

```sh
cd site
npm install
npm run dev        # http://localhost:4321
npm run build      # static site in dist/
npm run preview    # serve dist/
npm run verify     # SEO checks on dist/ + content audit (run after build)
```

Other scripts:

- `npm run diagrams`: re-renders `src/diagrams/*.mmd` to the committed `*.svg` with rehype-mermaid. Needs a local
  Chromium once (`npx playwright install chromium`). The build itself needs no browser.
- `npm run audit:live-seo`: checks the deployed site (HTTP redirect, robots.txt, sitemap, canonicals, OG image). Set
  `PAGES_PREVIEW_HOST=<project>.pages.dev` to also check the preview-host redirect.

## Layout

- `src/content/docs/`: the pages (Markdown/MDX). The landing page body is `src/components/Hero.astro`.
- `src/data/site.ts`: shared facts (repo URL, version, headline numbers, agents, skills), copied from the README.
- `src/charts/`: the two v5 charts, byte-for-byte copies of `docs/assets/` (light and dark), inlined by
  `ThemedChart.astro`.
- `src/pages/og/[...route].ts`: build-time 1200×630 OG cards (satori + resvg), one per page.
- `src/components/AgentWindow.astro`: the hero's animated without-kit / with-kit agent window (inline vanilla JS).
  Its only numbers are the README's new-feature averages, 43.5% and 70.6%.
- `src/components/Motion.astro`: the site-wide motion script (scroll reveal, count-up, chart draw). Everything is off under
  `prefers-reduced-motion: reduce`.
- `functions/_middleware.js`: Cloudflare Pages host guard. `<project>.pages.dev` 301s to compose.avinya.dev;
  per-deployment preview hosts get `X-Robots-Tag: noindex, nofollow`.

## Cloudflare Pages settings

Workers & Pages → Create → Pages → Connect to Git → `Meet-Miyani/compose-skill`:

| Setting | Value |
|---|---|
| Framework preset | Astro |
| Production branch | `main` |
| Root directory | `site` |
| Build command | `npm run build` |
| Build output directory | `dist` |
| Node version | 22 (from `site/.node-version`; or set the `NODE_VERSION` env var to `22`) |

Optional environment variables (Settings → Environment variables, production). Both are inert when unset, so no
placeholder tags ship:

| Variable | What it does |
|---|---|
| `PUBLIC_GSC_VERIFICATION` | Adds `<meta name="google-site-verification">` for Google Search Console (HTML-tag method) |
| `PUBLIC_CF_BEACON_TOKEN` | Adds the Cloudflare Web Analytics beacon (no cookies) |

Then Custom domains → Set up a custom domain → `compose.avinya.dev`. With avinya.dev on Cloudflare DNS this adds the
CNAME to `<project>.pages.dev` and the certificate.

After the domain is live:

1. Search Console: add `https://compose.avinya.dev` (or verify the `avinya.dev` domain property, which covers it),
   then submit `https://compose.avinya.dev/sitemap-index.xml`.
2. Make sure Cloudflare's managed robots.txt is off for the zone, so it does not rewrite `public/robots.txt`.
3. Run `npm run audit:live-seo`.
