# Fix round 11: release v6.0.0-preview.1 (plan step 10, worker brief)

**Owner go: 2026-10-01.** **Worker:** GPT-6-Sol via Codex. **Rules:** `handoff/WORKER_RULES.md` applies, **with the
write scope widened for this round** to: `skills/`, `skills-v2/`, `tests/`, `docs/`, `evals-v2/`, `catalog/`,
`internal/`, `main.go`, `main_test.go`, `scripts/`, `install.sh`, `Makefile`, `README.md`, `NOTICE.md`,
`.gitignore`, and `handoff/work/`. Use plain `mv`/`cp`/`rm`; **never run git commands that change state** (the
moderator stages and commits). Never open `evals-v2/heldout*` task files except to fix the path references listed in
§F.

**Owner decisions (2026-10-01):**
- the version is **v6.0.0-preview.1**: a pre-release, per the v5 verdict
- **`handoff/` is not published**: the moderator untracks it, and nothing published may link into it
- the GitHub repo is **`Meet-Miyani/compose-skill`**: `Meet-Miyani/composekit` does not exist

**Source of the numbers:** `evals-v2/results-v5/VERDICT.md` and `score-output.txt`. Quote them exactly; claim
nothing the verdict does not allow.

## A. Move the kit into `skills/`

1. Delete the legacy skill `skills/compose/`; it is retired. The new entry skill takes its name.
2. Move the 7 skill folders `skills-v2/{compose,compose-architecture,compose-feature,compose-ui,compose-data,compose-project,compose-platform}` to `skills/`.
3. Move `skills-v2/_tests/` to `tests/skills/`. Update `run-tests.sh` so that `REPO_ROOT` and the skill paths point
   at `skills/`, and its scratch directory is a `mktemp -d` that it removes on exit; nothing is written into the repo.
4. `skills-v2/NOTICE.md` → root `NOTICE.md`. `handoff/work/EXTERNAL_LEDGER.md` and
   `handoff/work/STYLE_NOTES.md` → `docs/attribution/`. First check both files contain no `/Users/` path and no
   "HaatPartner"; if either does, replace it with neutral text. Update the NOTICE links.
5. `skills-v2/docs/*` → `docs/`. Then remove the empty `skills-v2/` (its README content goes into the root
   README, §E).
6. Inside `skills/`: `grep -rn "skills-v2" skills` must return nothing; fix every path and link (relative links
   between skills such as `../compose-feature/...` already work).

## B. Catalog `catalog/skills.json`

7 entries, one per skill: `name`, `path` (`skills/<name>`), `displayName`, `description` (copy each SKILL.md
description, one line), `keywords`. Add a top-level `"bundle": ["compose", "compose-architecture", "compose-feature",
"compose-ui", "compose-data", "compose-project", "compose-platform"]`: the set `init` and `update` install
together. Extend `internal/catalog` to parse it; keep `schemaVersion` 1 if parsing stays backward compatible, else 2.

## C. CLI

- `init`, `update`, `remove` (bare) and `doctor` act on **every skill in `bundle`**. Today they act only on
  `defaultSkillName`, which would install the entry tree without the 6 skills it points to. `skills add/remove
  <name>` stay per skill.
- `update` must handle the old install: when a target has the legacy managed `compose` skill, replace it with the
  bundle's `compose`.
- Replace every `Meet-Miyani/composekit` with `Meet-Miyani/compose-skill`: `install.sh` (the `REPO` default),
  `internal/github/releases.go`, README commands. Leave the Go module path unchanged (no `go install` is advertised).
- Add or extend Go tests: catalog parsing with `bundle`; `init` into a temp target installs all 7 folders;
  `remove` removes all 7.

## D. Packaging

`scripts/package-skills.sh` tars `skills/` (all 7) and `catalog/skills.json`, excluding `tests/`, `docs/`,
`evals-v2/` and any `_tests`. Check that `.goreleaser.yaml`'s embedded files (if any) and `main.go`'s `//go:embed`
cover `skills/` and the catalog.

