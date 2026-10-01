# DataStore

Load when: choosing local storage or reviewing settings persistence.

## Choose

- Is it a large blob such as a photo or file?
  - Yes: keep the file in app storage and only its path in the database; delete the file with its row. *Prevents:* oversized database rows and orphaned files. https://developer.android.com/training/data-storage/app-specific
  - No: does it need records, queries, indexes, or relations?
    - Yes: use Room; see `room.md`. *Prevents:* full-file scans for record queries.
    - No: is it a small setting or settings object?
      - Yes: use Preferences DataStore; one JSON string key is the default for an object. Typed `OkioSerializer` with `OkioStorage` is also valid in common code. *Prevents:* a platform-only storage type in shared code. https://developer.android.com/kotlin/multiplatform/datastore https://github.com/androidx/androidx/blob/androidx-main/datastore/datastore-core-okio/src/commonMain/kotlin/androidx/datastore/core/okio/OkioSerializer.kt
- Not covered here → use judgement and state the assumption.

## Rules

3. **One DataStore instance per file, injected as a Koin `single` (non-negotiable).** Multiple instances on one file throw `IllegalStateException`; the factory docs say to manage the instance as a singleton (verified: https://developer.android.com/reference/kotlin/androidx/datastore/preferences/core/PreferenceDataStoreFactory). *Prevents:* `IllegalStateException` from competing instances.
4. **Settings values crossing the store are immutable (non-negotiable).** A mutated-in-place settings object breaks the transactional read-modify-write consistency that `updateData`/`edit` guarantee (verified: https://developer.android.com/reference/kotlin/androidx/datastore/core/DataStore). Copy on write. *Prevents:* half-written settings visible to concurrent readers.
5. **Default: store a structured settings object as one JSON string key in Preferences DataStore.** A `stringPreferencesKey` (verified: https://developer.android.com/codelabs/android-preferences-datastore) holds a `@Serializable` object encoded at the repository boundary. A primitive can use its typed Preferences key. *Prevents:* scattered keys for one logical settings object.
6. **Typed DataStore is a valid common-code option.** `OkioSerializer<T>` and `OkioStorage` live in `commonMain`; verify their API against the pinned library before using them. https://github.com/androidx/androidx/blob/androidx-main/datastore/datastore-core-okio/src/commonMain/kotlin/androidx/datastore/core/okio/OkioSerializer.kt *Prevents:* ruling out a supported typed store.
7. **Define the store factory once in `commonMain` with a produce-path lambda; resolve per-platform file paths in the platform source sets (non-negotiable).** One `commonMain` factory function takes the path producer and delegates to the Preferences factory; each platform supplies its own path (Android app files, iOS document directory, JVM app folder), because instantiating the store per platform is the only part of the API that must live in platform source sets (verified: https://developer.android.com/kotlin/multiplatform/datastore). Re-check the exact factory entry point against that page for the pinned version before writing setup code. The path factory is the single sanctioned `expect`/`actual` seam; everything above it stays interface plus DI. Supply the binding in every target the project declares: a target with no DataStore path binding fails the iOS link under the Koin compiler plugin (KOIN-D002 in the Phase 9 trial). *Prevents:* filesystem APIs leaking into shared code.
8. **Desktop storage goes in an app-specific folder, never the shared temp directory (non-negotiable).** A temp-dir file is reaped by the OS and shared with unrelated processes; resolve an app folder (e.g. under the user home) in the JVM source set. *Prevents:* shipped settings that vanish on reboot or collide across apps.
9. **Writes go through `edit` as one atomic read-modify-write transaction (non-negotiable).** `DataStore<Preferences>.edit` serializes all operations; values changed in the transform apply only when it completes (verified: https://developer.android.com/reference/kotlin/androidx/datastore/core/DataStore). Never split one logical write across two `edit` calls. *Prevents:* torn settings from interleaved writes.
10. **Catch real IO failures on `dataStore.data` (non-negotiable).** A missing file yields the default; an unreadable file is a real read failure. Route that failure to an error tier rather than silently showing empty state. https://developer.android.com/reference/kotlin/androidx/datastore/core/DataStoreFactory *Prevents:* a real storage failure hidden as a normal first launch.
11. **Ship a corruption handler (non-negotiable).** Pass `ReplaceFileCorruptionHandler` at creation (verified: https://developer.android.com/reference/kotlin/androidx/datastore/preferences/core/PreferenceDataStoreFactory); it runs when the serializer cannot de-serialize what is on disk. A store with no handler surfaces raw `CorruptionException` to every collector. *Prevents:* unrecoverable reads after an interrupted write.
12. **Register migrations at creation; `SharedPreferencesMigration` is Android-only and lives in `androidMain` (non-negotiable).** Migrations are a `create` parameter and complete before `dataStore.data` emits or `edit` applies (verified: https://developer.android.com/codelabs/android-preferences-datastore, https://developer.android.com/reference/kotlin/androidx/datastore/migrations/SharedPreferencesMigration). Its constructors take `android.content.Context` / `android.content.SharedPreferences` (verified: https://androidx.github.io/kmp-eap-docs/libs/androidx.datastore/datastore/androidx.datastore.migrations/-shared-preferences-migration/index.html), so construct it in `androidMain` and pass it into the `commonMain` factory through the platform-provided migrations list. Never read the store inside a migration's `cleanUp`. *Prevents:* pre-migration values reaching the UI, and shared code that compiles on Android only.
13. **Map Preferences to domain at the repository boundary (non-negotiable).** The repository exposes note-settings domain types; `Preferences` and raw key lookups never reach a ViewModel or composable (SKILL.md rule 1). *Prevents:* key names and defaults scattered across presentation.
14. **Never read preferences inside composables (non-negotiable).** The Route collects the repository's domain `Flow`; a composable holding `dataStore.data` couples composition to IO scope and duplicates the error path. *Prevents:* recomposition-driven IO with no tier.
15. **Build the provider scope from the application scope plus the IO dispatcher, with migrations at creation (non-negotiable).** `CoroutineScope(appScope.coroutineContext + ioDispatcher)` keeps store IO off the main thread and tied to the process lifetime (pattern verified: https://github.com/android/nowinandroid/blob/main/core/datastore/src/main/kotlin/com/google/samples/apps/nowinandroid/core/datastore/di/DataStoreModule.kt, Apache-2.0). *Prevents:* store IO on the main thread and a scope that dies before pending writes.
16. **Test DataStores come from the factory with a per-test directory (default).** Detail lives in the `compose-data` skill (`data-testing.md`); ViewModel tests bypass the store with fake repositories.


## Verification

- [ ] Every entry over ~100 rows or needing WHERE/JOIN lives in Room, not DataStore: yes or no.
- [ ] One Koin `single` per DataStore file: `grep -rn "DataStore" --include='*.kt' <di-root>` shows one binding per file and no second factory call on the same name.
- [ ] A typed common-code store, if chosen, uses verified `OkioSerializer` and `OkioStorage` APIs: yes or no.
- [ ] Factory defined once in `commonMain`, paths per platform source set: yes or no.
- [ ] No shared temp dir: `grep -rn "tmpdir\|java.io.tmp" --include='*.kt' <data-root>` returns nothing.
- [ ] Every write is a single `edit`; every `dataStore.data` collection has an IO `catch`: yes or no.
- [ ] Corruption handler and migrations passed at creation: `grep -rn "ReplaceFileCorruptionHandler\|SharedPreferencesMigration\|migrations" --include='*.kt' <data-root>` returns the creation site.
- [ ] No `Preferences` or `dataStore` import in presentation: `grep -rn "import.*datastore\|Preferences" --include='*.kt' <presentation-root>` returns nothing.
- [ ] Every library API named above was seen in the official docs for the version in `libs.versions.toml`: yes or no.
