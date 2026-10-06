/**
 * Shared facts for the landing page, header, footer and install pages.
 *
 * Every number and command here is copied from the repository's README.md or
 * evals-v2/results-v6/ (and results-v5/ for the earlier test) on `main`. Do not
 * round, rephrase or add numbers: when the README changes, change this file to
 * match.
 */

export const repoUrl = 'https://github.com/Meet-Miyani/compose-skill';
export const repoSlug = 'Meet-Miyani/compose-skill';
export const issuesUrl = `${repoUrl}/issues`;
export const releasesUrl = `${repoUrl}/releases`;
/** Blob URL for a file on `main`, for linking evidence. */
export const blob = (path: string) => `${repoUrl}/blob/main/${path}`;
/** Tree URL for a folder on `main`. */
export const tree = (path: string) => `${repoUrl}/tree/main/${path}`;

export const version = 'v6.1.0';
export const license = 'MIT';

export const authorName = 'Meet Miyani';
export const authorUrl = 'https://github.com/Meet-Miyani';
export const studioName = 'Avinya';
export const studioUrl = 'https://avinya.dev';

export const quickInstall = "npx skills add Meet-Miyani/compose-skill --skill '*' -a claude-code";

/** The four headline numbers from the top of README.md. */
export const headline = [
  { value: '+30.8', label: 'points for Gemini 3.8 Flash with the v6.1 kit (v6 test)' },
  { value: '+23.1', label: 'points for GPT-6-Luna with the v6.1 kit (v6 test)' },
  { value: '97.4%', label: 'of rubric items for DeepSeek V4.1 Flash with v6.1 (cheap add-on model)' },
  { value: '90 + 36', label: 'agentic runs (panel + add-ons); 2 blind graders must agree on every item' },
] as const;

/**
 * README "What we achieved", in order. `label` is the date or test name; `body`
 * may hold markdown links to pages on this site.
 */
export const achieved = [
  {
    label: 'Held-out v5',
    body: 'The kit lifted Gemini 3.8 Flash by +25.6 points and Sonnet 5.5 by +18.6 over 120 agentic runs. The test also found a real flaw: on a "match our conventions" task, models restructured too much with the kit. [Held-out v5 results](/results/#held-out-v5-the-earlier-test).',
  },
  { label: '2026-10-01', body: 'v6.0.0-preview.1: seven skills, one entry tree, four install channels.' },
  { label: '2026-10-02', body: 'Website live: install guides per agent and a build check that every number on it appears in the evidence files.' },
  {
    label: 'v6 A/B',
    body: '90 agentic runs: v6.0 vs the v6.1 fixes vs no kit. The "no new UI controls, screens or features" item on conform tasks went from 2 of 10 cells (v6.0) to 8 of 10 (v6.1), and every pre-registered rule held. [v6.1 results](/results/#v61-results).',
  },
  {
    label: '2026-10-05',
    body: 'v6.1.0 stable: no model scored below its own no-kit result, so it is released as stable and is the GitHub "Latest" release.',
  },
  {
    label: 'Cheap models',
    body: '36 add-on runs: DeepSeek V4.1 Flash went from 82.1% to 97.4% of items with v6.1, and DeepSeek V4 Pro from 74.4% to 87.2%. [Add-on results](/results/#add-ons-cheap-deepseek-models).',
  },
] as const;

export interface Agent {
  name: string;
  /** Page under /install/. */
  href: string;
  /** Agent ids for `npx skills -a` and `gh skill --agent`. */
  ids: string[];
}

export const agents: readonly Agent[] = [
  { name: 'Claude Code', href: '/install/claude-code/', ids: ['claude-code'] },
  { name: 'Codex', href: '/install/codex/', ids: ['codex'] },
  { name: 'Cursor', href: '/install/cursor/', ids: ['cursor'] },
  { name: 'GitHub Copilot', href: '/install/github-copilot/', ids: ['github-copilot'] },
  { name: 'Gemini CLI and Antigravity', href: '/install/gemini-cli-and-antigravity/', ids: ['gemini-cli', 'antigravity'] },
  { name: 'OpenCode', href: '/install/opencode/', ids: ['opencode'] },
];

export const skills = [
  { name: 'compose', owns: 'The entry decision tree (~1.3k tokens): task kind → affected area → exact reference files' },
  { name: 'compose-architecture', owns: 'Module graph, MVI/BaseViewModel contract, error tiers, state ownership, naming, Koin DI, Navigation 3, coroutines' },
  { name: 'compose-feature', owns: 'A screen or feature slice end to end: contract, ViewModel, UI, navigation, DI and tests; review mode' },
  { name: 'compose-ui', owns: 'Composables: Route/Screen split, stability, loading/empty/error states, lists, animation, accessibility, resources' },
  { name: 'compose-data', owns: 'Repositories, Ktor, Room, DataStore, Paging 3, offline-first, data-layer tests' },
  { name: 'compose-project', owns: 'New projects, adopting the kit, modules, convention plugins, version catalog, CI and agent hooks' },
  { name: 'compose-platform', owns: 'commonMain vs expect/actual, iOS/Swift interop, desktop and web targets, platform lifecycle' },
] as const;

/**
 * README "By task type", new features (3 tasks), all five panel models, both
 * graders agree. The only numbers the hero's agent window shows.
 */
export const newFeatureScore = { without: 43.5, with: 70.6 } as const;
