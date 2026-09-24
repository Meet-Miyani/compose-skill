# Feature Testing: ViewModel Tests, Fakes, and the State Matrix
Load this when writing or reviewing a ViewModel test, a fake repository, dispatcher setup, or state-matrix coverage.

## Contents
- House ViewModel-test convention (§9.1–9.2) and verified test APIs
- Canonical skeleton: setUp/tearDown plus one cold-load test
- State matrix: what to arrange and assert per row (§9.3)
- What to test where: ViewModel, validator, UI, platform shape
- Fakes: control fields, replaying streams, derived-value rule
- Dispatchers and determinism: Main rule, queuing, injected seams
- Source sets and shared asserts: host versus device, Koin boundary
- Validators, UI/platform reservation, gotchas, verification

## House ViewModel-test convention (§9.1–9.2)
Exercise the public event API through the public state API. Drive input with `onAction`, then read `state.value` after `advanceUntilIdle()`. Collect effects first with `backgroundScope.launch { vm.effect.toList(effects) }`, then assert the list. *Prevents:* tests that pass by timing luck instead of observed state.
Use `runTest` with a test dispatcher set as `Main`. Set `Main` in setUp, reset it in tearDown. Share one scheduler between the `runTest` scope and `Main`. *Prevents:* hangs and flakes from split schedulers.
Construct the ViewModel directly: `FakeNotesRepository`, the params object, a `SavedStateHandle()` test instance, and injected dispatchers. Never load Koin in a ViewModel test. Never use a mocking library. Assert with `kotlin.test`. *Prevents:* tests that exercise the DI framework instead of the contract.
Turbine is not part of the kit. Never add it; the `backgroundScope` plus `toList` shape covers effect and state assertions. *Prevents:* an extra dependency for an assertion the stdlib already performs.
Verified against https://kotlinlang.org/api/kotlinx.coroutines/kotlinx-coroutines-test/ — use only: `runTest(context)`, `TestScope.advanceUntilIdle()`, `TestScope.backgroundScope`, `StandardTestDispatcher()`, `Dispatchers.setMain` / `Dispatchers.resetMain`, `kotlinx.coroutines.flow.toList(destination)`. Verify every other helper in the project or official docs before calling it.
*Trace: CONTRACT_BRIEF §9.1, §9.2; SMP-56 (Main rule plus fakes plus coroutine test API).*

## Canonical skeleton
One shape for every ViewModel test in `com.example.feature.notes`. Copy it, do not reinvent it. Names match the feature templates exactly (`NotesParams(noteId)`, `OnScreenStarted`).
```kotlin
private lateinit var fake: FakeNotesRepository
private val dispatcher = StandardTestDispatcher()
@BeforeTest fun setUp() { Dispatchers.setMain(dispatcher); fake = FakeNotesRepository() }
@AfterTest fun tearDown() { Dispatchers.resetMain() }
@Test fun `cold load fills detail`() = runTest(dispatcher) {
  fake.seed(listOf(Note(id = 1L, title = "T", body = "B", updatedAt = null))) // absence stays null; never a sentinel
  val effects = mutableListOf<NotesUiEffect>()
  val vm = NotesViewModel(fake, NotesParams(noteId = 1L), SavedStateHandle(), dispatcher)
  backgroundScope.launch { vm.effect.toList(effects) }
  vm.onAction(NotesUiAction.OnScreenStarted); advanceUntilIdle()
  assertEquals(1, vm.state.value.items.size)
  assertTrue(effects.isEmpty())
}
```