## E. README (root)

Rewrite the root `README.md` for the new kit. Merge in the useful parts of `skills-v2/README.md`; the legacy README
is replaced. Required sections:
1. **What it is:** 7 skills (one `compose` entry tree plus 6 topic skills); the house stack; progressive loading
   (`compose` ~1.3k tokens → one reference per area).
2. **Install:** `install.sh` with the compose-skill URL; `composekit init`.
3. **Results (v6.0.0-preview.1, held-out v5):** the verdict table (no kit / generic prompt / kit for the 5 models),
   the pre-registered outcome ("preview: helped Sonnet 5, Opus, GPT-6-Sol and Gemini 3.8 Flash; not GPT-6-Luna"),
   the lifts, the generic-prompt comparison, house-style gains, and kit context per task (`kit-tokens.txt`).
   One line on method: 120 agentic runs, an independent task author, blind cross-vendor grading, grades frozen
   before scoring.
4. **Known issues (v2.1 work):** over-restructuring when asked to conform existing code; reviews still flag fine
   code as blocking; GPT-6-Luna; new features can exceed 20k tokens on models that read beyond the tree; only one
   kit-shaped project tested; one run per cell.
5. **Earlier comparison with the legacy skill:** the 2026-09-29 head-to-head (an older candidate, both loaded
   whole: Gemini 94 vs 89, GPT-6-Sol 72 vs 59, Sonnet 90 vs 76), labelled as *not re-measured on this release*.
6. **How it was tested:** link `evals-v2/results-v5/` and `evals-v2/method/`.

Plain language, honest, and no badges that overstate. No link into `handoff/`.

## F. Public evaluation method (`evals-v2/method/`)

- Copy the step 8 and step 9 sections of `handoff/reviews/m9.md`, from "## Plan step 8" to the end, into
  `evals-v2/method/preregistration-v5.md` **verbatim**, except: replace absolute paths with `<repo>`, and replace
  "HaatPartner" (if present) with "the reference app".
- Copy `handoff/tools/eval/{v5-run.sh,v5-run-opencode.sh,v5-queue-model.sh,v5-verify-tasks.sh,v5-grade.py,smoke-load.sh,smoke-parse.py}`
  and `handoff/tools/route-budget.py` into `evals-v2/method/tools/`. Make `REPO` derive from the script location
  instead of an absolute path, and fix paths that pointed into `handoff/`.
- Replace links into `handoff/` in `evals-v2/results-v5/{README,VERDICT}.md`, `evals-v2/results/SCOREBOARD.md`,
  `evals-v2/heldout-v3.md`, `evals-v2/heldout-v4.md` and `evals-v2/heldout-v4-build.py` with
  `evals-v2/method/...` where the file was copied, else with "(internal record, not published)". In
  `evals-v2/results-v5/checks-rerun/*.log`, replace absolute paths with `<repo>`.
- `grep -rn "/Users/\|HaatPartner" skills tests docs evals-v2 README.md NOTICE.md catalog scripts internal main.go install.sh`
  must return nothing.

## Checks before you finish

- `bash tests/skills/compose-architecture/run-tests.sh` passes (90 or more).
- `go build ./... && go test ./...` pass.
- `bash scripts/package-skills.sh test` creates the tarball, and `tar tzf` lists the 7 skills and no tests or docs.
- `go run . init --dry-run` (or the CLI's equivalent) shows all 7 skills for a temp target. If a real install is
  needed, use a temp HOME.
- `bash handoff/tools/validate-v2.sh --score-only`, pointed at `skills/*` (adjust the call): every topic skill ≥ 90.
- `grep -rn "handoff/" skills tests docs evals-v2 README.md NOTICE.md catalog scripts internal main.go install.sh .github`
  returns nothing.

## Report

Write `handoff/work/reports/fix-round-11.md` with:
- the files moved, added and changed
- the outputs of the checks
- anything left undone, and why
