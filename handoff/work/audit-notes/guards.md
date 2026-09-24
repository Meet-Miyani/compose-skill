# Guard-implementation decision — audit note

Scope: brief §11.1–§11.16 (guard inventory) and §12.2 (guards not wired
into CI/hooks). Candidates: (A) bash + ripgrep/grep text-search scripts
with a `run-checks.sh` registry (house approach), (B) Konsist,
(C) detekt custom rules. Ten Phase 5 checks: module direction, DTO/entity
visibility + domain-framework imports, Contract.kt exactly-three-types,
feature package roots, launchGuarded onError presence, file-level mutable
state, NavKey sealed-hierarchy registration, TODO placeholders, locale
parity, hardcoded colors.

Ledger note: EXTERNAL_LEDGER rows SKY-29–SKY-35 cover Compose-stability
baselines in CI, SMP-67/SMP-68 the KMP CI target matrix. None specifies a
guard implementation; they bear on this decision only as cost context
(gates must run inside the SMP-67/68 matrix, baselines show the
commit-the-gate-default shape of SKY-30).

## A. bash + ripgrep text search (house: check-layering.sh etc.)

Accuracy: catches all lexical checks — import bans (`*Dto` outside
`data/`), `Color(0x` / `Color.White`, `println`, `TODO`, file-level
`private var`, `implementation(projects.feature.x)`. Misses what needs
parsing. Concrete miss: `typealias NoteDto = …` evades a
`class .*Dto must be internal` regex. Concrete false positive: the string
literal `"fix TODO later"` in a test fixture trips a bare `rg TODO`.
House proof text search alone was insufficient: check-nav-keys.sh grew a
bracket-aware Python scan (brief §11.2) because grep cannot match
`data class X(\n) : NotesNavKey` across lines. Silent-tier audit
(`onError = {}`) flags legitimate polls too — needs human judgment.
Locale parity and TODO remain script-shaped under any candidate.

Setup cost: zero dependencies beyond bash + rg (+ python3 for the one
bracket scan). No Gradle, no JVM, no Kotlin-version coupling. No KMP
caveat exists — it reads source text, so `commonMain` needs no special
task.

Usability: `rg -n` prints `file:line`; the weak model runs one command,
reads the line, fixes, reruns. Failure surface is a regex, debuggable
without build knowledge.

CI/hooks: one shell step, sub-second (rg scans the kernel tree in
~0.08s per its README benchmarks). Registry pattern already specified
(brief §11.14). Agent-hook cost trivial: run `run-checks.sh` on change.

## B. Konsist (Kotlin structural tests, JUnit4/5/Kotest)

Accuracy: AST-aware declaration + architecture checks (`scopeFromProject`,
`Layer(..).dependsOn/doesNotDependOn`, file filtering). Catches what text
misses: commented-out code ignored, multiline supertypes, `typealias`
leaks, exact top-level-declaration counts for Contract.kt. Gaps: locale
parity is XML resources — Konsist scans Kotlin declarations only, so a
script is still required; comment/TODO inspection via the declaration API
was not verified on the pages fetched (open question below).

Setup cost: one test dependency (`com.lemonappdev:konsist:0.17.3`).
KMP caveat VERIFIED: KMP projects must use a dedicated `konsistTest`
module, and Gradle skips it as up-to-date unless `outputs.upToDateWhen
{ false }` or a `konsistCheck` wrapper passes `--rerun-tasks` (forces full
rerun, no incrementality). Also needs JVM + Gradle to execute at all, and
Konsist tracks recent Kotlin releases (version-skew risk per its release
notes).

Usability: per-declaration failures name the offending declaration — good
output. But the weak model must run Gradle (minutes, version-sensitive)
and read assertion traces instead of `file:line` from a sub-second
script. More setup to break.

CI/hooks: JVM job per matrix leg; cannot run as a synchronous
edit-hook; `--rerun-tasks` workaround reruns everything every time.

## C. detekt custom rules (PSI visitors + RuleSetProvider)

Accuracy: full PSI (`visitKtFile`, `visitNamedFunction`…); the only
candidate that could do type-aware checks. But none of the ten checks
needs types, and the KMP caveat VERIFIED on the official type-resolution
page: source-set tasks (`detektCommonMainSourceSet`) run WITHOUT type
resolution; type-resolution tasks exist only for JVM/Android compilations
(`detektMainJvm`); Native/JS/Wasm get syntax-only analysis. Our kit is
CMP with `commonMain` — custom rules would run syntax-only on exactly the
code they guard. Syntax-only custom rules compete with A/B at far higher
authoring cost (PSI knowledge).