## State matrix (§9.3)
One line per row: arrange the fake, drive the action, assert state and effects. The start action is `OnScreenStarted` in every row.
- Cold load: fake returns two notes; send `OnScreenStarted` with no prior data; assert content, `isLoading` false, no error, no effect.
- Reconcile: preload one list, return an updated list on next `OnScreenStarted`; assert prior content stays until the fresh list replaces it.
- Refreshing: set content, send a second `OnScreenStarted` against a slow fake; assert old content stays plus `isRefreshing` true, then fresh content with false.
- Error: set `fake.shouldThrow`; send `OnScreenStarted` on empty content; assert `error` holds the mapped `AppError` with Retry available.
- Retry: keep the failed error, clear `shouldThrow`, send `OnRetryClick`; assert content on success or the same error when still failing.
- Empty: fake returns zero rows; assert the empty business flag with no `AppError` set.
- Not found: fake returns null for the id; assert `isMissing` with no `AppError` set.
- Overlapping loads: start a slow load, send refresh before it completes; assert the second trigger skips and only the in-flight response writes.
- Process-death restore [kit]: construct with the key id and an empty fake cache; assert it re-fetches by identity, never null from a cold cache. Mandatory for detail destinations. *Prevents:* a restored detail that cannot resolve.
*Trace: CONTRACT_BRIEF §9.3, §8.3, §8.4; house rows plus the kit restore row.*

## What to test where
Write one ViewModel test class per destination covering the matrix. It is the highest-ROI test; write it before any UI test. *Prevents:* skipped states hidden behind UI-only coverage.
Write pure validator/calculator tests per rule-heavy feature (see Validators). Write UI tests only for high-risk screens. Reserve platform tests for real platform behavior. Never build screenshot infrastructure before ViewModel coverage exists. *Prevents:* wrong-test-priority.
*Trace: TEST-14 (ViewModel tests per feature, pure tests per rule-heavy feature, UI tests for high-risk screens, platform tests for real behavior, no screenshots before VM coverage; Turbine conflict resolved: house backgroundScope plus toList, never Turbine).*

## Fakes
Hand-write `FakeNotesRepository` in the test source set. Expose `shouldThrow: Throwable?` or a `respond` stub the test owns. Never generate it with a mocking library. *Prevents:* mock-fragility.
Back streams with replaying hot flows preloaded with empty defaults, plus test-only setters that push values. *Prevents:* asserting against a stream that never emitted.
Launch background collectors before driving actions: `stateIn` flows start on collect, so collect in `backgroundScope` first, then `onAction`, then `advanceUntilIdle()`. *Prevents:* asserting a value collection never started.
Never test derived values in isolation from ViewModel state. Assert labels, flags, and totals through `vm.state.value`, never mapper-only when the ViewModel owns the field. *Prevents:* a green mapper beside broken wiring.
Give `UiState` an explicit loading initial value and pin loading-to-success: assert `isLoading` true after the action, then content with false after idle. *Prevents:* a spinner that never appears or never clears.
*Trace: CONTRACT_BRIEF §9.2; TEST-39 (derived values through ViewModel state); SMP-57 (replaying hot flows, empty defaults, test-only setters); SMP-58 (stateIn starts on collect: collectors first); SMP-59 (explicit loading value; pin loading-to-success).*

## Dispatchers and determinism
Inject dispatchers as constructor parameters on the ViewModel and on any repository that dispatches. The only allowed `Dispatchers.IO` occurrence in production is a `= Dispatchers.IO` default on an injected parameter; never look it up at a call site. The callee switches with the injected dispatcher. *Prevents:* untestable threading. *Trace: CONTRACT_BRIEF §3.6, §9.4.*
Default to queuing `StandardTestDispatcher` shared between `runTest` and `Main`; it holds tasks until `advanceUntilIdle()`. *Prevents:* assertions that race the dispatcher.
Use `UnconfinedTestDispatcher` only for hot-flow collector setup, with the reason stated in a comment. *Prevents:* eager execution hiding an ordering defect.
*Trace: SKT-60 (queuing dispatcher default; unconfined only for hot-flow collector setup with stated reason); SKT-61 (set Main; one scheduler shared).*
Inject clock and random seams with dispatchers; control time and ids from the test. Disable animations in tests. *Prevents:* flaky timestamps and animated assertions.
*Trace: SKT-80 (inject clock/dispatcher/random; disable animations).*
For repository and stream mechanics, see the `compose-data` skill. For MVI ownership and overlap guards, see the `compose-architecture` skill.

