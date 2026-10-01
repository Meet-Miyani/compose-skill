/**
 * Structured-data builders and the OpenGraph image path helper.
 *
 * Everything here is a pure function. `src/components/Head.astro` is the only
 * caller.
 */

/** Human labels for the top-level IA directories. Mirrors the sidebar groups. */
const SECTION_LABELS: Record<string, string> = {
  install: 'Install',
};

/**
 * Starlight's docs loader gives the root `index.mdx` an empty id. Everything
 * downstream (OG routes, breadcrumb keys) needs a stable non-empty key.
 */
export function normalizeEntryId(id: string): string {
  return id === '' || id === '/' ? 'index' : id;
}

/** Path of the generated OpenGraph card for a docs entry. */
export function ogImagePath(id: string): string {
  return `/og/${normalizeEntryId(id)}.png`;
}

function absolute(siteUrl: string, pathname: string): string {
  return new URL(pathname, siteUrl).href;
}

export function breadcrumbListJsonLd(pathname: string, pageTitle: string, siteUrl: string): object {
  const segments = pathname.split('/').filter(Boolean);
  const itemListElement: object[] = [
    { '@type': 'ListItem', position: 1, name: 'Home', item: absolute(siteUrl, '/') },
  ];

  let accumulated = '';
  segments.forEach((segment, index) => {
    accumulated += `/${segment}`;
    const isLast = index === segments.length - 1;
    itemListElement.push({
      '@type': 'ListItem',
      position: index + 2,
      name: isLast ? pageTitle : (SECTION_LABELS[segment] ?? segment),
      item: absolute(siteUrl, `${accumulated}/`),
    });
  });

  return { '@context': 'https://schema.org', '@type': 'BreadcrumbList', itemListElement };
}

export function techArticleJsonLd(args: {
  url: string;
  title: string;
  description: string;
  siteUrl: string;
  dateModified?: string;
}): object {
  const { url, title, description, siteUrl, dateModified } = args;
  return {
    '@context': 'https://schema.org',
    '@type': 'TechArticle',
    headline: title,
    description,
    inLanguage: 'en',
    mainEntityOfPage: { '@type': 'WebPage', '@id': url },
    ...(dateModified ? { dateModified } : {}),
    author: { '@type': 'Person', name: 'Meet Miyani' },
    publisher: { '@type': 'Organization', name: 'Avinya', url: 'https://avinya.dev/' },
    isPartOf: { '@type': 'WebSite', name: 'Compose Kit', url: absolute(siteUrl, '/') },
  };
}

export function softwareSourceCodeJsonLd(siteUrl: string, repoUrl: string): object {
  return {
    '@context': 'https://schema.org',
    '@type': 'SoftwareSourceCode',
    name: 'Compose Skill (Compose Kit)',
    alternateName: ['Compose Kit', 'compose-skill', 'compose-kit'],
    description:
      'Seven agent skills that make Claude Code, Codex, Cursor, Copilot and Gemini write better Jetpack Compose and Compose Multiplatform code in one consistent house style.',
    url: absolute(siteUrl, '/'),
    codeRepository: repoUrl,
    programmingLanguage: 'Kotlin',
    license: 'https://opensource.org/license/mit',
    keywords: [
      'compose skill',
      'agent skills',
      'Jetpack Compose',
      'Compose Multiplatform',
      'Kotlin Multiplatform',
      'Claude Code',
      'Codex',
      'Cursor',
      'GitHub Copilot',
      'Gemini CLI',
    ],
    author: { '@type': 'Person', name: 'Meet Miyani' },
    maintainer: { '@type': 'Organization', name: 'Avinya', url: 'https://avinya.dev/' },
  };
}
