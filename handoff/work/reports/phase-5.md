# Phase 5 report — Guard scripts and their tests

- **Date:** 2026-09-25
- **Worker model:** opencode-go/muse-spark-1.3 (worker session)
- **Session(s):** worker session (OpenCode)
- **Status:** COMPLETE

## Summary

Phase 5 produced deterministic enforcement for the kit: 10 boundary guard scripts, `composekit.conf.example`, a `run-checks.sh` registry with a summary table, an `install-guards.sh` installer, and a fixture-based suite (`scripts/tests/`) in which every check passes on `fixtures/good/` and fails with the expected message on its own `fixtures/bad/<check>/` tree. The full suite (`bash .../tests/run-tests.sh`) is **24 passed, 0 failed under bash 3.2.57(1)-release** — the moderator-verified environment fact (no ripgrep, BSD grep, macOS bash 3.2) — including the load-bearing assertion that the `compose-feature` scaffold (`new-feature.sh --name Tags --item Tag`) passes `run-checks.sh`. All checks print `file:line` messages, exit non-zero on violation, and use `rg` only behind a `command -v rg` fallback to BSD-grep-safe flags. I did not read the private house app in this phase (CONTRACT_BRIEF §11 was the behaviour source, per the phase notes).

## Deliverables

| File | Lines | ~Tokens | Notes |
|---|---|---|---|
| `scripts/composekit.conf.example` | 39 | ~430 | all 8 keys with comments |
| `scripts/check-layering.sh` | 120 | ~1,150 | gradle project() edges + cross-feature imports, both directions |
| `scripts/check-contract-shape.sh` | 98 | ~930 | col-0 declaration scan, exactly-3 + UiState/Action/Effect suffixes |
| `scripts/check-packages.sh` | 67 | ~410 | five-roots path-segment gate over FEATURE_DIRS |
| `scripts/check-data-boundary.sh` | 112 | ~785 | internal DTO/Entity; domain import purity; Instant-not-String |
| `scripts/check-error-handling.sh` | 127 | ~980 | awk: onError lookahead-5, CancellationException rethrow+3, ViewModel wrappers |
| `scripts/check-file-level-state.sh` | 80 | ~620 | col-0 `var` in navigation/presentation files |
| `scripts/check-nav-keys.sh` | 104 | ~1,290 | bare-NavKey implementors; subclassesOfSealed registration; test-exempt |
| `scripts/check-placeholders.sh` | 98 | ~730 | explicit files, else git-diff scope, else full-tree scan; SEAM never matched |
| `scripts/check-locale-parity.sh` | 76 | ~570 | sorted-union key compare; absent dirs skipped; empty conf passes |
| `scripts/check-hardcoded-colors.sh` | 60 | ~390 | `Color(0x` minus DESIGN_SYSTEM_MODULE |
| `scripts/run-checks.sh` | 51 | ~400 | 10-check registry, summary table, exit 1 on any fail |
| `scripts/install-guards.sh` | 46 | ~420 | copies to scripts/composekit/, writes conf if absent, prints CI+hook snippets |
| `scripts/tests/run-tests.sh` | 101 | ~1,000 | 20 good/bad assertions + scaffold-pass + install assertions |
| `scripts/tests/fixtures/good/` (22 files) | — | — | Tags slice + :core:mvi, :data:notes, :app, designsystem, 2 locales |
| `scripts/tests/fixtures/bad/*` (10 dirs, 26 files) | — | — | one failing tree per check |

## Self-checks (paste real output — no output means not run)

`bash skills-v2/compose-architecture/scripts/tests/run-tests.sh` → exit 0:

```
run-tests.sh under bash 3.2.57(1)-release
PASS: check-layering passes on fixtures/good
PASS: check-layering fails on fixtures/bad/check-layering
PASS: check-contract-shape passes on fixtures/good
PASS: check-contract-shape fails on fixtures/bad/check-contract-shape
PASS: check-packages passes on fixtures/good
PASS: check-packages fails on fixtures/bad/check-packages
PASS: check-data-boundary passes on fixtures/good
PASS: check-data-boundary fails on fixtures/bad/check-data-boundary
PASS: check-error-handling passes on fixtures/good
PASS: check-error-handling fails on fixtures/bad/check-error-handling
PASS: check-file-level-state passes on fixtures/good
PASS: check-file-level-state fails on fixtures/bad/check-file-level-state
PASS: check-nav-keys passes on fixtures/good
PASS: check-nav-keys fails on fixtures/bad/check-nav-keys
PASS: check-placeholders passes on fixtures/good
PASS: check-placeholders fails on fixtures/bad/check-placeholders
PASS: check-locale-parity passes on fixtures/good
PASS: check-locale-parity fails on fixtures/bad/check-locale-parity
PASS: check-hardcoded-colors passes on fixtures/good
PASS: check-hardcoded-colors fails on fixtures/bad/check-hardcoded-colors
PASS: new-feature.sh scaffolds Tags/Tag
PASS: run-checks.sh passes on the Tags scaffold
PASS: install-guards.sh installs into a project dir
PASS: installed tree holds run-checks.sh and .composekit.conf

24 passed, 0 failed
```

`bash .../run-checks.sh .../fixtures/good` (summary-table shape) → exit 0:

```
check                    result
check-layering           PASS
check-contract-shape     PASS
check-packages           PASS
check-data-boundary      PASS
check-error-handling     PASS
check-file-level-state   PASS
check-nav-keys           PASS
check-placeholders       PASS
check-locale-parity      PASS
check-hardcoded-colors   PASS

10 passed, 0 failed
```

`bash -n` on all 13 scripts (10 checks + run-checks + install-guards + run-tests) → clean, no output.

`bash handoff/tools/budget.sh skills-v2/compose-architecture` → `RESULT: PASS` (SKILL.md ok 144/3497; the only WARN groups are the Phase-3-accepted ones: version hard floors paired with verify instructions, out-of-kit mentions in migration notes).

`bash handoff/tools/validate-v2.sh skills-v2/compose-architecture` → `Result: PASS with warnings / Quality Score: 90/100 (A) / Errors: 0` (same accepted warnings as Phase 3: skill-root README, license field, agents/openai.yaml, SKILL.md code-example suggestions declined per STANDARDS §3; plus new executable-bit WARNs on fixture/conf data files — fixtures are data run through `bash`, never executed, so no bit is set deliberately).

