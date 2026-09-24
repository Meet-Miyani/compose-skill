# Review — Phase 2.6 decision audit (2026-09-24)

**Verdict:** CHANGES REQUIRED — apply the rulings below to the brief and the evals.

This is a good audit, not a rubber stamp.

- Each of the 105 decision rows carries live evidence.
- Six research notes back it.
- It found four real problems:
  - the unsupported `errors` channel
  - the officially contradicted "no `SavedStateHandle`" rule
  - the house-only `getXStream` suffix
  - the deprecated `kotlinx.datetime.Instant`
- Carry-over D2.5-1 is closed: zero dup chains, and `dest-load.py` exits 0.

The high KEEP count (96) reflects that the core structure is standard (layering, UDF, feature
modules, fakes, Nav 3 keys), not deference to the house. The two OPEN rows and one SIMPLIFY are
ruled below.

## Tool results (moderator re-run)

```
ledger-check.sh → RESULT: PASS; dup chains: none
dest-load.py → exit 0
git status → HARVEST_LEDGER.md (chains), DECISION_AUDIT.md, audit-notes/, report — boundary respected
Brief unchanged in this phase → confirmed
Moderator verification (fresh-docs rule O-6): androidx.savedstate is Kotlin Multiplatform since
  1.3.0; lifecycle-viewmodel-savedstate is usable from commonMain; the `saved` delegate works with
  kotlinx.serialization (developer.android.com/jetpack/androidx/releases/savedstate;
  developer.android.com/topic/libraries/architecture/viewmodel/viewmodel-savedstate)
```

## Moderator rulings (binding; recorded in DECISIONS.md as M-4 … M-9)

- **M-4 (§3.7, `SavedStateHandle`) — REVERSE the house rule.**
  - What survives process death, and how:
    - Identity stays on the nav key, and records are re-fetched by identity (unchanged).
    - **User-entered state that is not yet persisted** (form drafts, typed text, a chosen filter or
      step) lives in the ViewModel's `SavedStateHandle`, via the multiplatform `androidx.savedstate`
      / `lifecycle-viewmodel-savedstate` APIs (`saved` delegate or `getStateFlow`, kotlinx.serialization
      for structured values).
    - `UiState` is *derived* from the handle for those fields. That is one owner, not a mirror, so
      the one-owner/no-mirror rule stands.
  - The phrase "typed input does not survive process death by design" is removed from the kit.
  - Phase 3 must verify, per O-6, the artifact versions and how Koin annotations inject a
    `SavedStateHandle` into a `@KoinViewModel` in `commonMain`, and cite the pages.
  - *Why:* official docs name text input as the canonical saved-state content. The ladder's rung 1
    (the platform API) holds and is now multiplatform. A per-screen UX defect that no guard can
    catch is worse than the constructor plumbing.
- **M-5 (§3.4, the `errors` channel) — KEEP the two channels, as a `[kit]` decision.**
  - `effect: Flow<Effect>` carries feature-specific one-shots.
  - `errors: Flow<AppError>` carries popup-tier errors.
  - *Why the ladder does not collapse them:*
    - `Effect` is each feature's own sealed type, so a base-class error cannot live inside it.
    - Collapsing would force every feature to declare and forward its own `ShowError` variant.
      That is per-feature boilerplate a mid-tier model forgets, and M2 showed models dropping
      error wiring.
    - The separate generic channel makes popup wiring one line at every Route
      (`HandleAppErrors(viewModel.errors)`).
  - The brief records the rationale and the risk: `trySend` fails only on a closed channel (the
    buffer is 64). The kit also states "effects and errors are for one-shots; anything the user must
    still see after returning is state".
- **M-6 (§2.4, repository read naming) — KEEP `getXStream` as a `[kit]` rule. The SIMPLIFY is
  rejected.**
  - The proposed rule (use `Stream` only when a one-shot coexists) needs judgment, and it forces a
    rename the day a one-shot is added.
  - A weak model applies "every `Flow`-returning repository read ends in `Stream`; suspend one-shots
    are `getX`" without error.
  - The NiA naming is a sample convention, not official guidance. Record the NiA divergence in the
    brief as known and intentional.
