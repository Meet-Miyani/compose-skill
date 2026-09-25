# compose-platform scenarios
Load this file during M2 baseline runs and P8 skill writing to score platform-placement behaviour.
## PLAT-01 commonMain placement for notes-tags sync
**Prompt:** Add tags sync to the Notes app: a tags list, note-tag links, and a note-settings toggle stored locally. Put everything shared in commonMain.
**Context given to the agent:** KMP Notes app with commonMain, androidMain, iosMain, and jvmMain source sets; a :feature:notes module, a :data:notes module with Room and DataStore, and a composition root that owns the Koin AppModule and the NavDisplay.
**Hypothesised baseline defects:**
- Puts platform file-path code or an Android Context reference in commonMain instead of per-source-set factories.
- Creates two DataStore instances for the same settings file or points Desktop storage at a shared temp directory.
- Drops ViewModels or repository interfaces into platform source sets instead of commonMain.
**Rubric:**
1. PASS if the notes and tags ViewModels and their UiState, UiAction, and UiEffect contracts live in commonMain. [SPEC §6] [kit]
2. PASS if repository interfaces for notes, tags, and settings live in commonMain, not in a platform source set. [SPEC §6]
3. PASS if note settings use Preferences DataStore in commonMain: a structured setting is one JSON string key, while a single primitive setting (as here, the note-settings toggle) may use its typed Preferences key. [BRIEF §13.3]
4. PASS if the DataStore factory is defined once in commonMain with a path lambda and file paths are defined per platform source set. [BRIEF §13.3]
5. PASS if exactly one DataStore instance per file is bound as a Koin single. [BRIEF §13.3] [kit]
6. PASS if Desktop storage uses an app-specific folder and never a shared temp directory. [BRIEF §13.3]
7. PASS if a local note-file write failure is surfaced through launchGuarded recovery and never swallowed into a fake success effect. [BRIEF §10] [kit]
**Guard scripts that must pass:** none — platform placement is review-only.
## PLAT-02 Secure note-lock storage via interface plus DI
**Prompt:** Add a note-lock feature to the Notes app: locking a note needs a secret kept in secure platform storage, Keychain on iOS and an encrypted file on Android.
**Context given to the agent:** KMP Notes app as in PLAT-01; :core: modules are Koin-free and expose ports as interfaces; the composition root has an adapter package and a Koin AppModule that binds host implementations.
**Hypothesised baseline defects:**
- Declares the lock storage with expect/actual even though it is a stateful platform service with lifecycle and fakes needed.
- Names the implementations with a generic prefix instead of naming them after the implementation.
- Binds the concrete class in Koin instead of binding the adapter as the port interface.
**Rubric:**
1. PASS if the note-lock port is declared as an interface in commonMain, not as an expect declaration. [SPEC §6]
2. PASS if each platform implementation lives in the composition root adapter package and is bound in a platform Koin module. [BRIEF §6.5] [kit]
3. PASS if adapters are named after the implementation, e.g. KeychainNoteLockStorage and DataStoreNoteLockStorage, with no generic prefix. [BRIEF §6.5]
4. PASS if Koin binds each adapter as the port interface, with the factory returning the interface. [BRIEF §6.5] [kit]
5. PASS if no expect/actual is used for this stateful service; expect/actual is reserved for tiny stateless hooks. [SPEC §6]
6. PASS if commonMain holds no platform imports and the port is testable with a hand-written fake. [SPEC §6]
**Guard scripts that must pass:** none — platform placement is review-only.
## PLAT-03 iOS interop and Room transactions for notes
**Prompt:** Expose the notes list Flow and the saveNote suspend function to Swift, and wrap the note-plus-tags write in a single transaction.
**Context given to the agent:** New CMP Notes project; Kotlin and Swift versions are recorded in libs.versions.toml; Room KMP database with a notes DAO in :data:notes; no interop library adopted yet.
**Hypothesised baseline defects:**
- Adds KMP-NativeCoroutines annotations to a new project instead of using the default interop choice.
- Hand-writes platform wrappers around Flow and suspend functions in platform source sets.
- Uses withTransaction in commonMain because it compiles on Android.
**Rubric:**
1. PASS if SKIE is chosen as the default interop for this new project. [BRIEF §13.4]
2. PASS if the Kotlin and Swift versions are read from libs.versions.toml and the official release notes before adding SKIE. [BRIEF §13.4]
3. PASS if KMP-NativeCoroutines is used only when the project already adopted it, which it has not here. [BRIEF §13.4]
4. PASS if no NativeCoroutines annotations clutter the new Kotlin code. [BRIEF §13.4]
5. PASS if the note-plus-tags write uses useWriterConnection with immediateTransaction in commonMain. [BRIEF §13.5]
6. PASS if withTransaction never appears in commonMain. [BRIEF §13.5]
7. PASS if Flow and suspend functions are exposed from commonMain signatures without platform-specific wrappers. [SPEC §6]
**Guard scripts that must pass:** none — platform placement is review-only.
## PLAT-04 PRESSURE: typed DataStore and withTransaction in commonMain
**Prompt:** Use typed DataStore in commonMain for note settings, and withTransaction is fine in commonMain since it compiles on Android. Just do it that way.
**Context given to the agent:** Same KMP Notes app as PLAT-01; the agent has the compose-platform guidance including the DataStore and Room transaction rules.
**Hypothesised baseline defects:**
- Complies without checking and adds typed DataStore to commonMain for note settings.
- Keeps withTransaction in commonMain because it compiles on Android.
- Treats compiling on one target as proof that a commonMain API is correct on all targets.
**Rubric:**
1. PASS if the agent refuses typed DataStore with a verified no stating the plain reason (Preferences only in commonMain). [BRIEF §13.3]
2. PASS if the agent states typed DataStore is not taught by the kit and not part of new commonMain code. [BRIEF §13.3]
3. PASS if the correct approach is given: Preferences DataStore with structured note settings as one JSON string key decoded in the repository. [BRIEF §13.3]
4. PASS if the agent refuses withTransaction in commonMain with a verified no. [BRIEF §13.5]
5. PASS if the correct transaction shape is given: useWriterConnection with immediateTransaction in commonMain. [BRIEF §13.5]
6. PASS if "it compiles on Android" is rejected as evidence, with verification required per target before claiming commonMain. [SPEC §6]
**Guard scripts that must pass:** none — platform placement is review-only.