`bash handoff/tools/ledger-check.sh` → `RESULT: PASS` (Rows 1162, dup-chain problems: none; unlanded rows are all P6–P8 destinations, as in P3/P4 — this phase adds no ledger rows).

`git status --short` → only `?? skills-v2/compose-architecture/scripts/`. Boundary respected: nothing written outside skills-v2/, evals-v2/, handoff/work/.

## STANDARDS §9 checklist

- [x] Every non-negotiable has a reason and *Prevents:* — N/A, no SKILL.md prose touched; guard messages cite the arch/feature rule they enforce.
- [x] Every Red flag names a rule number — N/A, no skill prose touched.
- [x] Every Verification item is a command or a yes/no checkable condition — the suite is 24 command assertions, each with an explicit expected exit + message substring.
- [x] No third-party tutorial code; `budget.sh` passes — PASS (above).
- [x] `validate-v2.sh` scores ≥ 90 for every skill touched — 90/100 for compose-architecture (untouched prose, new scripts only).
- [x] Every rule traces to a harvest-ledger row or to the contract brief — every check traces to CONTRACT_BRIEF §11.x and an approved arch/feature rule number (see Decisions).
- [x] No content duplicated across skills; cross-skill pointers name the skill — scripts cite rule numbers/messages only; no prose copied.
- [x] The Notes/Catalog example domain is used consistently — Tags/Tag fixtures throughout.
- [x] The §2.1 validate-before-answering contract is present — N/A, no skill prose touched (present and unchanged in both approved skills).

## Seed rules → outcome (P3–P8)

Phase 5's "seeds" are the six PLAN task groups; all landed:

| PLAN task | Outcome | Where |
|---|---|---|
| 1. composekit.conf.example (7 keys) | Kept verbatim | `scripts/composekit.conf.example` |
| 2. ten rule-family checks, file:line + non-zero | All 10 written, each with good+bad fixtures | `scripts/check-*.sh` |
| 3. run-checks.sh registry + summary table | Kept; table + `N passed, M failed`, exit 1 on fail | `scripts/run-checks.sh` |
| 4. install-guards.sh (copy, conf-if-absent, CI+hook snippets) | Kept; hook content stays in compose-project P8, snippet printed | `scripts/install-guards.sh` |
| 5. scripts/tests/ (good/bad fixtures, run-tests incl. scaffold-pass) | Kept; 22 good + 26 bad files; scaffold Tags/Tag passes | `scripts/tests/` |
| 6. bash 3.2, rg-with-grep-fallback, no network/writes | Verified: suite runs under 3.2.57 with no rg installed | report output above |

## Decisions I made

