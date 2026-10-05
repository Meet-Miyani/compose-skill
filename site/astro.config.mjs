// @ts-check
import { readFile } from 'node:fs/promises';
import { defineConfig } from 'astro/config';
import { unified } from '@astrojs/markdown-remark';
import starlight from '@astrojs/starlight';
import sitemap from '@astrojs/sitemap';
import starlightLlmsTxt from 'starlight-llms-txt';
import rehypeTableScroll from './src/lib/rehype-table-scroll.mjs';

/**
 * Canonical origin. `site` MUST be the custom domain, never the *.pages.dev
 * preview host. `functions/_middleware.js` is the second line of defence, and
 * the og-host guard below is the third.
 */
const SITE = 'https://compose.avinya.dev';
const SITE_HOST = new URL(SITE).host;
const REPO = 'https://github.com/Meet-Miyani/compose-skill';
const SITE_TITLE = 'Compose Kit';
const SITE_DESCRIPTION =
  'Compose Skill (Compose Kit): seven agent skills that make Claude Code, Codex, Cursor, Copilot and Gemini write better Jetpack Compose and Compose Multiplatform code.';

// Both inert until the corresponding Cloudflare Pages build env var is set —
// no placeholder tags ship to production without a real token.
const GSC_VERIFICATION_TOKEN = process.env.PUBLIC_GSC_VERIFICATION;
const CF_BEACON_TOKEN = process.env.PUBLIC_CF_BEACON_TOKEN;

/**
 * After the build, assert that the home page's og:image points at the
 * canonical host. A share card on a host that does not resolve is a silently
 * broken link preview, so fail the build instead (idea from avinya.dev).
 */
function ogHostGuard() {
  return {
    name: 'og-host-guard',
    hooks: {
      'astro:build:done': async ({ dir, logger }) => {
        const html = await readFile(new URL('./index.html', dir), 'utf8');
        const m = html.match(/<meta property="og:image" content="([^"]+)"/i);
        if (!m) throw new Error('og-host-guard: no og:image meta found in index.html');
        const ogHost = new URL(m[1]).host;
        if (ogHost !== SITE_HOST) {
          throw new Error(`og-host-guard: og:image host "${ogHost}" != site host "${SITE_HOST}".`);
        }
        logger.info(`og:image host OK (${ogHost})`);
      },
    },
  };
}

