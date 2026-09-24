# DataStore audit note — re-verified against current official docs (2026-09-24)

Scope: CONTRACT_BRIEF §13.3 (D1-2) decisions (a)–(e), owner decision O-6
fresh-docs rule (STANDARDS §2.1.6). Carry-over rows: EXTERNAL_LEDGER
CMP-106, CMP-107, CMP-109; HARVEST_LEDGER SKL-39, DS-12. Eval input:
PLAT-01 items 3–6, PLAT-04 items 1–3, M2 baseline PLAT-04 pressure-fold
rows + conclusion 3. HAAT app NOT read (forbidden this phase).

## Verdicts

| # | Decision | Verdict |
|---|---|---|
| (a) | Only Preferences DataStore in KMP/commonMain | KEEP (reword: "documented/taught", see note) |
| (b) | Structured values ride as one serialized JSON string key, decoded in repo | KEEP as kit simplification |
| (c) | Typed DataStore (datastore-core + Serializer) not taught / no new commonMain code | KEEP rule; brief wording must change (see D1-9 fix) |
| (d) | Exactly one DataStore instance per file, bound as Koin single | KEEP |
| (e) | Per-platform path factories; Desktop uses app-specific folder, never tmpdir | KEEP as kit hardening (stricter than docs) |

## (a) Preferences-only in commonMain — KEEP (reworded)

Evidence FOR (all fetched 2026-09-24, page version published 2026-09-09):

- `https://developer.android.com/kotlin/multiplatform/datastore` (2026-09-24): commonMain dependencies list only `datastore:1.2.1` + `datastore-preferences:1.2.1`; all four platform snippets (Android/iOS/Web/JVM) build `DataStore<Preferences>` — page teaches Preferences only.
- Same page (2026-09-24): "You need to define how to instantiate the DataStore object on each platform. This is the only part of the API that is required to be in the specific platform source sets" — supports the per-platform factory shape.
- `https://developer.android.com/jetpack/androidx/releases/datastore` (2026-09-24): "You can now use DataStore in Kotlin Multiplatform projects"; KMP Web support via sessionStorage; older note "non-Android targets … still experimental" sits in the 1.1.x history section, not the current recommendation.
- Third-party corroboration only (NOT load-bearing): "As of now, only Preferences DataStore is supported, while Proto DataStore is still not available for KMP" (LinkedIn, 2025-05-27).

Evidence AGAINST / caution: I could not confirm the literal sentence
"only Preferences DataStore is supported in KMP projects" on the current
page (direct fetch failed; excerpts show Preferences-only content but not
that sentence). Recommend the brief say "the official KMP guide documents
Preferences DataStore only" rather than "only … is supported" — same kit
rule, weaker claim, no overstatement. Corroborates CMP-106 (keep UNVERIFIED
→ re-tag as brief-quote + search-excerpt provenance, not live-fetch).

## (b) One JSON string key, decoded in the repository — KEEP

- `https://kotlinlang.org/docs/serialization-configure-json-serialization.html` (2026-09-24): `Json.encodeToString` / `decodeFromString` round-trip for `@Serializable` classes — the mechanism the kit pattern relies on.
- `https://kotlinlang.org/api/kotlinx.serialization/kotlinx-serialization-json/kotlinx.serialization.json/-json/encode-to-string.html` + `decode-from-string.html` (2026-09-24): API reference for both calls.
- `stringPreferencesKey` exists and is common-multiplatform (kmp-eap-docs `datastore-preferences-core` index, 2026-09-24): "You should not have multiple keys with the same name" — one key per settings blob is consistent with the API contract.
- Against (honest note): official docs teach structured data via typed `Serializer` (`https://developer.android.com/topic/libraries/architecture/datastore`, JSON `SettingsSerializer` example, 2026-09-24) — the single-string-key is a KIT simplification, not an official pattern. Keep because: one fewer dependency, no Serializer/schema-migration contract to teach (ladder rung 1 below). Decode must live in the repository (brief §5: parsing at the boundary), never in the ViewModel.

## (c) Typed DataStore — rule KEEP, brief wording MUST CHANGE (D1-9 fix)

Finding (precise, as requested): typed DataStore is **possible-but-unsupported**,
not impossible — and the brief's current sentence is wrong either way.

- `https://developer.android.com/reference/kotlin/androidx/datastore/core/package-summary` (2026-09-24): `DataStore`, `DataStoreFactory`, `Storage`, `StorageConnection` tagged `Cmn` (common); **`Serializer` tagged `android` only** — the interface a typed DataStore needs is Android-only in the stable API surface.
- `https://developer.android.com/reference/kotlin/androidx/datastore/core/DataStoreFactory` (2026-09-24): generic `create(storage: Storage<T>)` overload tagged `Cmn android N JS` (so a hand-rolled common `Storage<T>` is conceivable), but the `create(serializer, produceFile: File)` overloads are `android`-only.
- `https://androidx.github.io/kmp-eap-docs/.../datastore-core/...` (2026-09-24): datastore-core appears on the KMP **EAP** (early-access/experimental) docs site — not the stable KMP guide, which never mentions datastore-core.
- klibs.io target tables (2026-09-24): `datastore-preferences-core:1.2.1` ships JVM/Native/Wasm/iOS targets — Preferences-core is genuinely multiplatform-published; typed-via-Serializer remains android-tagged regardless of published targets.

