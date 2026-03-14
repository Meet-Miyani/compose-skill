# Testing Strategy

## Table of Contents

- [What to Test in commonMain](#what-to-test-in-commonmain)
- [Compose UI Tests](#compose-ui-tests)
- [Platform Tests](#platform-tests)
- [Snapshot Testing Caveats](#snapshot-testing-caveats)
- [Lean Default Test Matrix](#lean-default-test-matrix)

## What to Test in commonMain

### Reducer Tests (highest ROI)

Since `reduce()` is a pure function, test it directly — no ViewModel, no coroutines, no mocks:

```kotlin
@Test
fun `save with empty name shows validation error`() {
    val state = AddCategoryState(name = "")
    val result = viewModel.reduce(AddCategoryResult.OnSaveClick, state)

    assertEquals("Name is required", result.state.validationErrors["name"])
    assertTrue(result.effects.any { it is AddCategoryEffect.ShowError })
}

@Test
fun `save with valid name sets saving flag`() {
    val state = AddCategoryState(name = "Rings")
    val result = viewModel.reduce(AddCategoryResult.OnSaveClick, state)

    assertTrue(result.state.isSaving)
    assertTrue(result.state.validationErrors.isEmpty())
}

@Test
fun `category saved navigates back with success`() {
    val state = AddCategoryState(isSaving = true)
    val result = viewModel.reduce(AddCategoryResult.CategorySaved, state)

    assertFalse(result.state.isSaving)
    assertTrue(result.effects.any { it is AddCategoryEffect.NavigateBack })
    assertTrue(result.effects.any { it is AddCategoryEffect.ShowSuccess })
}
```

Test:

- Field edit transitions
- Validation transitions
- Derived result updates
- Loading -> success/error transitions
- Retry flow
- Effect emissions for navigation, snackbar, haptics
- Preservation of last good content during refresh

### Validation Tests

Test: required, numeric parse, range, cross-field rules, submit rules.

### Calculation Engine Tests

Test: edge cases, rounding policy, domain invariants, regression fixtures.

### Side Effect Tests (handleEvent / async)

Use fakes for: repositories, share/clipboard/haptics services, clocks, dispatchers.

Verify: emitted effects, cancellation policy, success/error message mapping.

### Turbine for StateFlow Testing

Use `kotlinx-coroutines-test` with the **Turbine** library to test full async flows through the ViewModel (including `handleEvent` + `asyncAction`):

```kotlin
@Test
fun `save category transitions through saving to success`() = runTest {
    val viewModel = AddCategoryViewModel(FakeCategoryRepository(), FakeSettingsDataStore())

    viewModel.state.test {
        val initial = awaitItem()
        assertFalse(initial.isSaving)

        viewModel.onEvent(AddCategoryEvent.OnNameChanged("Rings"))
        awaitItem() // name updated

        viewModel.onEvent(AddCategoryEvent.OnSaveClick)
        val saving = awaitItem()
        assertTrue(saving.isSaving)

        val done = awaitItem()
        assertFalse(done.isSaving)
    }
}
```

Prefer **reducer tests** for state transition logic (pure, fast, no infrastructure). Use **Turbine tests** only for verifying full async flows end-to-end.

## Compose UI Tests

Compose Multiplatform common UI testing uses `runComposeUiTest` rather than Android's JUnit `TestRule` model.

Test:

- Critical field entry flows
- Submit enable/disable behavior
- Error visibility
- Loading placeholder/content swap
- Preserved content during refresh
- Accessibility labels on critical controls

## Platform Tests

### Android/iOS specific

Test:

- Platform shell wiring
- Deep-link entry
- Navigation host integration
- Share sheet / clipboard / haptic bindings
- Platform lifecycle edge cases
- Keyboard/safe-area regressions

## Snapshot Testing Caveats

- Per-platform rendering differences are real
- Typography, antialiasing, and layout can differ slightly
- Shared golden tests across Android/iOS are brittle

**Default:** prefer semantic assertions and interaction tests. Use per-platform visual goldens only for a few high-value screens.

## Lean Default Test Matrix

1. Reducer tests for every feature
2. Validation/calculation tests for every rule-heavy feature
3. UI tests for high-risk screens
4. Platform integration tests only for real platform behavior

Do not sink weeks into screenshot infrastructure before you have reducer coverage.

## Recommendations by App Scale

### Small App

- One shared module, feature packages inside it
- Direct feature ViewModel, reducer can live in same file if small
- Modules: `shared`, `androidApp`, `iosApp`
- Low abstraction level
- Testing: reducer tests, validator/calculator tests, a few shared UI tests
- Avoid: multi-module explosion, base MVI framework, use case per repository call

### Medium App

- `core` shared module + shared feature modules
- Reducer and effect handling separated, shared validators/calculators/services
- Modules: `core`, `feature-estimate`, `feature-settings`, `feature-history`
- Moderate abstraction, extract only reusable logic and UI
- Testing: strong `commonTest` coverage, shared UI tests for high-value screens, platform tests for bindings
- Avoid: app-wide god ViewModel, root feature contract hierarchies

### Large App

- Feature-first modules, shared core primitives only
- Screen ViewModel as default, sub-flow ViewModel only where independently complex
- Strict no-op emission guards, explicit async cancellation policies
- `core-*` for stable cross-feature primitives, many vertical feature modules
- Testing: reducer/effect/domain tests mandatory, more shared UI tests, platform integration tests, performance audits on hot screens
- Avoid: framework worship, generic base ViewModel inheritance trees, premature cross-feature reducer DSLs
