# Resources: Media

Load this when a task adds icons, fonts, or raw files to shared resources: the icon pipeline, composable font construction, or raw-file URIs.

Contents: icon pipeline, fonts, raw files and remote content.

## Icons (RES-07)

**Downloaded Material Symbols XML ships with fill forced to black and tint attributes stripped; recolor at the call site with a runtime tint filter.** A hardcoded icon color misses every theme change. *Prevents:* icons frozen to one theme. (RES-07; SKILL.md rule 5)

Icon homes agree with the design-system reference: stock glyphs stay at the call site and project-drawn glyphs live on the shared set, so this file states no second icon home.

## Fonts (RES-10)

**Build custom `Typography` inside a composable, because `Font()` reads `Res` in composition.** A notes type scale that applies bundled fonts therefore constructs its `FontFamily` at render time, not in a top-level val. *Prevents:* font loading outside composition. (RES-10)

## Raw files, URIs, and remote content (CMP-09, CMP-10, CMP-19, CMP-21)

**Resources packed as Android assets stay reachable to WebViews and media components by path through `getUri`.** A notes export file bundled under `files/` hands its URI to the player instead of its bytes. *Prevents:* bundled media no external API can open. (CMP-19)

**[Decision] Bundled assets are resources; downloaded or remote files never are.** Fetch remote note attachments with an image or network library and convert bytes with the decode helpers before display. *Prevents:* network content modeled as a static resource. (CMP-21)

## Gotchas

- Nearly all resources read synchronously on the caller thread; only raw files and web resources read asynchronously. (CMP-09)
- Big raw files cannot be streamed; pass outside libraries a path through `getUri` instead. (CMP-10)

## Verification

- [ ] Downloaded icons carry fill black with a runtime tint from a theme token; custom `Typography` builds inside a composable: yes or no.
- [ ] No remote or downloaded file is modeled as a resource; bundled media reaches outside libraries by path through `getUri`: yes or no.
