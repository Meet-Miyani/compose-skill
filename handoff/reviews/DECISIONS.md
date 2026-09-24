# Decisions log (binding)

Owner and moderator decisions that bind every later phase. When this log and an older document
disagree, this log wins. The worker reads it at the start of every phase.

| ID | Date | By | Decision |
|---|---|---|---|
| O-1 | 2026-09-24 | owner | **Koin: annotations are the kit default** (`@KoinViewModel`, `@Module`/`@ComponentScan`, Koin compiler plugin). The owner finds them easier. The Koin DSL is not taught for new code; a project that already uses the DSL consistently keeps it (existing-project policy). Phase 2.6 does not re-audit this choice, only its *setup correctness* against current Koin docs. |
| O-2 | 2026-09-24 | owner | **Drop `inlineUnlessSensitiveAccess` / HTTP 428 escalation from the kit.** It is purely house business logic. The error tiers stay (popup / inline / silent), without the sensitive-access escalation row. |
| O-3 | 2026-09-24 | owner | **Kit scope is the foundation, not the app.** The kit teaches base structure, architecture, problem solving, coding standards, naming conventions and mobile best practice. Any brief decision that exists only because of the house app's business domain (a specific backend contract, business flows, vendor SDKs, brand packs, OTP flows) is **dropped** in Phase 2.6, even if it is correct for the house app. |
| O-4 | 2026-09-24 | owner | **The house app is a candidate, not law** (STANDARDS §1.5 "Evidence over precedent"). Every remaining house decision is audited in Phase 2.6. |
| O-5 | 2026-09-24 | owner | **Bar = Claude Opus 5.5.** Weak models (Muse Spark, DeepSeek, MiniMax) with the kit must match or beat Opus-without-kit on engineering quality, and reach ≥ 90% kit compliance (PLAN "Eval gate"). The M2 Opus reference scored 72%. |
| O-6 | 2026-09-24 | owner | **Fresh-docs rule.** Whenever an agent sets up or writes code against a library, API or SDK from scratch (DataStore, Navigation 3, Room, Ktor, Paging, Koin, Coil, a new SDK), it first reads the **current official docs** (a docs MCP such as Context7 if available, otherwise the official site), checks the project's versions in `libs.versions.toml`, and only then writes code. This is a non-negotiable in every skill (STANDARDS §2.1 item 6). |
| M-1 | 2026-09-24 | moderator | Six task-shaped skills; `compose-project` replaces `compose-module` (owner-approved). |
| M-2 | 2026-09-24 | moderator | External sets are absorbed, not vendored (owner-approved; STANDARDS §7). |
| M-3 | 2026-09-24 | moderator | Evals run over the direct OpenCode Go API (`handoff/tools/run-evals-api.py`), not the OpenCode CLI. |
| M-4 | 2026-09-24 | moderator | **`SavedStateHandle` is allowed** (reverses the house rule): user-entered, not-yet-persisted input survives process death via the multiplatform `androidx.savedstate` / `lifecycle-viewmodel-savedstate` APIs; identity on the nav key, records re-fetched; `UiState` derived from the handle (one owner). Verified: savedstate is KMP from 1.3.0. |
| M-5 | 2026-09-24 | moderator | **Keep two base-class channels** (`effect` + `errors`) as a `[kit]` decision: a generic error channel gives one-line popup wiring per Route without per-feature `ShowError` boilerplate. |
| M-6 | 2026-09-24 | moderator | **Keep `getXStream`** for every `Flow`-returning repository read (`getX` for suspend one-shots) as an unambiguous `[kit]` rule; the NiA `getX(): Flow` divergence is known and intentional. |
| M-7 | 2026-09-24 | moderator | DataStore: Preferences in `commonMain`, structured values as one JSON string key; the false "typed DataStore supported in commonMain" claim is removed. |
| M-8 | 2026-09-24 | moderator | Use `kotlin.time.Instant` (`kotlinx.datetime.Instant` is deprecated). |
| M-9 | 2026-09-24 | moderator | Guards v1 = bash + ripgrep scripts; Konsist/detekt re-evaluated in the later tools/CLI scope. |