- **M-10 enforced (boundaries only).** check-layering covers exactly the PLAN trio (feature→feature, anything→composition-root, core/data→feature); I did not add the brief's data→designsystem edge or any import-shape judgment. No check inspects implementation internals.
- **No size/line-count guard (D1-6).** Brief §13.8 permits a WARN-level size guard, but M-10 (boundaries only) wins: size is not a boundary. No check counts lines. Heuristics stay review triggers.
- **Rule-trace map (check → brief → skill rule):** layering → §11.1 → arch 1–3; contract-shape → F-22/§3.2 → arch 4; packages → §2.1 → arch 11; data-boundary → §5.1–5.3 → arch 12 (+ arch 4 DTO-internal via verification); error-handling → §3.5–3.6 → arch 6; file-level-state → §7.6 → arch 13; nav-keys → §11.2/§7.2 → arch 15; placeholders → feature rule 2 (+ arch stance item 1); locale-parity → §11.4 → feature gate 16; hardcoded-colors → §11.3 → compose-ui token rule (P6 owns the prose; the guard is the boundary).
- **Scaffold-pass compatibility (moderator requirement).** The Tags/Tag scaffold passes because: SEAM is never a placeholder pattern; `launchGuarded(` with next-line `onError` passes the 5-line lookahead; `get<String>` does not match `Result<`; `updatedAt: Instant?` does not match the String-date pattern; top-level `val` serializers and indented `var`s are clean; the sealed NavKey + `subclassesOfSealed` pair is present; absent locale dirs are skipped (the scaffold has no strings.xml and the copied conf's locale paths do not exist under it).
- **Placeholders bad-fixture uses explicit-file mode in run-tests.** Root-only mode follows `git diff --name-only` inside a work tree (per PLAN), which is legitimately empty for untracked fixture files in this clean repo — so the harness asserts the bad tree via `check-placeholders.sh <root> <file>`. The check itself is unchanged.
- **check-nav-keys parse-error claim investigated, no defect found.** The file-level-state worker reported a `case`-inside-`$(…)` parse error in check-nav-keys.sh; I re-read the file in full, ran `bash -n` (clean) and executed it on good (exit 0 silent) and bad (both messages, correct lines) under bash 3.2.57. No fix was needed; the report predates the final draft.
- **Executable bits only on runnable scripts.** The 13 `.sh` runners are +x; fixture `.kt`/`.kts`/`.xml`/`.conf` files are data (invoked via `bash script path`, as run-checks does) and stay non-executable. The validator's executable WARNs on fixtures are accepted noise; the score is unchanged at 90.
- **No external-doc verification needed.** Guards use only POSIX shell/grep/sed/awk/sort/comm/find; no library/API fact is asserted, so O-6 has no target this phase. No URL is recorded.

## Open questions for the moderator

- Confirm the placeholders root-only semantics: tracked-`git-diff`-only inside a work tree (PLAN-literal) vs also scanning untracked files. The current form can pass a brand-new TODO-bearing file in a clean tree when run root-only; run-checks in CI sees committed diffs, which is the designed use.
- Confirm accepting the validator's executable-bit WARNs on fixture data files (leaving them non-executable) vs silencing by chmod.
- Confirm skipping the WARN-level size guard under M-10 is the right call over brief §13.8's "may".

## Disagreements with the plan

- None. One note: PLAN suggests the scaffold test as part of run-tests; I implemented exactly that (Tags/Tag + copied good conf + run-checks → 0), plus an install-guards smoke assertion that the task list implies but does not spell out.

## Out-of-scope observations

- Two 9-line scratch confs from the locale worker's edge-case verification remain at `handoff/work/scratch/lp-empty/.composekit.conf` and `lp-nodirs/.composekit.conf` (git-ignored scratch zone; `rm` is denied to me). Safe to delete.
- The error-handling worker's brace-form trigger (`launchGuarded {` without parens) exceeds the PLAN letter (`launchGuarded` without `onError`) but matches the feature skill's intent; kept, documented in the script header.
- `run-tests.sh` writes its temp scaffold under `handoff/work/scratch/phase5-tmp/` and removes it; verified absent after the green run.

## Fan-out record

- Batch 1 (5 subagents, one turn): check-layering, check-contract-shape, check-packages, check-data-boundary, check-error-handling — each wrote its script plus `fixtures/bad/<check>/` (conf + 1–3 stubs). Batch 2 (5 subagents, one turn): check-file-level-state, check-nav-keys, check-placeholders, check-locale-parity, check-hardcoded-colors — same shape. I own `composekit.conf.example`, `fixtures/good/` (22 files), `run-checks.sh`, `install-guards.sh`, `tests/run-tests.sh`, all reconciliation, self-checks and this report.
- Batch 1 (5 subagents, one turn): check-layering, check-contract-shape, check-packages, check-data-boundary, check-error-handling — each wrote its script plus `fixtures/bad/<check>/` (conf + 1–3 stubs). Batch 2 (5 subagents, one turn): check-file-level-state, check-nav-keys, check-placeholders, check-locale-parity, check-hardcoded-colors — same shape. I own `composekit.conf.example`, `fixtures/good/` (22 files), `run-checks.sh`, `install-guards.sh`, `tests/run-tests.sh`, all reconciliation, self-checks and this report.
- Reconcile changes I made: none to any subagent script (all passed good/bad + `bash -n` as delivered; message substrings matched the harness on first run). Two harness-side fixes of my own: created the scaffold root before invoking `new-feature.sh` (`--root` must exist), and routed the placeholders bad-case through explicit-file mode (git-diff scope is vacuously empty for untracked fixtures). I read all 10 scripts in full before the suite run.

## Review fixes (2026-09-25 — moderator review `handoff/reviews/phase-5.md`, 7 items)

Worker: opencode-go/muse-spark-1.3. No disagreements with any item; every item applied literally. I did not read the private house app; the false-positive shapes were reproduced from the review text as generic Notes fixtures. Environment note: this sandbox permits `bash <path>` invocations only (no bare `/bin/bash` prefix, no `rm`, no `cd &&`), so tests ran as `bash skills-v2/...`, which is `/bin/bash` 3.2.57(1)-release per the suite header. `rg --version` → command not found, so the whole suite ran on the BSD-grep fallback path, matching the moderator's environment.

| Item | What changed | File(s) |
|---|---|---|
| 1. Multi-line `launchGuarded`/`runGuarded` | The awk scan now reads the argument block from the opening `(` to the matching `)` with parentheses balanced across lines (no line limit) and looks for `onError` inside it. A trailing-lambda `launchGuarded {` carries no argument block and always fails. Unknown shapes keep the old 5-line lookahead as a conservative fallback. Header comment updated. | `scripts/check-error-handling.sh` |
| 1 fixtures | Good: `TagsMultilineViewModel.kt` with `onError` on the third line of a multi-line call. Bad: appended `reload()` — a multi-line call without `onError` — to the bad `TagsViewModel.kt` (now 2 `without onError` hits). Depth proof (temporary, reverted): with `onError` pushed 9 lines down, the good tree still passed; the old 5-line window would have flagged it. | `scripts/tests/fixtures/good/.../presentation/tags/TagsMultilineViewModel.kt`, `scripts/tests/fixtures/bad/check-error-handling/.../TagsViewModel.kt` |
| 2. Several design-system directories | New `DESIGN_SYSTEM_DIRS` (space-separated); empty means the `DESIGN_SYSTEM_MODULE` one-item alias. `check-hardcoded-colors.sh` allows `Color(0x…)` in any listed directory. All other scripts gained the `DESIGN_SYSTEM_DIRS=""` conf default for uniformity. | `scripts/check-hardcoded-colors.sh` (+ one-line default in the other 7 conf-parsing scripts) |
| 2 fixture | Good: second brand/theme module `core/brandtheme` with `BrandPalette.kt` holding `Color(0x…)` literals; good conf sets `DESIGN_SYSTEM_DIRS="core/designsystem core/brandtheme"` while keeping `DESIGN_SYSTEM_MODULE` (alias still exercised by the MODULE-only bad confs). | `scripts/tests/fixtures/good/core/brandtheme/.../BrandPalette.kt`, `scripts/tests/fixtures/good/.composekit.conf` |
| 3. Skip test source sets | `check-packages.sh` skips `*/src/*Test*/` before the five-package test. | `scripts/check-packages.sh` |
| 3 fixture | Good: `FakeTagsRepository.kt` in `commonTest` at the feature root package (no five-package segment) — passes. Bad `util/` case in `commonMain` still fails. | `scripts/tests/fixtures/good/feature/tags/src/commonTest/kotlin/com/example/feature/tags/FakeTagsRepository.kt` |
| 4. Per-module locale parity + discovery | `check-locale-parity.sh` rewritten around `compare_dirs <root-label> <dirs…>`: with `LOCALE_DIRS` set it compares exactly those dirs (override, unchanged logic); with it empty it discovers every `src/*/composeResources` and Android `src/*/res` root holding `values*/strings.xml` and compares each root's locales only. Failure message names the locale dir, the resource root (module) and the key, e.g. `string key "tags_retry" missing in …/values-de (resource root feature/tags/src/commonMain/composeResources; present in …/values)`. Stale `keys_*` temp files are cleared per set so multi-root runs cannot pollute the union. | `scripts/check-locale-parity.sh` |
| 4 fixtures | Good conf now `LOCALE_DIRS=""` (discovery); good tree gains a second module `feature/notes` in Android-res shape (`values` + `values-de`) with a different key set (`notes_*` vs `tags_*`), each internally consistent — passes. Bad conf now `LOCALE_DIRS=""`; the inconsistent tags root fails naming module + key. `run-tests.sh` additionally asserts the message names `resource root feature/tags` and `tags_retry`, and proves the override with a scratch tree (consistent `mod-a` pair + undiscoverable-shape broken `feature/broken` root): override passes, discovery on the same tree fails. | `scripts/tests/fixtures/good/feature/notes/src/main/res/values{,-de}/strings.xml`, `scripts/tests/fixtures/good/.composekit.conf`, `scripts/tests/fixtures/bad/check-locale-parity/.composekit.conf`, `scripts/tests/run-tests.sh` |
| 5. `SEAM` blocks done | `check-placeholders.sh` pattern is now `TODO\|FIXME\|NotImplementedError\|SEAM` with `SEAM` token reporting (`placeholder SEAM found; …`). `run-tests.sh` scaffold section rewritten: the 9 non-placeholder checks must pass on the fresh Tags scaffold, `check-placeholders` (explicit-file mode — root-only mode follows `git diff --name-only`, vacuously empty for the untracked scaffold, as documented in the Phase 5 report) must fail with `SEAM`; after stripping the SEAM lines, `run-checks.sh` and explicit-mode `check-placeholders` must pass. | `scripts/check-placeholders.sh`, `scripts/tests/run-tests.sh` |
| 6. Generic example conf | Removed the `feature/tags` locale paths; `DESIGN_SYSTEM_DIRS=""` added with branding/theme docs, `LOCALE_DIRS=""` documented as discovery-by-default with override semantics. | `scripts/composekit.conf.example` |
| 7. Regression fixtures | Covered by the good fixtures above: multi-line `onError` (item 1), second palette module (item 2), `commonTest` fake at feature root (item 3), two-module locale discovery (item 4). All genericized to the Tags/notes example domain; no house names. | (same files as items 1–4) |

### Self-checks after fixes (paste real output — no output means not run)

`bash skills-v2/compose-architecture/scripts/tests/run-tests.sh` → exit 0:

```
run-tests.sh under bash 3.2.57(1)-release
PASS: check-layering passes on fixtures/good
PASS: check-layering fails on fixtures/bad/check-layering
PASS: check-contract-shape passes on fixtures/good
PASS: check-contract-shape fails on fixtures/bad/check-contract-shape
PASS: check-packages passes on fixtures/good
PASS: check-packages fails on fixtures/bad/check-packages
PASS: check-data-boundary passes on fixtures/good
PASS: check-data-boundary fails on fixtures/bad/check-data-boundary
PASS: check-error-handling passes on fixtures/good
PASS: check-error-handling fails on fixtures/bad/check-error-handling
PASS: check-file-level-state passes on fixtures/good
PASS: check-file-level-state fails on fixtures/bad/check-file-level-state
PASS: check-nav-keys passes on fixtures/good
PASS: check-nav-keys fails on fixtures/bad/check-nav-keys
PASS: check-placeholders passes on fixtures/good
PASS: check-placeholders fails on fixtures/bad/check-placeholders
PASS: check-locale-parity passes on fixtures/good
PASS: check-locale-parity fails on fixtures/bad/check-locale-parity
PASS: check-locale-parity names the module
PASS: check-locale-parity names the missing key
PASS: check-locale-parity honors the LOCALE_DIRS override
PASS: check-locale-parity discovers the broken root without the override
PASS: check-hardcoded-colors passes on fixtures/good
PASS: check-hardcoded-colors fails on fixtures/bad/check-hardcoded-colors
PASS: new-feature.sh scaffolds Tags/Tag
PASS: check-layering passes on the fresh scaffold
PASS: check-contract-shape passes on the fresh scaffold
PASS: check-packages passes on the fresh scaffold
PASS: check-data-boundary passes on the fresh scaffold
PASS: check-error-handling passes on the fresh scaffold
PASS: check-file-level-state passes on the fresh scaffold
PASS: check-nav-keys passes on the fresh scaffold
PASS: check-locale-parity passes on the fresh scaffold
PASS: check-hardcoded-colors passes on the fresh scaffold
PASS: check-placeholders fails on the fresh scaffold (SEAMs)
PASS: run-checks.sh passes on the scaffold once SEAMs are implemented
PASS: check-placeholders passes on the scaffold once SEAMs are implemented
PASS: install-guards.sh installs into a project dir
PASS: installed tree holds run-checks.sh and .composekit.conf

39 passed, 0 failed
```

`bash .../run-checks.sh .../fixtures/good` → exit 0: `10 passed, 0 failed` (all 10 checks PASS).

`bash -n` on all 13 scripts (10 checks + run-checks + install-guards + run-tests) → clean, no output.

`bash handoff/tools/budget.sh skills-v2/compose-architecture` → `RESULT: PASS` (same Phase-3-accepted WARN groups only: version hard floors with verify instructions, out-of-kit mentions in migration notes).

`bash handoff/tools/validate-v2.sh skills-v2/compose-architecture` → `Result: PASS with warnings / Quality Score: 90/100 (A) / Errors: 0` (same accepted warnings as Phase 5: skill-root README, license field, agents/openai.yaml, SKILL.md code-example suggestions declined per STANDARDS §3; executable-bit WARNs on fixture/conf data files, now including the 4 new fixture files — still deliberately non-executable data).

`bash handoff/tools/ledger-check.sh` → `RESULT: PASS` (Rows 1162, dup-chain problems: none; unlanded rows are all P6–P8 destinations, as in P3/P4/P5 — these fixes add no ledger rows).

`git status --short` → only `?? handoff/reviews/phase-5.md`, `?? handoff/work/reports/phase-5.md`, `?? skills-v2/compose-architecture/scripts/`. Boundary respected: nothing written outside skills-v2/, evals-v2/, handoff/work/.

### STANDARDS §9 checklist (review fixes)

- [x] Every non-negotiable has a reason and *Prevents:* — N/A, no SKILL.md prose touched.
- [x] Every Red flag names a rule number — N/A, no skill prose touched.
- [x] Every Verification item is a command or a yes/no checkable condition — 39 command assertions, each with expected exit + message substring.
- [x] No third-party tutorial code; `budget.sh` passes — PASS (above).
- [x] `validate-v2.sh` scores ≥ 90 for every skill touched — 90/100 for compose-architecture.
- [x] Every rule traces to a harvest-ledger row or to the contract brief — no new rules; fixes implement review items 1–7 against existing brief §11.x rules.
- [x] No content duplicated across skills; cross-skill pointers name the skill — scripts cite rule numbers/messages only.
- [x] The Notes/Catalog example domain is used consistently — Tags/notes fixtures throughout; no house names.
- [x] The §2.1 validate-before-answering contract is present — N/A, no skill prose touched (unchanged in both approved skills).

### Out-of-scope observations

- `check-packages.sh` skips exactly `*/src/*Test*/` per the review letter. Lowercase JVM `src/test` (and `src/androidTest` is covered — it contains capital `Test`) is not skipped: a fake under `src/test` at the feature root would still fail. Flagging in case the moderator wants the pattern widened; left as specified.
- The two `handoff/work/scratch/lp-empty/.composekit.conf` and `lp-nodirs/.composekit.conf` scratch confs noted in the Phase 5 report are still present (git-ignored scratch zone; `rm` is denied to me). Safe to delete.

## Review fixes, round 2 (2026-09-25 — moderator re-review `handoff/reviews/phase-5.md`, items 8–10)

Worker: opencode-go/muse-spark-1.3. No disagreements with any item; every item applied literally. Items 1–7 were already accepted and are untouched. I did not read the private house app; the four false-positive shapes were reproduced from the re-review text as generic Notes/Tags fixtures. Environment note: tests ran as `bash skills-v2/...` (this sandbox permits `bash <path>` invocations only), which is `/bin/bash` 3.2.57(1)-release per the suite header; `rg` is not installed, so the whole suite ran on the BSD-grep fallback path, matching the moderator's environment.

| Item | What changed | File(s) |
|---|---|---|
| 8. Call-site matching only | The awk scan now requires all of: whole identifier (preceding char not `[A-Za-z0-9_@.]`, next char not `[A-Za-z0-9_]` — excludes `return@launchGuarded`, `x.launchGuarded`, `launchGuardedFoo`); `(`/`{` after optional whitespace on the **same** line (a token at end of line is never a call; the old next-line read and the old 5-line `onError` fallback are removed — anything else is not a call); no `fun ` before the token on its line (the definition); comment lines skipped (first non-blank `//`, `/*`, `*`) and text after `//` truncated before matching. The `(`/`)` balancing and the trailing-lambda `{` rule are unchanged. The `CancellationException` check uses the same `//`-truncated code. Header comment updated. | `scripts/check-error-handling.sh` |
| 9. Skip test source sets | Both `find` loops (`*.kt` scan and `*ViewModel.kt` wrapper scan) prune `*/src/*Test*/*`, the same rule as `check-packages.sh`. | `scripts/check-error-handling.sh` |
| 10. Regression fixtures (all `fixtures/good`, Notes/Tags domain, no house names) | `TagsReturnLabelViewModel.kt`: valid `onError` calls containing `return@launchGuarded` at end of line (followed by `}`) and `return@launchGuarded` inside an `onStart = { … }` argument. `TagsGuardedDocs.kt`: KDoc `*` lines with a `[launchGuarded]` link and a `` `launchGuarded` `` code span. `TagsInlineViewModel.kt`: one-line `launchGuarded(onError = { … }) { … }`. `core/mvi/…/BaseViewModel.kt`: the base definition `fun launchGuarded(onError: …`. `commonTest/…/TagsGuardedTest.kt`: `fun launchGuarded_success_runs()` plus a bare `launchGuarded { }` call (whole file skipped per item 9). | `scripts/tests/fixtures/good/feature/tags/src/commonMain/kotlin/com/example/feature/tags/presentation/tags/TagsReturnLabelViewModel.kt`, `…/TagsGuardedDocs.kt`, `…/TagsInlineViewModel.kt`, `scripts/tests/fixtures/good/core/mvi/src/commonMain/kotlin/com/example/core/mvi/BaseViewModel.kt`, `scripts/tests/fixtures/good/feature/tags/src/commonTest/kotlin/com/example/feature/tags/TagsGuardedTest.kt` |
| 10. Bad fixtures kept | Unchanged: single-line `launchGuarded {`, multi-line `launchGuarded(` without `onError`, swallowed `CancellationException`, `Result<` wrapper — all still fail (verified below). | (no change) `scripts/tests/fixtures/bad/check-error-handling/…/TagsViewModel.kt` |

### Self-checks after round-2 fixes (paste real output — no output means not run)

`bash skills-v2/compose-architecture/scripts/check-error-handling.sh skills-v2/compose-architecture/scripts/tests/fixtures/good` → exit 0, no output (`good-exit=0`).

`bash skills-v2/compose-architecture/scripts/check-error-handling.sh skills-v2/compose-architecture/scripts/tests/fixtures/bad/check-error-handling` → exit 1 (`bad-exit=1`):

```
feature/tags/src/commonMain/kotlin/com/example/feature/tags/presentation/tags/TagsViewModel.kt:27: launchGuarded without onError: pass onError = ... explicitly
feature/tags/src/commonMain/kotlin/com/example/feature/tags/presentation/tags/TagsViewModel.kt:34: launchGuarded without onError: pass onError = ... explicitly
feature/tags/src/commonMain/kotlin/com/example/feature/tags/presentation/tags/TagsViewModel.kt:46: CancellationException caught without rethrow
feature/tags/src/commonMain/kotlin/com/example/feature/tags/presentation/tags/TagsViewModel.kt:52: forbidden wrapper in ViewModel: Result<
```

`bash skills-v2/compose-architecture/scripts/tests/run-tests.sh` → exit 0:

```
run-tests.sh under bash 3.2.57(1)-release
PASS: check-layering passes on fixtures/good
PASS: check-layering fails on fixtures/bad/check-layering
PASS: check-contract-shape passes on fixtures/good
PASS: check-contract-shape fails on fixtures/bad/check-contract-shape
PASS: check-packages passes on fixtures/good
PASS: check-packages fails on fixtures/bad/check-packages
PASS: check-data-boundary passes on fixtures/good
PASS: check-data-boundary fails on fixtures/bad/check-data-boundary
PASS: check-error-handling passes on fixtures/good
PASS: check-error-handling fails on fixtures/bad/check-error-handling
PASS: check-file-level-state passes on fixtures/good
PASS: check-file-level-state fails on fixtures/bad/check-file-level-state
PASS: check-nav-keys passes on fixtures/good
PASS: check-nav-keys fails on fixtures/bad/check-nav-keys
PASS: check-placeholders passes on fixtures/good
PASS: check-placeholders fails on fixtures/bad/check-placeholders
PASS: check-locale-parity passes on fixtures/good
PASS: check-locale-parity fails on fixtures/bad/check-locale-parity
PASS: check-locale-parity names the module
PASS: check-locale-parity names the missing key
PASS: check-locale-parity honors the LOCALE_DIRS override
PASS: check-locale-parity discovers the broken root without the override
PASS: check-hardcoded-colors passes on fixtures/good
PASS: check-hardcoded-colors fails on fixtures/bad/check-hardcoded-colors
PASS: new-feature.sh scaffolds Tags/Tag
PASS: check-layering passes on the fresh scaffold
PASS: check-contract-shape passes on the fresh scaffold
PASS: check-packages passes on the fresh scaffold
PASS: check-data-boundary passes on the fresh scaffold
PASS: check-error-handling passes on the fresh scaffold
PASS: check-file-level-state passes on the fresh scaffold
PASS: check-nav-keys passes on the fresh scaffold
PASS: check-locale-parity passes on the fresh scaffold
PASS: check-hardcoded-colors passes on the fresh scaffold
PASS: check-placeholders fails on the fresh scaffold (SEAMs)
PASS: run-checks.sh passes on the scaffold once SEAMs are implemented
PASS: check-placeholders passes on the scaffold once SEAMs are implemented
PASS: install-guards.sh installs into a project dir
PASS: installed tree holds run-checks.sh and .composekit.conf

39 passed, 0 failed
```

`bash -n` on all 13 scripts (10 checks + run-checks + install-guards + run-tests) → clean (`bash-n-clean`, no output).

### STANDARDS §9 checklist (round-2 fixes)

- [x] Every non-negotiable has a reason and *Prevents:* — N/A, no SKILL.md prose touched.
- [x] Every Red flag names a rule number — N/A, no skill prose touched.
- [x] Every Verification item is a command or a yes/no checkable condition — 39 command assertions, each with expected exit + message substring; round-2 adds no new assertions (the 5 new good fixtures are covered by the existing good-tree assertions).
- [x] No third-party tutorial code; `budget.sh` passes — no prose touched; scripts use only POSIX shell/awk/grep/sort/find (no new commands).
- [x] `validate-v2.sh` scores ≥ 90 for every skill touched — no skill prose touched (round-1 score 90/100 stands; new files are fixture data plus one script edit).
- [x] Every rule traces to a harvest-ledger row or to the contract brief — no new rules; fixes implement re-review items 8–10 against existing brief §11.x rule (arch rule 6).
- [x] No content duplicated across skills; cross-skill pointers name the skill — scripts cite rule numbers/messages only.
- [x] The Notes/Catalog example domain is used consistently — Tags/notes fixtures throughout; no house names.
- [x] The §2.1 validate-before-answering contract is present — N/A, no skill prose touched (unchanged in both approved skills).

### Disagreements with the re-review

- None. One observation: item 8's `fun `-before-token rule is applied literally (any `fun ` earlier on the same line suppresses the hit), so a hypothetical one-liner `fun foo() { launchGuarded { } }` would be missed; such one-liners do not occur in fixtures or the scaffold, and the literal rule matches the moderator's spec. Left as specified.

## Review fixes, round 3 (2026-09-25 — moderator re-review `handoff/reviews/phase-5.md`, item 11)

Worker: opencode-go/muse-spark-1.3. No disagreement; item 11 applied literally. Items 1–10 were already accepted and are untouched. I did not read the private house app; the `BottomSheetScene.kt:127` shape (throw on the fourth line after three comment lines, plus `finally`) was reproduced from the re-review text as a generic Tags fixture. New awk helpers use only `index`/`substr`/`length` (POSIX, BSD-awk safe); no new shell commands. Tests ran as `bash skills-v2/...`, which is `/bin/bash` 3.2.57(1)-release per the suite header; `rg` is not installed, so the suite ran on the BSD-grep fallback path.

| Item | What changed | File(s) |
|---|---|---|
| 11. Whole catch-block read | Check (b) now: extracts the caught name from `catch (<name>: CancellationException)` (whole-word `catch`, text between `(` and `:`, last whitespace-separated token); finds the block's opening `{` from the `catch` position and reads to the matching `}` with braces balanced across lines (nested `updateState { … }` handled); skips comment lines (first non-blank `//`, `/*`, `*`) and `//` tails for both brace counting and the throw search; passes when a non-comment line holds whole-word `throw` plus whole-word `<name>` or `CancellationException`. No opening brace found is a conservative fail. Header comment updated (also removed the duplicated (b)/(c) lines). | `scripts/check-error-handling.sh` |
| 11 fixtures | Good `TagsRethrowViewModel.kt`: `catch (cancellation: CancellationException)` with three `//` comment lines, then `throw cancellation`, then a `finally` block (throw sits at catch+4, outside the old 3-line window, so the fixture is load-bearing). Bad: appended `loadTitlesOrEmpty()` to the bad `TagsViewModel.kt` — a 7-line catch block (comment + three state updates + return, no rethrow) that fails; the pre-existing 4-line swallowed catch still fails. | `scripts/tests/fixtures/good/feature/tags/src/commonMain/kotlin/com/example/feature/tags/presentation/tags/TagsRethrowViewModel.kt`, `scripts/tests/fixtures/bad/check-error-handling/feature/tags/src/commonMain/kotlin/com/example/feature/tags/presentation/tags/TagsViewModel.kt` |

### Self-checks after round-3 fixes (paste real output — no output means not run)

`bash skills-v2/compose-architecture/scripts/check-error-handling.sh skills-v2/compose-architecture/scripts/tests/fixtures/good` → exit 0, no output (`good-exit=0`).

`bash skills-v2/compose-architecture/scripts/check-error-handling.sh skills-v2/compose-architecture/scripts/tests/fixtures/bad/check-error-handling` → exit 1 (`bad-exit=1`):

```
feature/tags/src/commonMain/kotlin/com/example/feature/tags/presentation/tags/TagsViewModel.kt:27: launchGuarded without onError: pass onError = ... explicitly
feature/tags/src/commonMain/kotlin/com/example/feature/tags/presentation/tags/TagsViewModel.kt:34: launchGuarded without onError: pass onError = ... explicitly
feature/tags/src/commonMain/kotlin/com/example/feature/tags/presentation/tags/TagsViewModel.kt:46: CancellationException caught without rethrow
feature/tags/src/commonMain/kotlin/com/example/feature/tags/presentation/tags/TagsViewModel.kt:59: CancellationException caught without rethrow
feature/tags/src/commonMain/kotlin/com/example/feature/tags/presentation/tags/TagsViewModel.kt:52: forbidden wrapper in ViewModel: Result<
```

`bash skills-v2/compose-architecture/scripts/tests/run-tests.sh` → exit 0 (`suite-exit=0`):

```
run-tests.sh under bash 3.2.57(1)-release
PASS: check-layering passes on fixtures/good
PASS: check-layering fails on fixtures/bad/check-layering
PASS: check-contract-shape passes on fixtures/good
PASS: check-contract-shape fails on fixtures/bad/check-contract-shape
PASS: check-packages passes on fixtures/good
PASS: check-packages fails on fixtures/bad/check-packages
PASS: check-data-boundary passes on fixtures/good
PASS: check-data-boundary fails on fixtures/bad/check-data-boundary
PASS: check-error-handling passes on fixtures/good
PASS: check-error-handling fails on fixtures/bad/check-error-handling
PASS: check-file-level-state passes on fixtures/good
PASS: check-file-level-state fails on fixtures/bad/check-file-level-state
PASS: check-nav-keys passes on fixtures/good
PASS: check-nav-keys fails on fixtures/bad/check-nav-keys
PASS: check-placeholders passes on fixtures/good
PASS: check-placeholders fails on fixtures/bad/check-placeholders
PASS: check-locale-parity passes on fixtures/good
PASS: check-locale-parity fails on fixtures/bad/check-locale-parity
PASS: check-locale-parity names the module
PASS: check-locale-parity names the missing key
PASS: check-locale-parity honors the LOCALE_DIRS override
PASS: check-locale-parity discovers the broken root without the override
PASS: check-hardcoded-colors passes on fixtures/good
PASS: check-hardcoded-colors fails on fixtures/bad/check-hardcoded-colors
PASS: new-feature.sh scaffolds Tags/Tag
PASS: check-layering passes on the fresh scaffold
PASS: check-contract-shape passes on the fresh scaffold
PASS: check-packages passes on the fresh scaffold
PASS: check-data-boundary passes on the fresh scaffold
PASS: check-error-handling passes on the fresh scaffold
PASS: check-file-level-state passes on the fresh scaffold
PASS: check-nav-keys passes on the fresh scaffold
PASS: check-locale-parity passes on the fresh scaffold
PASS: check-hardcoded-colors passes on the fresh scaffold
PASS: check-placeholders fails on the fresh scaffold (SEAMs)
PASS: run-checks.sh passes on the scaffold once SEAMs are implemented
PASS: check-placeholders passes on the scaffold once SEAMs are implemented
PASS: install-guards.sh installs into a project dir
PASS: installed tree holds run-checks.sh and .composekit.conf

39 passed, 0 failed
```

`bash -n` on all 13 scripts (10 checks + run-checks + install-guards + run-tests) → clean (`bash-n-done`; each file printed `OK: <path>`).

### STANDARDS §9 checklist (round-3 fixes)

- [x] Every non-negotiable has a reason and *Prevents:* — N/A, no SKILL.md prose touched.
- [x] Every Red flag names a rule number — N/A, no skill prose touched.
- [x] Every Verification item is a command or a yes/no checkable condition — existing 39 command assertions cover the new fixtures (good tree passes, bad tree fails); no new assertions added, none needed.
- [x] No third-party tutorial code; `budget.sh` passes — no prose touched; only POSIX shell/awk/index-substr logic.
- [x] `validate-v2.sh` scores ≥ 90 for every skill touched — no skill prose touched (round-1 score 90/100 stands; new files are one fixture plus edits to one script and one bad fixture).
- [x] Every rule traces to a harvest-ledger row or to the contract brief — no new rules; fix implements re-review item 11 against existing brief §11.x rule (arch rule 6).
- [x] No content duplicated across skills; cross-skill pointers name the skill — scripts cite rule numbers/messages only.
- [x] The Notes/Catalog example domain is used consistently — Tags fixtures throughout; no house names.
- [x] The §2.1 validate-before-answering contract is present — N/A, no skill prose touched (unchanged in both approved skills).

### Disagreements with the round-3 review

- None.

## Review fixes, round 4 (2026-09-25 — moderator re-review `handoff/reviews/phase-5.md`, item 12)

Worker: opencode-go/muse-spark-1.3. No disagreement; item 12 applied literally. Items 1–11 were already accepted and are untouched. I did not read the private house app; the `DefaultSupportChat.kt:113` shape (`try { withTimeout(ms) { block() } } catch (_: TimeoutCancellationException) { throw DomainException(...) }`) was reproduced from the re-review text as a generic Tags fixture. The fix reuses the existing POSIX `hasword` awk helper (`index`/`substr`/`length` only, BSD-awk safe); no new shell commands. Tests ran as `bash skills-v2/...` — the sandbox denies a bare `/bin/bash` prefix (documented in round 1–3), and `bash` is `/bin/bash` 3.2.57(1)-release per the suite header; `rg` is not installed, so the suite ran on the BSD-grep fallback path, matching the moderator's environment.

| Item | What changed | File(s) |
|---|---|---|
| 12. Whole-name catch-type match | Check (b) now fires only when `CancellationException` occurs as a whole name: the `catch`-line gate changed from substring `index(code, "CancellationException") > 0` to `hasword(code, "CancellationException") == 1` (char before the name is not `[A-Za-z0-9_]`, char after is not `[A-Za-z0-9_]`). A qualified `kotlinx.coroutines.CancellationException` still fires (preceding `.` is not a word char); `TimeoutCancellationException` never fires (preceding `t` is a word char). The rethrow search inside the block is unchanged. Header comment updated. | `scripts/check-error-handling.sh` |
| 12 fixture (good) | New `TagsTimeoutViewModel.kt`: `try { withTimeout(5_000) { repository.getTagTitles() } } catch (_: TimeoutCancellationException) { throw TagsTimeoutException() }`. Passes (no fire on the subtype). Load-bearing: under the old substring gate this file would fail — the block holds no `throw cancellation`/`CancellationException`, only `throw TagsTimeoutException()`. Genericized to the Tags example domain; no house names. | `scripts/tests/fixtures/good/feature/tags/src/commonMain/kotlin/com/example/feature/tags/presentation/tags/TagsTimeoutViewModel.kt` |
| 12 bad fixtures kept | Unchanged: both swallowed-`CancellationException` catches (4-line and 7-line blocks) still fail, as do both `without onError` hits and the `Result<` wrapper (verified below). | (no change) `scripts/tests/fixtures/bad/check-error-handling/…/TagsViewModel.kt` |

### Self-checks after round-4 fixes (paste real output — no output means not run)

`bash skills-v2/compose-architecture/scripts/check-error-handling.sh skills-v2/compose-architecture/scripts/tests/fixtures/good` → exit 0, no output (`good-exit=0`).

`bash skills-v2/compose-architecture/scripts/check-error-handling.sh skills-v2/compose-architecture/scripts/tests/fixtures/bad/check-error-handling` → exit 1 (`bad-exit=1`):

```
feature/tags/src/commonMain/kotlin/com/example/feature/tags/presentation/tags/TagsViewModel.kt:27: launchGuarded without onError: pass onError = ... explicitly
feature/tags/src/commonMain/kotlin/com/example/feature/tags/presentation/tags/TagsViewModel.kt:34: launchGuarded without onError: pass onError = ... explicitly
feature/tags/src/commonMain/kotlin/com/example/feature/tags/presentation/tags/TagsViewModel.kt:46: CancellationException caught without rethrow
feature/tags/src/commonMain/kotlin/com/example/feature/tags/presentation/tags/TagsViewModel.kt:59: CancellationException caught without rethrow
feature/tags/src/commonMain/kotlin/com/example/feature/tags/presentation/tags/TagsViewModel.kt:52: forbidden wrapper in ViewModel: Result<
```

`bash skills-v2/compose-architecture/scripts/tests/run-tests.sh` → exit 0 (`suite-exit=0`):

```
run-tests.sh under bash 3.2.57(1)-release
PASS: check-layering passes on fixtures/good
PASS: check-layering fails on fixtures/bad/check-layering
PASS: check-contract-shape passes on fixtures/good
PASS: check-contract-shape fails on fixtures/bad/check-contract-shape
PASS: check-packages passes on fixtures/good
PASS: check-packages fails on fixtures/bad/check-packages
PASS: check-data-boundary passes on fixtures/good
PASS: check-data-boundary fails on fixtures/bad/check-data-boundary
PASS: check-error-handling passes on fixtures/good
PASS: check-error-handling fails on fixtures/bad/check-error-handling
PASS: check-file-level-state passes on fixtures/good
PASS: check-file-level-state fails on fixtures/bad/check-file-level-state
PASS: check-nav-keys passes on fixtures/good
PASS: check-nav-keys fails on fixtures/bad/check-nav-keys
PASS: check-placeholders passes on fixtures/good
PASS: check-placeholders fails on fixtures/bad/check-placeholders
PASS: check-locale-parity passes on fixtures/good
PASS: check-locale-parity fails on fixtures/bad/check-locale-parity
PASS: check-locale-parity names the module
PASS: check-locale-parity names the missing key
PASS: check-locale-parity honors the LOCALE_DIRS override
PASS: check-locale-parity discovers the broken root without the override
PASS: check-hardcoded-colors passes on fixtures/good
PASS: check-hardcoded-colors fails on fixtures/bad/check-hardcoded-colors
PASS: new-feature.sh scaffolds Tags/Tag
PASS: check-layering passes on the fresh scaffold
PASS: check-contract-shape passes on the fresh scaffold
PASS: check-packages passes on the fresh scaffold
PASS: check-data-boundary passes on the fresh scaffold
PASS: check-error-handling passes on the fresh scaffold
PASS: check-file-level-state passes on the fresh scaffold
PASS: check-nav-keys passes on the fresh scaffold
PASS: check-locale-parity passes on the fresh scaffold
PASS: check-hardcoded-colors passes on the fresh scaffold
PASS: check-placeholders fails on the fresh scaffold (SEAMs)
PASS: run-checks.sh passes on the scaffold once SEAMs are implemented
PASS: check-placeholders passes on the scaffold once SEAMs are implemented
PASS: install-guards.sh installs into a project dir
PASS: installed tree holds run-checks.sh and .composekit.conf

39 passed, 0 failed
```

`bash -n` on all 13 scripts (10 checks + run-checks + install-guards + run-tests) → clean (each file printed `OK: <path>`).

### STANDARDS §9 checklist (round-4 fixes)

- [x] Every non-negotiable has a reason and *Prevents:* — N/A, no SKILL.md prose touched.
- [x] Every Red flag names a rule number — N/A, no skill prose touched.
- [x] Every Verification item is a command or a yes/no checkable condition — existing 39 command assertions cover the new fixture (good tree passes, bad tree fails); no new assertions added, none needed.
- [x] No third-party tutorial code; `budget.sh` passes — no prose touched; only the existing POSIX awk helper reused.
- [x] `validate-v2.sh` scores ≥ 90 for every skill touched — no skill prose touched (round-1 score 90/100 stands; new files are one fixture plus a two-line edit to one script).
- [x] Every rule traces to a harvest-ledger row or to the contract brief — no new rules; fix implements re-review item 12 against existing brief §11.x rule (arch rule 6).
- [x] No content duplicated across skills; cross-skill pointers name the skill — scripts cite rule numbers/messages only.
- [x] The Notes/Catalog example domain is used consistently — Tags fixtures throughout; no house names.
- [x] The §2.1 validate-before-answering contract is present — N/A, no skill prose touched (unchanged in both approved skills).

### Disagreements with the round-4 review

- None.