export default defineConfig({
  site: SITE,
  build: {
    format: 'directory',
    inlineStylesheets: 'always',
  },
  markdown: {
    // The one Mermaid diagram is pre-rendered to src/diagrams/*.svg by
    // `npm run diagrams` (rehype-mermaid + headless Chromium), so the
    // Cloudflare Pages build itself needs no browser.
    processor: unified({ rehypePlugins: [rehypeTableScroll] }),
  },
  integrations: [
    starlight({
      title: SITE_TITLE,
      description: SITE_DESCRIPTION,
      logo: { src: './src/assets/logo.svg', alt: 'Compose Kit' },
      favicon: '/favicon.svg',
      credits: false,
      pagefind: true,
      lastUpdated: true,
      tableOfContents: { minHeadingLevel: 2, maxHeadingLevel: 3 },
      social: [{ icon: 'github', label: 'GitHub', href: REPO }],
      // Starlight appends the entry path relative to the Astro project root,
      // which is `site/`, so the base URL has to include that segment.
      editLink: { baseUrl: `${REPO}/edit/main/site/` },
      customCss: ['./src/styles/tokens.css', './src/styles/mermaid.css'],
      components: {
        Head: './src/components/Head.astro',
        Header: './src/components/Header.astro',
        Hero: './src/components/Hero.astro',
        SiteTitle: './src/components/SiteTitle.astro',
        PageTitle: './src/components/PageTitle.astro',
        Footer: './src/components/Footer.astro',
        ThemeSelect: './src/components/ThemeSelect.astro',
      },
      expressiveCode: {
        // Code sits on the dark stage surface in both themes, so there is one
        // dark syntax theme and no light/dark switch.
        themes: ['github-dark'],
        minSyntaxHighlightingColorContrast: 5.5,
        useStarlightUiThemeColors: false,
        useStarlightDarkModeSwitch: false,
        styleOverrides: {
          borderRadius: 'var(--kit-radius-lg)',
          borderColor: 'var(--kit-stage-hair)',
          codeBackground: 'var(--kit-stage)',
          codeForeground: 'var(--kit-stage-ink)',
          codeFontFamily: 'var(--kit-font-mono)',
          codeFontSize: '0.875rem',
          codeLineHeight: '1.7',
          codePaddingBlock: '1.125rem',
          codePaddingInline: '1.25rem',
          uiFontFamily: 'var(--kit-font-body)',
          frames: {
            shadowColor: 'transparent',
            editorBackground: 'var(--kit-stage)',
            editorTabBarBackground: 'var(--kit-stage)',
            editorTabBarBorderColor: 'var(--kit-stage-hair)',
            editorTabBarBorderBottomColor: 'var(--kit-stage-hair)',
            editorActiveTabBackground: 'var(--kit-stage)',
            editorActiveTabForeground: 'var(--kit-stage-slate)',
            editorActiveTabBorderColor: 'transparent',
            editorActiveTabIndicatorTopColor: 'transparent',
            editorActiveTabIndicatorBottomColor: 'transparent',
            terminalBackground: 'var(--kit-stage)',
            terminalTitlebarBackground: 'var(--kit-stage)',
            terminalTitlebarBorderBottomColor: 'var(--kit-stage-hair)',
            terminalTitlebarForeground: 'var(--kit-stage-slate)',
            inlineButtonForeground: 'var(--kit-stage-ink)',
            inlineButtonBorder: 'var(--kit-stage-hair)',
            tooltipSuccessBackground: 'var(--kit-accent-strong)',
            tooltipSuccessForeground: 'var(--kit-accent-contrast)',
          },
        },
      },
      head: [
        ...['space-grotesk-600', 'inter-400', 'jetbrains-mono-400'].map((face) => ({
          tag: /** @type {const} */ ('link'),
          attrs: {
            rel: 'preload',
            href: `/fonts/${face}.woff2`,
            as: 'font',
            type: 'font/woff2',
            crossorigin: 'anonymous',
          },
        })),
        // The logo's accent dot settles in once per visit, not on every page:
        // after the first page this marks the visit, and tokens.css skips the
        // animation. Inline in <head> so the attribute exists before paint.
        {
          tag: 'script',
          content:
            "try{if(sessionStorage.getItem('kit-logo'))document.documentElement.dataset.logoSeen='';else sessionStorage.setItem('kit-logo','1')}catch(e){}",
        },
        // Must track --kit-paper (dark) in tokens.css.
        { tag: 'meta', attrs: { name: 'theme-color', content: '#0e0f10' } },
        // Google Search Console ownership verification. Inert until
        // PUBLIC_GSC_VERIFICATION is set as a Cloudflare Pages env var.
        ...(GSC_VERIFICATION_TOKEN
          ? [{ tag: /** @type {const} */ ('meta'), attrs: { name: 'google-site-verification', content: GSC_VERIFICATION_TOKEN } }]
          : []),
        // Cloudflare Web Analytics beacon: zero-cookie, no npm dependency.
        // Inert until PUBLIC_CF_BEACON_TOKEN is set.
        ...(CF_BEACON_TOKEN
          ? [
              {
                tag: /** @type {const} */ ('script'),
                attrs: {
                  defer: true,
                  src: 'https://static.cloudflareinsights.com/beacon.min.js',
                  'data-cf-beacon': JSON.stringify({ token: CF_BEACON_TOKEN }),
                },
              },
            ]
          : []),
      ],
      plugins: [
        starlightLlmsTxt({
          projectName: 'Compose Skill (Compose Kit)',
          description:
            'Seven agent skills that make AI coding agents (Claude Code, Codex, Cursor, GitHub Copilot, Gemini CLI, Antigravity, OpenCode) write better Jetpack Compose and Compose Multiplatform code in one consistent house style: MVI on a shared BaseViewModel contract, Koin annotations, Navigation 3, feature-owned data/domain/presentation layers and typed error handling. MIT licensed.',
          details: [
            '## Facts',
            '',
            '- Repository: https://github.com/Meet-Miyani/compose-skill',
            '- Current release: v6.1.0 (stable, released 2026-10-05). The v6.1 A/B test passed every pre-registered rule; the results are on /results/.',
            '- Skills: `compose` (the entry decision tree, about 1.3k tokens), `compose-architecture`, `compose-feature`, `compose-ui`, `compose-data`, `compose-project`, `compose-platform`. Install all seven; they cross-reference each other.',
            '- Install: `npx skills add Meet-Miyani/compose-skill --skill \'*\' -a <agent-id>` (add `-g` for global), `gh skill install` with `--pin v6.1.0`, the Claude Code plugin `compose-kit@compose-kit`, or the Codex plugin `compose-kit@compose-kit`.',
            '- License: MIT',
            '',
            '## Evidence',
            '',
            'v6.1 (5 models, 6 new tasks, 3 arms: no kit, v6.0 kit, v6.1 kit; 90 agentic runs; both graders must pass an item): items passed of 39, no kit / v6.0 / v6.1: Sonnet 5.5 31/35/34, GPT-6-Luna 28/35/37, GPT-6-Sol 30/34/34, Gemini 3.8 Flash 22/33/34, Muse Spark 1.3 27/27/29. All pre-registered rules held, so v6.1.0 is the stable release. Source of truth: evals-v2/results-v6/VERDICT.md in the repository.',
            '',
            'Earlier test, held-out v5: 5 models, 8 never-seen tasks, 3 arms (no kit, generic prompt, kit), 120 agentic runs, graded blind by two models from other vendors; an item passes only when both pass it.',
            'Kit minus no kit: Gemini 3.8 Flash +25.6, Sonnet 5.5 +18.6, Opus 5.5 +9.3, GPT-6-Sol +4.6, GPT-6-Luna +2.3.',
            'Erratum (2026-10-01): two review tasks had flawed setups. Opus\'s +9.3 depends on them (+3.4 without them).',
            'Source of truth: evals-v2/results-v5/VERDICT.md in the repository.',
            '',
            '## Reading order',
            '',
            'Start with `/`, then `/install/` and the page for your agent under `/install/`. `/skills/` explains what each skill owns, `/results/` has the numbers.',
          ].join('\n'),
          optionalLinks: [
            {
              label: 'GitHub repository',
              url: REPO,
              description: 'Source, releases, issues and the evaluation evidence under evals-v2/.',
            },
            {
              label: 'v5 verdict',
              url: `${REPO}/blob/main/evals-v2/results-v5/VERDICT.md`,
              description: 'The frozen held-out v5 scores, pre-registered rules, limits and erratum.',
            },
          ],
          promote: ['index*', 'install/index*', 'skills*'],
          demote: ['roadmap*'],
          customSets: [
            {
              label: 'Install',
              description: 'Install the Compose skill for each agent: Claude Code, Codex, Cursor, GitHub Copilot, Gemini CLI, Antigravity, OpenCode.',
              paths: ['install/**'],
            },
          ],
          pageSeparator: '\n\n---\n\n',
        }),
      ],
      sidebar: [
        {
          label: 'Get started',
          items: [
            { slug: 'install' },
            { slug: 'install/claude-code' },
            { slug: 'install/codex' },
            { slug: 'install/cursor' },
            { slug: 'install/github-copilot' },
            { slug: 'install/gemini-cli-and-antigravity' },
            { slug: 'install/opencode' },
          ],
        },
        { label: 'Kit', items: [{ slug: 'skills' }] },
        { label: 'Evidence', items: [{ slug: 'results' }, { slug: 'how-we-test' }] },
        { label: 'Project', items: [{ slug: 'roadmap' }] },
      ],
    }),
    sitemap({
      // `/og/*.png` are image endpoints, not pages.
      filter: (page) => !page.includes('/og/'),
      changefreq: 'weekly',
    }),
    ogHostGuard(),
  ],
});