Required fix: delete "it is supported in `commonMain` per the artifact's
docs" (brief §13.3 ¶2). Replacement: "Typed DataStore is technically
composable in commonMain via the generic `Storage`-based factory, but the
stable KMP guide documents Preferences only and `Serializer` remains
Android-tagged in the stable API reference — so the kit does not teach it
and new commonMain code must not use it." Kit rule (Preferences-only)
stands either way. This also resolves DS-12/SKL-39: the CONFLICT stands,
now with precise grounds. PLAT-04 rubric items 1–3 need no change
(they already say only "not taught", per D1-9).

## (d) One instance per file, Koin single — KEEP

- `https://developer.android.com/reference/kotlin/androidx/datastore/preferences/core/PreferenceDataStoreFactory` (2026-09-24): "Never create more than one instance of DataStore for a given file … You should consider managing your DataStore instance as a singleton." Same sentence on `DataStoreFactory.create` (2026-09-24), tagged common.
- `https://developer.android.com/topic/libraries/architecture/datastore` (2026-09-24): `preferencesDataStore` delegate "should only be called once in a file"; "You can use Hilt … so that your DataStore instance is unique per process" — official docs bless the one-instance-per-file + DI-singleton shape; Koin `single` is the kit's DI expression of it.
- Supports PLAT-01 item 5 and CMP-107 (first half).

## (e) Per-platform paths; Desktop app-specific folder, never tmpdir — KEEP

- KMP guide jvmMain snippet (2026-09-24): `File(System.getProperty("java.io.tmpdir"), dataStoreFileName)` — the official doc DOES use tmpdir; iOS uses `NSDocumentDirectory`, Android `context.filesDir`, Web `WebLocalStorage`/`WebSessionStorage`.
- The kit rule is therefore a deliberate HARDENING, not doc-derived: tmpdir is shared and may be cleared; an app-specific folder (`~/.appname`) persists. Keep — weakest-model rule ("never tmpdir") prevents the copy-paste defect of shipping the doc snippet verbatim. Brief should cite it as `[kit]` hardening with the doc snippet as the anti-example, not as "per the Android KMP guide" (the guide shows the opposite).
- Supports PLAT-01 items 4 + 6 and CMP-107 (second half) + CMP-109 (expect/actual-or-factory seam for paths only).

## Samples practice

Official guide samples put `createDataStore(storage: Storage<Preferences>)`
in commonMain and one tiny per-platform `createDataStore()` overload
(Context/filesDir, NSDocumentDirectory, WebLocalStorage, tmpdir File).
No official sample shows the single-JSON-string-key or the Koin binding —
both are kit-owned. No official KMP sample shows typed DataStore.

## Ladder input (STANDARDS §1.5 ponytail ladder)

1. Platform/docs cover it? Singleton-per-file, per-platform paths, Preferences API — yes, reuse docs. JSON-string-key, Koin single, app-folder — no, kit rule needed (rung 3: kit template).
2. Simplest version holding: one `stringPreferencesKey` per settings blob (not per field — per-field keys is the observed M2 defect, PLAT-01 item 3 failed by both weak models); decode once in repository with `ignoreUnknownKeys = true` for forward-compat.
3. Carve-outs simplicity never removes: corruption/missing-key defaults (fallback object, never crash), no `observeX` naming, repository interface stays in commonMain.

## Scalability note

Preferences + one JSON blob per settings file holds to 50 modules: one
file per settings owner, one Koin single each, no schema-migration
ceremony. Breaks when: blob exceeds ~100 KB, two writers contend on
`updateData` for different fields in one blob, or partial-update/query
needs appear — all are migrate-to-Room signals, not reasons to adopt
typed DataStore. State that trigger in the skill; do not pre-teach Room
for settings.

## Reachability log (2026-09-24)

- FETCH FAIL (timeout, twice): `https://developer.android.com/kotlin/multiplatform/datastore` direct webfetch; `https://developer.android.com/jetpack/androidx/releases/datastore` direct webfetch. Same failure class as Phase 2.5 harvest (developer.android.com unreachable from worker env).
- OK via websearch excerpts (cached, page version 2026-09-09): KMP datastore setup page (deps, all 4 platform snippets, singleton/factory quotes), datastore release notes (KMP + Web support), datastore topic guide (Preferences vs typed, JSON SettingsSerializer), API ref DataStore / DataStoreFactory / Serializer / Preferences.Key / datastore-core package-summary (Cmn vs android tags), kmp-eap-docs datastore-core + preferences-core indexes.
- OK direct: `https://kotlinlang.org/docs/serialization-configure-json-serialization.html`, kotlinx.serialization `encodeToString` / `decodeFromString` API pages, klibs.io target tables — via search excerpts.
- No JetBrains KMP-docs fallback needed (AndroidX excerpts sufficed); no HAAT read.

## Facts I could not verify

1. The literal "only Preferences DataStore is supported in KMP" sentence on the current guide — excerpts show Preferences-only content, not the sentence. Reword per §(a); do not quote what I did not see.
2. Whether a hand-rolled common `Storage<T>` makes typed DataStore actually WORK on iOS/Desktop today — conceivable per Cmn tags, unverified end-to-end (no build in this phase). Irrelevant to the kit rule; recorded so nobody upgrades "possible" to "supported".
3. Exact `dataStoreFileName` constant / `Storage` import paths in the current guide — excerpts truncate them; the writing phase must live-fetch before landing template code (O-6).
