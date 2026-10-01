# Desktop and Web

Load this when the task touches desktop window lifecycle, the web/wasmJs target, web resources or fonts, Hot Reload, or keyboard and safe-area edges.

## Desktop lifecycle

1. **Map window events to lifecycle states, never to custom flags (non-negotiable).** Iconify means ON_STOP, deiconify means ON_START, focus loss means ON_PAUSE, focus gain means ON_RESUME, dispose means ON_DESTROY; a Notes list that treats iconify as destroy loses scroll state. *Prevents:* window events handled as app death. https://www.jetbrains.com/help/kotlin-multiplatform-dev/compose-lifecycle.html
2. **For Main-dispatcher and scope setup on desktop, follow SKILL.md rule 6 (non-negotiable).** This file does not restate that rule; rule 6 owns the version floor and the dependency. *Prevents:* two sources of truth for the desktop Main dispatcher.

## Web lifecycle and navigation

3. **Never wait for CREATED or DESTROYED on web (non-negotiable).** The web app is always attached so it skips CREATED, and a closed tab never reaches DESTROYED, so cleanup that only runs there never runs. *Prevents:* release logic that never fires on web. https://www.jetbrains.com/help/kotlin-multiplatform-dev/compose-lifecycle.html
4. **Mirror web routes with `bindToBrowserNavigation` using fragments that start with `#` (non-negotiable).** The helper mirrors the route in the URL fragment; a custom fragment without the leading hash pastes to the wrong endpoint and a shared Notes deep link breaks. *Prevents:* web links that land on the wrong screen. https://www.jetbrains.com/help/kotlin-multiplatform-dev/compose-navigation-routing.html
5. **Give web routes a readable stable `SerialName` (default).** Default fragments embed the serial name plus arguments, so an unnamed Notes-detail key produces an unstable unreadable URL. *Prevents:* unstable web URLs. https://www.jetbrains.com/help/kotlin-multiplatform-dev/compose-navigation-routing.html
6. **Check current docs before depending on Nav3 browser history on web (non-negotiable).** Base-library Nav3 browser-history support is still planned upstream, so a community workaround adopted today can rot under the next release. *Prevents:* navigation built on an unowned workaround. https://www.jetbrains.com/help/kotlin-multiplatform-dev/compose-navigation-3.html

## Web target and resources

7. **Treat the wasmJs target status as a verify gate, not a settled fact (default).** Confirm Beta status, the wasmJs target name, and WasmGC plus modern-browser requirements in current official docs before promising web support. *Prevents:* shipping a web target the toolchain no longer matches.
8. **Gate web first paint on the resource preload helpers (non-negotiable).** Web images and fonts load over fetch, so a Catalog list painted before preload shows empty frames then font swaps. *Prevents:* blank first paint on web. https://www.jetbrains.com/help/kotlin-multiplatform-dev/compose-web-resources.html
9. **Never assume a web resource survives a relaunch (non-negotiable).** The web resource cache clears on every launch for consistency, and duplicate in-flight fetches serialize behind per-resource locks, so startup always refetches. *Prevents:* offline-on-second-launch assumptions on web. https://www.jetbrains.com/help/kotlin-multiplatform-dev/compose-web-resources.html
10. **Expect on-demand Noto subset downloads for unresolved glyphs (default).** Unresolved glyphs download Noto subsets on demand with CJK chosen from the browser language, and brief tofu can still flash first on a Notes editor with mixed scripts. *Prevents:* surprise font flashes treated as bugs. https://www.jetbrains.com/help/kotlin-multiplatform-dev/compose-web-resources.html
11. **Remap served web resource URLs with `configureWebResources`, never by hardcoding paths (non-negotiable).** Served paths change between local serving and CDN layouts, so a hardcoded path breaks the Catalog images in one of them. *Prevents:* resource URLs that work in exactly one environment. https://www.jetbrains.com/help/kotlin-multiplatform-dev/compose-multiplatform-resources-setup.html
12. **Set a custom web locale through the `index.html` `Navigator.languages` override plus a `languagechange` listener (non-negotiable).** The property is read-only, so assigning it directly silently does nothing and the Notes list stays in the browser locale. *Prevents:* locale overrides that never apply on web. https://www.jetbrains.com/help/kotlin-multiplatform-dev/compose-resource-environment.html

## Hot Reload

13. **Use Hot Reload only as a desktop-JVM sandbox for iterating on common UI (default).** It speeds up Notes-screen iteration but never proves iOS or web behavior, so target runs still close every gate. *Prevents:* desktop-only verification. https://www.jetbrains.com/help/kotlin-multiplatform-dev/compose-hot-reload.html
14. **Meet the Hot Reload floor before using it: Kotlin 2.1.20 or newer with JetBrains Runtime Java 21 or earlier (non-negotiable).** Below the floor reload fails or misbehaves instead of reporting cleanly. *Prevents:* debugging the tool instead of the UI. https://www.jetbrains.com/help/kotlin-multiplatform-dev/compose-hot-reload.html
15. **Prefer the bundled default on CMP 1.10 or newer; upgrade instead of hand-wiring (default).** The plugin ships bundled and enabled by default for desktop targets there, so manual wiring adds a second setup that rots. *Prevents:* duplicate Hot Reload setups. https://www.jetbrains.com/help/kotlin-multiplatform-dev/compose-hot-reload.html
16. **Drive agent-led iteration through the Hot Reload MCP server task on CMP 1.12 or newer (default).** The server reloads code, captures screenshots, reads the semantic tree, pulls logs, and drives input, which beats describe-and-guess loops. *Prevents:* blind UI iteration. https://www.jetbrains.com/help/kotlin-multiplatform-dev/compose-hot-reload.html

## Keyboard, focus, and safe-area edges

17. **Test text input on real iOS hardware and isolate quirks at the UI or platform edge (non-negotiable).** Simulators hide focus and composition quirks that only the Notes editor on device shows. *Prevents:* keyboard bugs found after release.
18. **Never put keyboard workaround flags in shared feature state (non-negotiable).** Shared UI uses inset and safe-area layout, and a flag in `UiState` couples every target to one phone's keyboard bug. *Prevents:* platform hacks leaking into shared state.*
19. **Never put safe-area hacks into feature state (non-negotiable).** Insets-aware shared layouts own safe areas, keyboard overlap, sheets, and nav chrome; a `safeAreaHack` field in the Notes `UiState` is deleted on sight. *Prevents:* layout hacks that three targets inherit.*

## Boundary

- Desktop Main-dispatcher mechanics live in SKILL.md rule 6; desktop packaging, signing, and distribution mechanics live in the `compose-project` skill. This file owns neither.