## Source sets and shared asserts
Keep pure logic plus ViewModel tests in the host source set (`commonTest`, JVM runner in `jvmTest`). Run real-device UI tests in the device source set. *Prevents:* JVM-runnable assertions paying device cost.
*Trace: SKT-85 (host source set for pure logic plus ViewModel tests; device source set for device UI tests); SMP-60 (commonTest coroutine-test support; JVM runner in jvmTest).*
Share assertions with `kotlin.test`; never split assertion libraries per platform. *Prevents:* two dialects for one expectation.
*Trace: SKT-90 (kotlin.test shared asserts).*
The Koin module dry-run check (`verify()`) belongs in `commonTest`. ViewModel tests construct fakes directly and never touch Koin. *Prevents:* graph failures surfacing as ViewModel failures.
*Trace: KOIN-13 (verify() dry-run check in commonTest; ViewModel tests use no Koin).*

## Validators, UI/platform reservation
Test validators and calculators as pure functions next to the function: parsing, rounding, invariants, fixtures. No ViewModel, no dispatcher, no fake. *Prevents:* rules reachable only behind a full screen. *Trace: CONTRACT_BRIEF §9.5.*
Platform tests (shell wiring, deep-link entry, nav-host integration, share/clipboard/haptic bindings, lifecycle edges, keyboard and safe-area regressions) and Compose UI tests (field-entry flows, submit gating, error visibility, placeholder/content swap, refresh preserves content, accessibility labels) run on-device for real platform behavior; semantic assertions are the default, visual goldens cover a few high-value screens.

## Gotchas
- A `runTest` without `setMain` leaves `viewModelScope` on a live dispatcher; the test asserts before the load runs.
- Reading `state.value` before `advanceUntilIdle()` reads the loading frame; advance first, then read.
- Collecting effects after `onAction` misses the emission; launch the collector before driving actions.
- A fake backed by a cold flow with no replay delivers nothing; preload empty defaults with test-only setters.
- A mapper-only assertion when the ViewModel owns the field hides broken wiring; assert through `vm.state.value`.
- `UnconfinedTestDispatcher` everywhere hides ordering defects; default to the queuing dispatcher.
- Hardcoded `Dispatchers.IO` removes the test seam; inject the dispatcher and switch in the callee.
- No explicit loading initial value starts as content; pin the loading-to-success transition.
- Screenshot goldens before matrix coverage picture broken states; finish ViewModel tests first.

## Verification
- [ ] Each destination has one ViewModel test class covering all applicable matrix rows (yes/no).
- [ ] Each test sets `Main` in setUp and resets it in tearDown on one shared scheduler (yes/no).
- [ ] Effects collect via `backgroundScope` plus `toList` before the action; no Turbine import (run `rg -l "turbine" --glob '*.kt'`; zero hits).
- [ ] Each ViewModel is built directly with fake, params object, `SavedStateHandle()`, dispatchers; no Koin, no mocks (yes/no).
- [ ] Stream fakes preload empty defaults with test-only setters; collectors launch before actions (yes/no).
- [ ] No derived value is asserted mapper-only when the ViewModel owns the field (yes/no).
- [ ] Loading-to-success is pinned where a loading flag exists (yes/no).
- [ ] No production file references `Dispatchers.IO` outside a constructor default value (run `rg -n "Dispatchers\.IO" --glob '*.kt'`; every hit is a `= Dispatchers.IO` default on an injected dispatcher parameter, never a call-site lookup).
- [ ] `verify()` lives in `commonTest`; ViewModel tests hold no Koin rule (yes/no).
- [ ] Shared asserts use `kotlin.test` only (yes/no).