- **M-7 (§13.3, DataStore) — ACCEPT the audit's fixes.**
  - Delete the false "typed DataStore is supported in `commonMain`" sentence (D1-9).
  - The official KMP guide supports Preferences DataStore. The kit stores structured values as one
    JSON string key.
  - The `java.io.tmpdir` ban is re-tagged `[kit]` hardening.
- **M-8 (§5.1, §8.2, `Instant`) — ACCEPT.** Name `kotlin.time.Instant` as the type;
  `kotlinx.datetime.Instant` is deprecated. Phase 7 re-verifies the minimum Kotlin and
  kotlinx-datetime versions per O-6.
- **M-9 (guards) — ACCEPT bash + ripgrep as the kit's single guard implementation for v1.**
  - Konsist and detekt are rejected for v1 on the audit's KMP evidence: a dedicated-module rerun
    cost, and syntax-only `commonMain` analysis.
  - Re-evaluated in the later tools/CLI scope.
- **All other rows:** the recommendations are accepted as written. That covers the 96 KEEPs, with
  their "owed sentences" (for example §8.3: streams-first scope, keying `LifecycleStartEffect` by
  nav-key id, the skip-vs-cancel rationale, `launchGuarded` returning its `Job`), and the 4 DROPs
  (O-2 escalation cluster, §4.1 enum entry, §4.2 storage subtype, §5.1 money sentences).

## Required changes (review-fix pass)

1. **Apply every ruling to `CONTRACT_BRIEF.md`:**
   - M-4 through M-9
   - all DROPs, deleting each location your audit lists
   - every KEEP-with-wording-fix and owed sentence
   Tag each changed rule with its ruling ID (e.g. `[kit, M-4]`) and update the provenance counts.
2. **Apply the eval impact:**
   - ARCH-03 item 3 (the dropped escalation) → remove it, or rewrite it to "inline tier without
     escalation".
   - Move the DATA-03 #3/#4 citations to their new sections.
   - Re-check the ARCH-03 #7 and UI-01 #6 citations after M-5.
   - **Add** rubric rows for M-4:
     - FEAT-01: "typed editor input survives process-death restore via `SavedStateHandle`; the
       record is re-fetched by identity"
     - UI-04: an explicit check that the refusal is not answered with a `rememberSaveable` mirror
   - Keep `evals.json` in step.
   - Record in the report every M2 "no model passed" item that disappears with a dropped rule, so
     later gates do not count it.
3. **Re-run** `ledger-check.sh`, `dest-load.py` and the JSON parse checks. Confirm with a grep that
   the brief no longer contains `inlineUnlessSensitiveAccess`, `SensitiveAccess`, "by design"
   (process death) or `kotlinx.datetime.Instant`.

---

# Re-review — Phase 2.6 review fixes (2026-09-24)

**Verdict:** APPROVED

```
First fix run stalled for 65 min at 0 bytes: a stray moderator debug `opencode serve` held the shared
  DB. The server and the stalled run were killed and relaunched as a fresh session, which completed
  (moderator fault, see memory).
Brief: inlineUnlessSensitiveAccess 0 · SensitiveAccess 0 · kotlinx.datetime.Instant 0 · "by design" 0 ·
  M-4/M-5/M-6 tags present · kotlin.time.Instant present · §3.7 carries the M-4 SavedStateHandle rule
  with the official citation
Evals: ARCH-03 #3 → inline tier without escalation; FEAT-01 #8 → typed input survives process death
  via SavedStateHandle; UI-04 #7 → no rememberSaveable mirror; evals.json and triggers.json parse
ledger-check.sh PASS · dest-load.py exit 0 · no opencode processes left running
```

The brief is now the audited source of truth for Phases 3–8. Phase 3 must verify, per O-6, the
savedstate / lifecycle-viewmodel-savedstate versions and how Koin annotations inject a
`SavedStateHandle` in `commonMain` (M-4).
