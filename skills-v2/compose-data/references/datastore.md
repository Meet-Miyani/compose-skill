# DataStore

Load when choosing local storage, wiring Preferences DataStore in `commonMain`, or reviewing settings persistence.

## Storage choice

| Need | Store |
|---|---|
| Key-value settings, flags, tokens (notes sort order, tag filter) | Preferences DataStore |
| Structured settings object | One JSON string key in Preferences DataStore (rule 5) |
| Queries, indexes, relations, more than ~100 entries | Room (see the `compose-data` skill, `room.md`) |
| Large blobs (images, files) | Filesystem, with only the path in Room or DataStore |

1. **Pick the store from the table above, never by habit (non-negotiable).** Settings-shaped data in Room is a migration contract with no queries; relational data in DataStore is unindexed reads that degrade per entry. *Prevents:* a store whose access pattern fits nothing it holds.
2. **Need WHERE/JOIN or more than ~100 entries means Room (non-negotiable).** Past that size a preferences file is a full-file parse per read with no index to prune it. *Prevents:* settings-file queries that slow every launch.
3. **One DataStore instance per file, injected as a Koin `single` (non-negotiable).** Multiple instances on one file break all DataStore functionality; the factory docs say to manage the instance as a singleton (verified: https://developer.android.com/reference/kotlin/androidx/datastore/preferences/core/PreferenceDataStoreFactory). The Hilt singleton-provider shape is not taught; Koin `single` is the kit's expression of it. *Prevents:* store corruption from competing writers.
4. **Settings values crossing the store are immutable (non-negotiable).** A mutated-in-place settings object breaks the transactional read-modify-write consistency that `updateData`/`edit` guarantee (verified: https://developer.android.com/reference/kotlin/androidx/datastore/core/DataStore). Copy on write. *Prevents:* half-written settings visible to concurrent readers.
5. **Structured settings ride as one JSON string key in Preferences DataStore (non-negotiable).** One `stringPreferencesKey` (e.g. `"notes_settings_json"`, verified: https://developer.android.com/codelabs/android-preferences-datastore) holds a `@Serializable` data class encoded with kotlinx.serialization in the repository. The KMP guide documents Preferences DataStore only (verified: https://developer.android.com/kotlin/multiplatform/datastore). *Prevents:* an Android-only storage schema in shared code.
6. **NOT TAUGHT: typed DataStore (`Serializer<T>`).** The stable KMP guide documents Preferences only, so the kit does not teach typed DataStore; the rule-5 JSON-string pattern covers the need with one fewer dependency and no schema-migration contract. DROP DS-12, CONFLICT per D1-9. *Prevents:* shared code written against an Android-tagged `Serializer` surface.
7. **Define the store factory once in `commonMain` with a produce-path lambda; resolve per-platform file paths in the platform source sets (non-negotiable).** One `commonMain` factory function takes the path producer and delegates to the Preferences factory; each platform supplies its own path (Android app files, iOS document directory, JVM app folder), because instantiating the store per platform is the only part of the API that must live in platform source sets (verified: https://developer.android.com/kotlin/multiplatform/datastore). Re-check the exact factory entry point against that page for the pinned version before writing setup code. The path factory is the single sanctioned `expect`/`actual` seam; everything above it stays interface plus DI. *Prevents:* filesystem APIs leaking into shared code.
8. **Desktop storage goes in an app-specific folder, never the shared temp directory (non-negotiable).** A temp-dir file is reaped by the OS and shared with unrelated processes; resolve an app folder (e.g. under the user home) in the JVM source set. *Prevents:* shipped settings that vanish on reboot or collide across apps.
9. **Writes go through `edit` as one atomic read-modify-write transaction (non-negotiable).** `DataStore<Preferences>.edit` serializes all operations; values changed in the transform apply only when it completes (verified: https://developer.android.com/reference/kotlin/androidx/datastore/core/DataStore). Never split one logical write across two `edit` calls. *Prevents:* torn settings from interleaved writes.
10. **Catch IO failures on `dataStore.data`; the file can be unreadable on first launch or after corruption (non-negotiable).** Expose defaults or a typed empty state from the `catch`, never a crash and never a silent empty that hides the failure from the tier decision (SKILL.md rule 5). *Prevents:* first-launch crash on a missing preferences file.
11. **Ship a corruption handler (non-negotiable).** Pass `ReplaceFileCorruptionHandler` at creation (verified: https://developer.android.com/reference/kotlin/androidx/datastore/preferences/core/PreferenceDataStoreFactory); it runs when the serializer cannot de-serialize what is on disk. A store with no handler surfaces raw `CorruptionException` to every collector. *Prevents:* unrecoverable reads after an interrupted write.
12. **Register migrations at creation; `SharedPreferencesMigration` is Android-only and lives in `androidMain` (non-negotiable).** Migrations are a `create` parameter and complete before `dataStore.data` emits or `edit` applies (verified: https://developer.android.com/codelabs/android-preferences-datastore, https://developer.android.com/reference/kotlin/androidx/datastore/migrations/SharedPreferencesMigration). Its constructors take `android.content.Context` / `android.content.SharedPreferences` (verified: https://androidx.github.io/kmp-eap-docs/libs/androidx.datastore/datastore/androidx.datastore.migrations/-shared-preferences-migration/index.html), so construct it in `androidMain` and pass it into the `commonMain` factory through the platform-provided migrations list. Never read the store inside a migration's `cleanUp`. *Prevents:* pre-migration values reaching the UI, and shared code that compiles on Android only.
13. **Map Preferences to domain at the repository boundary (non-negotiable).** The repository exposes note-settings domain types; `Preferences` and raw key lookups never reach a ViewModel or composable (SKILL.md rule 1). *Prevents:* key names and defaults scattered across presentation.
14. **Never read preferences inside composables (non-negotiable).** The Route collects the repository's domain `Flow`; a composable holding `dataStore.data` couples composition to IO scope and duplicates the error path. *Prevents:* recomposition-driven IO with no tier.
15. **Build the provider scope from the application scope plus the IO dispatcher, with migrations at creation (non-negotiable).** `CoroutineScope(appScope.coroutineContext + ioDispatcher)` keeps store IO off the main thread and tied to the process lifetime (pattern verified: https://github.com/android/nowinandroid/blob/main/core/datastore/src/main/kotlin/com/google/samples/apps/nowinandroid/core/datastore/di/DataStoreModule.kt, Apache-2.0). *Prevents:* store IO on the main thread and a scope that dies before pending writes.
16. **Test DataStores come from the factory with a per-test directory (default).** Detail lives in the `compose-data` skill (`data-testing.md`); ViewModel tests bypass the store with fake repositories.

## Red flags

| Thought | Reality |
|---|---|
| "I'll create a second DataStore on the same file for this feature; it is scoped cleaner." | No. This-file rule 3 (SKILL.md rule 10): one instance per file as a Koin `single`. Two instances corrupt. |
| "I'll teach typed DataStore here; it is nicer for settings." | No. This-file rule 6 (SKILL.md rule 10): not taught. One JSON string key covers it. |
| "I'll put the Desktop file in the temp dir like the snippet; it is just local cache." | No. This-file rule 8 (SKILL.md rule 10): app-specific folder. Temp-dir settings vanish. |
| "I'll read `dataStore.data` in the composable; it is already a Flow." | No. This-file rule 14 (SKILL.md rule 1): repository maps to domain; the Route collects. |
| "I'll pass `Preferences` to the ViewModel; the keys are right there." | No. This-file rule 13 (SKILL.md rule 1): domain types leave the repository, never `Preferences`. |
| "I'll skip the corruption handler; the file format is stable." | No. This-file rule 11: handler required. One interrupted write ends every collector. |
| "I'll split this settings write into two edits; each is small." | No. This-file rule 9: one `edit` per logical write. Split writes interleave. |
| "I'll use `java.io.File` paths in `commonMain`; all targets have files." | No. SKILL.md rule 9: paths resolve in platform source sets; `commonMain` takes the lambda. |

## Verification

- [ ] Every entry over ~100 rows or needing WHERE/JOIN lives in Room, not DataStore: yes or no.
- [ ] One Koin `single` per DataStore file: `grep -rn "DataStore" --include='*.kt' <di-root>` shows one binding per file and no second factory call on the same name.
- [ ] No typed DataStore: `grep -rn "Serializer<" --include='*.kt' <data-root>` returns nothing outside unrelated serializers.
- [ ] Factory defined once in `commonMain`, paths per platform source set: yes or no.
- [ ] No shared temp dir: `grep -rn "tmpdir\|java.io.tmp" --include='*.kt' <data-root>` returns nothing.
- [ ] Every write is a single `edit`; every `dataStore.data` collection has an IO `catch`: yes or no.
- [ ] Corruption handler and migrations passed at creation: `grep -rn "ReplaceFileCorruptionHandler\|SharedPreferencesMigration\|migrations" --include='*.kt' <data-root>` returns the creation site.
- [ ] No `Preferences` or `dataStore` import in presentation: `grep -rn "import.*datastore\|Preferences" --include='*.kt' <presentation-root>` returns nothing.
- [ ] Every library API named above was seen in the official docs for the version in `libs.versions.toml`: yes or no.
