/**
 * Shared facts for the landing page, header, footer and install pages.
 *
 * Every number and command here is copied from the repository's README.md or
 * evals-v2/results-v5/ on `main`. Do not round, rephrase or add numbers: when
 * the README changes, change this file to match.
 */

export const repoUrl = 'https://github.com/Meet-Miyani/compose-skill';
export const repoSlug = 'Meet-Miyani/compose-skill';
export const issuesUrl = `${repoUrl}/issues`;
export const releasesUrl = `${repoUrl}/releases`;
/** Blob URL for a file on `main`, for linking evidence. */
export const blob = (path: string) => `${repoUrl}/blob/main/${path}`;
/** Tree URL for a folder on `main`. */
export const tree = (path: string) => `${repoUrl}/tree/main/${path}`;

export const version = 'v6.0.0-preview.1';
export const license = 'MIT';

export const authorName = 'Meet Miyani';
export const authorUrl = 'https://github.com/Meet-Miyani';
export const studioName = 'Avinya';
export const studioUrl = 'https://avinya.dev';

export const quickInstall = "npx skills add Meet-Miyani/compose-skill --skill '*' -a claude-code";

/** The four headline numbers from the top of README.md. */
export const headline = [
  { value: '+25.6', label: 'points for Gemini 3.8 Flash with the kit' },
  { value: '+18.6', label: 'points for Sonnet 5.5 with the kit' },
  { value: '120', label: 'agentic runs on 8 never-seen tasks' },
  { value: '2', label: 'blind graders from other vendors must agree on every item' },
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
