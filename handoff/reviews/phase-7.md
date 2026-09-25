# Review: Phase 7, `compose-data` (2026-09-25)

**Verdict:** CHANGES REQUIRED (two technical blockers). The eval gate passes for DeepSeek and Muse.

## Moderator verification

```
budget.sh PASS (compose-data SKILL.md 3,143 tokens; references 1,272–2,367; code share 0–6%)
validate-v2.sh compose-data 90/100 · ledger-check PASS · dest-load 0 over cap · guard suite 54/54
M-11 linked, not restated · M-12 labels on every rule · D1-9 correct (Preferences only in KMP)
```

## Eval gate: `handoff/work/scratch/gate-p7` (DATA-01..04, blind Sonnet graders, 5 answers per packet)

| Model | Rubric (DATA-02#7 excluded, item 5) | Quality | Pressure | Invented APIs |
|---|---|---|---|---|
| DeepSeek V4.1 Flash + kit | 26/26 (**100%**) | **7.75** | held | 0 |
| Muse Spark 1.3 + kit | 24/26 (**92%**) | **7.5** | held | 0 |
| MiniMax M3 + kit | 23/26 (88%) | 6.5 | held | 0 |
| MiniMax M3, no kit | 10/26 (38%) | 3.5 | held | 0 |
| Opus 5.5, no kit | 18/26 (69%) | 7.25 | **folded** | 0 |

- DeepSeek and Muse pass every gate condition and beat Opus on rubric and quality.
- MiniMax rises from 38% to 88%, one item short of the bar, and is recorded as residual D7-1.
- The kit-loaded models all implemented. The only "asked for context instead" answer was MiniMax
  **without** the kit, so the Phase 6 stall fix holds.

## Required changes

1. **BLOCKER: `sendWithoutRequest` is backwards** (`references/auth-and-realtime.md:8,26`).
   - The fetched Ktor page (https://ktor.io/docs/client-bearer-auth.html) says the callback "determines
     whether the client should attach credentials before sending the request". Returning **true**
     sends the token proactively.
   - The skill says to return true to *exempt* login/register. A model copying this attaches a stale
     token to sign-in.
   - Rewrite: login, register and the refresh call use a client instance **without** the Auth plugin,
     or an isolated unauthenticated client (rule 6's option). `sendWithoutRequest` controls only
     proactive versus after-401 attachment, never exemption. The refresh request is marked with
     `markAsRefreshTokenRequest()`, which is on the same page.
   - Fix the red-flag row too.
2. **BLOCKER: `SharedPreferencesMigration` is Android-only** (`references/datastore.md:25`, rule 12).
   - It takes `Context` / `android.content.SharedPreferences`
     (https://developer.android.com/reference/kotlin/androidx/datastore/migrations/SharedPreferencesMigration).
   - State that it lives in `androidMain`, and that it is passed into the `commonMain` factory through
     the platform-provided migrations list. This matches SKILL.md rule 9 ("say the platform next to
     every Android-only data API").
3. **`references/networking-ktor.md:9`: "install `HttpRequestRetry` before `HttpTimeout`"** has no
   source. Verify it against a fetched Ktor page or the Ktor source, and cite it. If you cannot, cut
   the ordering claim and keep only "retry covers timeouts only when configured to", verified.
4. **`references/paging.md:12` version gate:** split it by target. 3.3.0-alpha01 covers Android/JVM
   only; a project targeting iOS/macOS/Linux needs 3.3.0-alpha02 or later. Name the first stable 3.3.x
   release from the release page, and prefer it as the gate for production code.
5. **Evals, DATA-02 item 7** ("disambiguated filtered streams") failed for all five answers: the task
   asks for no filtered aggregate. Either rewrite it conditionally ("if the answer adds a filtered
   stream, its name disambiguates it, e.g. `getArchivedNotesStream`") or add the filtered read to the
   task. Keep `scenarios.md` and `evals.json` in sync.
6. **`references/room.md:14` (rule 3):** give it a reason and a *Prevents:* line, or fold it into rule 2.
7. **`references/auth-and-realtime.md:9`:** the "(verified: URL)" tag on "return null from
   `refreshTokens` on failure" overstates what the page shows. Cite the Ktor source or KDoc that
   states the null contract, or reword the citation to what the page does say.

## Residual

- **D7-1:** MiniMax M3 on data scenarios is at 88% (from 38%), with quality 6.5 against Opus's 7.25.
  Re-measured at M9.

Re-run `budget.sh`, `validate-v2.sh skills-v2/compose-data`, `ledger-check.sh`, `dest-load.py` and the
guard suite. The fixes touch facts the gate scenarios do not exercise. The moderator verifies them
directly and does not re-gate unless a rule a scenario depends on changes.

---

# Re-review: Phase 7 fixes (2026-09-25)

**Verdict:** APPROVED, with residual D7-1.

The moderator verified every fix:

1. **`sendWithoutRequest`:** rewritten correctly. Login, register and refresh run on a client without
   Auth; `sendWithoutRequest` is described as proactive-versus-after-401 only; the refresh call is
   marked with `markAsRefreshTokenRequest()`. The red flag is fixed.
2. **`SharedPreferencesMigration`:** labeled Android-only, in `androidMain`.
3. **HttpRequestRetry-before-HttpTimeout:** kept, and verified by the moderator on the fetched page
   https://ktor.io/docs/client-request-retry.html: "If the `HttpTimeout` plugin is installed,
   `HttpRequestRetry` should be installed first to allow configuring retries for timeouts."
4. **Paging gate:** concrete. It requires 3.3.0 stable, and explains alpha01 (Android/JVM) and alpha02
   (iOS/macOS/Linux).
5. **DATA-02 #7:** rewritten conditionally ("where the answer adds a filtered stream …; no filtered
   stream is required"). `scenarios.md` and `evals.json` are in sync.
6. **Room rule 3** has its reason and a *Prevents:* line.
7. **The `refreshTokens` citation** is reworded.

Self-checks: budget PASS, validate 90/100, ledger PASS, dest-load 0 over cap, guard suite 54/54,
evals.json parses.

The fixes do not change any rule a gate scenario depends on, so the gate stands: DeepSeek 100%,
Muse 92%, MiniMax 88%, against Opus at 69%.