Setup cost (highest): separate pure-Kotlin rules module, `Rule` subclass
+ `RuleSetProvider` + `META-INF/services` registration, `detektPlugins`
wiring with `assemble` ordering, per-rule activation in `detekt.yml`
(rules are disabled by default — documented pitfall), version alignment
across Gradle/KGP/AGP (official compatibility table pins e.g. Kotlin
2.4.10 for 2.0.0-alpha.6). Task names changed between 1.x
(`detektMetadataCommonMain`) and 2.x (`detektMainJvm`) — version
sensitivity is load-bearing, confirmed by issues #9284 and PR #9316.

Usability: finding output (`file:line` + rule id + message) is good, but
a weak model cannot author or debug PSI rules, and running them needs
Gradle. Duplicate findings across overlapping tasks reported upstream.

CI/hooks: per-source-set/per-compilation Gradle tasks; unusable as a fast
edit-hook; `build/`-folder noise and duplicated reports documented.

## Recommendation: A — bash + ripgrep, registry-wired (exactly ONE)

Reasons, in STANDARDS §1.5/§4.1 terms:

1. Evidence order: the house scripts already enforce all ten areas
(brief §11); no new-framework evidence is needed, and no candidate
covers locale parity without a script anyway.
2. Ponytail ladder: rg+bash is rung 1 (platform tooling, no new
dependency). Konsist/detekt are higher rungs justified only if rung 1
fails — it holds for 9/10 checks and ties on the 10th. Stop at rung 1.
3. Weak-model bar (§1.5): zero-build, sub-second, `file:line` output is
the Feedback-loop and Solve-don't-punt ideal — the script does the
checking, the agent runs exactly one command (Degrees of freedom).
4. Fixes the documented house weakness (§12.2): `install-guards.sh`
wires the same registry into CI *and* agent hooks, which the house
never did. The failure was wiring, not check technology.

Other two remain useful for: Konsist — named upgrade path if evals show
text-search false positives driving fixes to the wrong line
(meta-testing trigger); package-layer `dependsOn` checks as template
unit tests later. detekt — stock built-in rules for generic Kotlin
hygiene if a later phase wants them; custom rules only if a future check
genuinely needs type resolution. Neither in Phase 5.

## Ladder input (Phase 5)

Rung 1: `run-checks.sh` registry of rg/bash checks (generalised house
scripts). Rung 2 (only on measured false-positive pain): Konsist
declaration tests for the two parse-sensitive checks (Contract shape,
NavKey registration). Rung 3 (never for these ten): detekt custom rules.
Carve-outs unaffected: validation at trust boundaries, error paths,
tests — guards only report, they remove nothing.

## Scalability (50 modules, 10 developers)

rg scan time is flat (~ms) regardless of module count; conf-driven inputs
(`FEATURE_DIRS`, `LOCALE_DIRS`) scale without new code. No per-module
Gradle tasks, no Kotlin/Gradle/AGP version-alignment tax across 10
machines, no IDE skew. Konsist/detekt costs multiply per module and per
developer environment; their documented KMP workarounds (`--rerun-tasks`,
per-compilation tasks) get slower exactly as modules grow.

## Sources (all fetched 2026-09-24)

- Konsist getting started:
  https://docs.konsist.lemonappdev.com/getting-started/getting-started.md
- Konsist dependency (`konsist:0.17.3`, JUnit4/5 + Kotest):
  https://docs.konsist.lemonappdev.com/getting-started/getting-started/add-konsist-dependency.md
- Konsist KMP dedicated-module + rerun-tasks workaround:
  https://docs.konsist.lemonappdev.com/advanced/isolate-konsist-tests.md
- Konsist architecture assert (`dependsOn`, `strict`, scopes):
  https://docs.konsist.lemonappdev.com/writing-tests/architecture-assert.md
- detekt custom rules (Rule, RuleSetProvider, ServiceLoader, disabled
  by default, pure-Kotlin module pitfall):
  https://detekt.dev/docs/introduction/extensions/
- detekt KMP type-resolution tasks (syntax-only source-set tasks;
  JVM/Android-only type resolution):
  https://detekt.dev/docs/gettingstarted/type-resolution
- ripgrep (line-oriented regex, gitignore-aware, `-t`/`-T` file types,
  `--json`, opt-in PCRE2/multiline; ~0.08s kernel-tree benchmark):
  https://github.com/BurntSushi/ripgrep
- detekt KMP issue/PR context (via search excerpts 2026-09-24):
  https://github.com/detekt/detekt/issues/5961,
  https://github.com/detekt/detekt/issues/9284,
  https://github.com/detekt/detekt/pull/9316

## Could not verify

- Konsist's API for comment/TODO inspection (declaration-features pages
not fetched) — conservative choice: keep TODO as a script check.
- Whether Konsist `scopeFromProject` from a dedicated JVM module
resolves every KMP module's `commonMain` sources — needs a Phase 5
spike before any Konsist adoption.
- detekt stable-1.x vs 2.0.0-alpha.6 task names differ; any kit text
naming detekt tasks must be version-conditional (conditionals on
observables, STANDARDS §4.1).
