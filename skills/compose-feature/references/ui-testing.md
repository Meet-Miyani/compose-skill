# Compose UI Testing
Load this when writing or reviewing a Compose UI test for a Notes destination.

## Contents
- Scope: what UI tests cover (§9.6)
- Entry (#entry): one entry point per class
- Placement (#placement): device-only checks
- Finders (#finders): tags over text
- Assertions (#assertions): presence vs visibility
- Actions (#actions): text input semantics
- Sync (#sync): waiters and thread handoff
- Lazy (#lazy): keyed lists
- Restoration (#restoration): save/restore round trip
- Focus tests (#focus-tests): key-driven focus
- KMP shared UI tests (`runComposeUiTest`): common-test runners and locales

UI tests cover critical field-entry flows, submit enable/disable, error visibility, placeholder/content swap, refresh-preserves-content, and accessibility labels on critical controls. Prefer semantic assertions by default; per-platform visual goldens cover high-value screens only.
*Trace: CONTRACT_BRIEF §9.6.*
For composable accessibility mechanics, see the `compose-ui` skill.

## Entry
Use exactly one test entry point per test class. The rule and the suspending lambda each build an independent recomposer, clock, and idling setup, so a second entry fights the first.
*Trace: SKT-01.*

## Placement
Keep screenshot capture, ripple-dependent checks, and accessibility validation on device tests. The host runner drives no RenderThread and only approximates platform services.
*Trace: SKT-09.*

## Finders
Find nodes by production test tag by default. Text finders churn with every copy edit and locale rotation.
*Trace: SKT-17.*
Declare each test tag once as a constant in production and reference it from tests. A duplicated literal drifts from the Notes screen it names.
*Trace: SKT-18.*

## Assertions
Reserve `assertExists` for tree presence and use `assertIsDisplayed` whenever the contract is user visibility.
*Trace: SKT-26.*
Put boolean display predicates inside `waitUntil` blocks and keep throwing assertions outside them. A throwing assert inside the waiter aborts the wait it was meant to poll.
*Trace: SKT-28.*
Choose the at-least-one assertion when emptiness must fail and the every-node assertion when vacuous pass is intended, and pin cardinality with count assertions.
*Trace: SKT-29.*

## Actions
Append through text input and overwrite through text replacement. Chained inputs concatenate at the cursor, so a second field entry appends to the note title instead of replacing it.
*Trace: SKT-32.*

## Sync
Wait on Compose-observable state through the test-clock waiter and reserve the wall-clock waiter for conditions outside the snapshot system.
*Trace: SKT-37.*
Read and mutate outside state through `runOnIdle` by default, switch to `runOnUiThread` under a paused clock, and keep read-only bulk reads in `runWhenIdle` without mutations.
*Trace: SKT-38.*

## Lazy
Tag the lazy container and each Notes item by stable key and scroll by key. Index scrolling breaks the day the list reorders.
*Trace: SKT-46.*
Verify lazy visibility with displayed assertions. Tree presence says nothing about being on screen.
*Trace: SKT-47.*
Read total counts and visible keys from `layoutInfo` inside `runOnIdle` instead of counting composed children. Child enumeration snapshots only the rows composed right now.
*Trace: SKT-48.*

## Restoration
Set content through the restoration tester, which requires a content rule rather than the empty rule. Without it the round trip cannot inject its registry.
*Trace: SKT-49.*
Drive state off its default, persist only saveable state under the bundle cap, and never claim Activity-recreation coverage from this tool.
*Trace: SKT-51.*

## Focus tests
Test focus with one concrete key or directional interaction plus focused semantics, and reserve screenshots for focus appearance only. Direct state mutation proves nothing about the key path the user drives.
*Trace: CB-72.*

## KMP shared UI tests (`runComposeUiTest`)
Run shared Compose UI tests through `runComposeUiTest` on its receiver instead of a JUnit rule.
*Trace: CMP-67.*
Never run common UI tests as Android local unit tests. Run them on JVM or connected-device tasks instead.
*Trace: CMP-70.*
Verify locale behavior per platform: adb locale properties on Android, `XCUITest` launch arguments on iOS, JVM default-locale setting on desktop, browser automation on web.
*Trace: CMP-72.*
Test an unsupported locale for default-resource fallback, plus the simplified/traditional/plain triple for multi-script languages.
*Trace: CMP-73.*
