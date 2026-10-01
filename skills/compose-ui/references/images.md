# Images

Load this when a note screen shows remote art, cover thumbnails, or shared-resource pictures.

Contents:
- Which image API to call for note art.
- The one default note-image pattern to reuse.
- Loader ownership: one shared loader per app.
- Placeholder and cache-key pairing for lists and transitions.
- Cache policy defaults and response-cache behavior.
- Transformations compared with modifier clipping.
- Vector note icons and shared-resource URIs.
- CMP placement of image wiring.
- Preview and test doubles for note images.

## Which image API

Take the first row that holds, then stop (IMG-02):

| Situation | Call |
|---|---|
| Note cover, list thumbnail, or detail hero in almost every screen | The default async image composable |
| Note art needed as a painter, or request restarts watched by hand | The painter API with manual control |
| Per-state composable slots needed with first-frame state correctness | The slot API with per-state content |

The slot API subcomposes, so it suits dense note lists poorly. Keep the default API in list-heavy screens (IMG-16).

## Default note-image pattern

Reuse one default pattern for every note image instead of inventing per-screen variants (IMG-04): one shared note-cover component that enables crossfade, sets placeholder, error, and fallback painters, passes the note title as the content description (null only for purely decorative art), crops to fill, and clips with the card shape. Verify the parameter names against the current Coil docs before wiring it. *Prevents:* screens that flash empty frames or ship silent art to screen readers.

For setup, the image library needs its compose artifact plus exactly one network integration matching the project's network stack; name the integration from the current official docs before wiring anything (IMG-01).

## Loader ownership

Keep one shared image loader per app process. Extra loaders split memory and disk caches and lower hit rates (IMG-18).

Libraries accept an injected loader instead of overriding the app singleton (IMG-19).

## Placeholder and cache-key pairing

Pair stable list identity with stable image identity. Note rows already key by note id; give the same logical picture a stable memory cache key in both places it appears (IMG-12, IMG-16):

```kotlin
request(note.coverUrl)
    .memoryCacheKey("note-cover-" + note.id)
    .placeholderMemoryCacheKey("note-cover-" + note.id)
```

The placeholder key reuses the in-memory result as the next request's placeholder, which avoids flashes when a note thumbnail opens into the detail hero. Keep item size predictable so art does not thrash layout (IMG-16).

When the painter API is unavoidable in a cell, supply a size resolver so it does not always fetch the original size (IMG-16).

Cache policy: default request cache policies stay enabled. Override memory, disk, or network policy only for non-default behavior (IMG-11).

When response `Cache-Control` behavior is required, check the current official docs for whether the network fetcher needs an explicit strategy registration, and follow them (IMG-10).

## Pipeline decisions

Custom image work plugs into the pipeline in this order: cross-cutting policy, model mapping, cache keying, fetching, decoding. Register custom components once when building the loader, never per screen (IMG-06, IMG-09).

| Need | Customize | Note |
|---|---|---|
| Retry, short-circuit, or app-wide request policy | Interceptor | Wraps the whole pipeline (IMG-20) |
| Custom source or protocol, such as signed note-asset URLs | Fetcher factory | Data transport only (IMG-23) |
| Custom encoded format | Decoder factory | Converts fetched bytes to a renderable picture (IMG-24) |
| Auth headers for all image calls vs one call | Network client vs per-request headers | Global behavior rides the client; single-call metadata rides the request (IMG-25) |

Never register pipeline components per screen for what request options already cover, never ship a custom fetcher without a stable keyer, never put volatile values in cache keys, never block heavily in an interceptor without bounds, and never put platform-only types in shared pipeline contracts (IMG-09).

## Transformations compared with clipping

Use request transformations only for pixel-level changes to decoded output. Use modifier clipping and shapes for UI-only effects such as rounded note cards. Transformations materialize bitmaps and can collapse an animated picture to a single frame (IMG-13).

## Vector icons and shared-resource art

Vector note icons decode once the vector-decoding artifact is on the classpath; register its decoder factory explicitly only for non-default wiring. Confirm both facts in the current official docs before relying on them (IMG-14).

Load shared note art through the string-URI helper for resources, not through direct drawable handles, which are not image models. Confirm the helper name in the current official docs (IMG-15).

## CMP placement

Keep domain-level model wrappers and mapping intent in shared code. Keep platform-bound client setup in platform source sets, and prefer the broadly multiplatform network option for wide target coverage (IMG-08).

Auth and header behavior for image calls follows the same repository and client rules as other network traffic; see the `compose-data` skill.

## Preview and test doubles

Previews have no network access. Inject the deterministic preview handler for note art in previews (IMG-17).

Enable request logging only in debug builds when diagnosing request, decoder, or cache behavior (IMG-17).

In large apps, inject a custom or fake loader for tests instead of relying on global singleton state (IMG-17).

## Red flags

| Thought | Reality |
|---|---|
| "I'll just use the slot API everywhere; slots are more flexible." | No. Rule 6: reuse the one default pattern first. The slot API costs subcomposition in every note row. |
| "I'll just clear the note art and show a spinner while it refreshes." | No. Rule 7: refresh keeps content with an indicator. Skeletons are cold-load only. |
| "I'll just key note rows by index; the art cache key is enough." | No. Rule 8: item keys come from domain identity, and the image cache key pairs with it. Index keys scramble row state. |
| "I'll just leave the cover description null for now; readers come later." | No. Rule 9: every meaningful picture carries a description from a resource-backed label before done. Null is decorative-only. |
| "I'll just transform the bitmap round in the request; same look." | No. Rule 6: UI-only rounding is modifier clipping. Request transformations materialize bitmaps and can freeze animation. |
| "I'll just build a loader in this screen with its own cache." | No. Rule 6: one shared loader per app. Per-screen loaders fragment caches. |

## Verification

- [ ] Note images call the default API; the slot API appears only where per-state slots are documented: yes or no.
- [ ] One shared note-image component carries crossfade, placeholder, error, fallback, description, and crop: yes or no.
- [ ] No decorative-null description sits on meaningful note art without a comment: yes or no.
- [ ] `rg -n "SubcomposeAsyncImage" --glob '*.kt' <feature-root>` shows no list-cell call sites.
- [ ] `rg -n "memoryCacheKey" --glob '*.kt' <feature-root>` shows keys built from note identity, never timestamps or random values.
- [ ] `rg -n "transformations\(" --glob '*.kt' <feature-root>` is empty for UI-only rounding or clipping.
- [ ] Shared-resource art loads through the string-URI helper, not direct drawable handles: yes or no.
- [ ] Previews inject the deterministic preview handler; request logging is debug-only: yes or no.
