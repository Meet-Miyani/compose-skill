/**
 * Host guard for compose.avinya.dev (copied from the AdMob CMP docs site).
 *
 * Cloudflare Pages answers on three kinds of host:
 *   1. compose.avinya.dev          — the canonical custom domain. Serve.
 *   2. <project>.pages.dev         — the production preview host. 301 away, so
 *                                    Google never has two crawlable copies of
 *                                    the site to choose between.
 *   3. <hash>.<project>.pages.dev  — per-deployment previews. Serve them (they
 *                                    exist to be reviewed) but mark them
 *                                    noindex so they cannot be indexed.
 *
 * The Pages project name is deliberately NOT hardcoded: cases 2 and 3 are
 * distinguishable by label count alone, so renaming the Pages project cannot
 * desync this file.
 *
 *   <project>.pages.dev          -> 3 labels
 *   <hash>.<project>.pages.dev   -> 4 labels
 */

const CANONICAL_HOST = 'compose.avinya.dev';
const PAGES_SUFFIX = '.pages.dev';
const PRODUCTION_PREVIEW_LABEL_COUNT = 3;

/** True for `<project>.pages.dev`, false for `<hash>.<project>.pages.dev`. */
export function isProductionPreviewHost(hostname) {
  if (!hostname.endsWith(PAGES_SUFFIX)) return false;
  return hostname.split('.').length === PRODUCTION_PREVIEW_LABEL_COUNT;
}

/** Response headers are immutable, so a tagged copy is the only way to set one. */
function withRobotsTag(response, value) {
  const headers = new Headers(response.headers);
  headers.set('X-Robots-Tag', value);
  return new Response(response.body, {
    status: response.status,
    statusText: response.statusText,
    headers,
  });
}

export async function onRequest(context) {
  const url = new URL(context.request.url);

  if (url.hostname === CANONICAL_HOST) {
    return context.next();
  }

  if (isProductionPreviewHost(url.hostname)) {
    url.hostname = CANONICAL_HOST;
    url.protocol = 'https:';
    url.port = '';
    return Response.redirect(url.toString(), 301);
  }

  return withRobotsTag(await context.next(), 'noindex, nofollow');
}
