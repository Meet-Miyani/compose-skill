# Fix round 12: four standard install channels; retire the Go CLI (plan step 10, part 2; worker brief)

**Owner decisions, 2026-10-01:**
- Users install through **four standard channels**: `npx skills`, `gh skill`, a Claude Code plugin and a Codex
  plugin.
- The **Go CLI is retired** from main and is not released with v6.0.0-preview.1. A future "kit CLI" for project
  tooling is post-release scope.

**Worker:** GPT-6-Sol via Codex. **Write scope:** `.claude-plugin/`, `.codex-plugin/`, `.agents/plugins/`,
`.github/workflows/`, `README.md`, `docs/`, `scripts/`, `catalog/`, the Go files listed in §C, `.goreleaser.yaml`,
`install.sh`, `Makefile`, `.gitignore`, `handoff/work/`. **Never run git commands that change state.** Every manifest
format must come from a page you fetch now; cite the URLs in the report.

## A. Plugin manifests (one plugin, "compose-kit", bundling all 7 skills in `skills/`)

1. **Claude Code:** `.claude-plugin/marketplace.json`, plus `plugin.json` if the docs require one. Fetch
   https://code.claude.com/docs/en/plugin-marketplaces and
   https://code.claude.com/docs/en/plugins/host-marketplace and follow them exactly.
   - The plugin's source is this repo, and its skills are the 7 folders under `skills/`.
   - Set `version` to `6.0.0-preview.1`. The docs warn that users get no update if `version` is not bumped, so add
     a line about this to `docs/RELEASING.md` (create it: how to cut a release).
   - If the `claude` CLI is available, validate with `claude plugin validate .` (or the documented equivalent) and
     paste the output.
2. **Codex:** `.codex-plugin/plugin.json` and `.agents/plugins/marketplace.json`, per
   https://developers.openai.com/codex/plugins/build. Version `6.0.0-preview.1`. Validate with whatever the Codex
   docs offer, if anything.
3. **Do not add** a Gemini extension (`gemini-extension.json`): `gh skill` covers Gemini CLI and Antigravity.

## B. README install section (replace the current one)

Order and exact commands:
1. `npx skills add Meet-Miyani/compose-skill --skill '*'` (needs Node ≥ 22.20; covers Claude Code, Codex, Cursor,
   OpenCode, Copilot and more). Check the flag for "all skills" against
   https://github.com/vercel-labs/skills (README) and use the documented form.
2. `gh skill install Meet-Miyani/compose-skill --all` (needs gh ≥ 2.90; covers Gemini CLI and Antigravity too;
   **pin to a release** with the documented `@<tag>` or `--pin` form). Check against
   https://cli.github.com/manual/gh_skill_install.
3. Claude Code: `/plugin marketplace add Meet-Miyani/compose-skill`, then the exact `/plugin install` line for the
   plugin name you chose.
4. Codex: `codex plugin marketplace add Meet-Miyani/compose-skill` (check the exact command in the Codex docs), then
   its install step.

Add:
- **"Install all 7 skills"** in bold, with one plain sentence on why (the `compose` entry routes to the other 6).
- A one-line project pointer to add to `AGENTS.md`/`CLAUDE.md` (the existing pointer line from
  `skills/compose-project/references/enforcement.md`).
- **Upgrading from the old single `compose` skill (v5.x or the `composekit` CLI):** remove the old
  `compose` folder from your agent's skills directory, then install with any channel above. The old CLI's `update`
  cannot fetch v6.
- **Optional project guards:** `bash <skills dir>/compose-architecture/scripts/install-guards.sh <project>`
  (check the real path and usage in that script).

Remove every mention of `composekit init`, the Go CLI and `install.sh`. Keep the Results, Known issues and How it was
tested sections from round 11 unchanged. Add a short **Roadmap** line: "v6.x: fixes for the known issues; later,
maybe a kit CLI for project tooling (new project, add feature, run guards), if users need it."

## C. Retire the Go CLI from main

- Delete `main.go`, `main_test.go`, `internal/`, `go.mod`, `go.sum`, `.goreleaser.yaml` and `install.sh`. Delete
  `Makefile` too if every target is CLI-only; otherwise keep its non-CLI targets.
- `.github/workflows/release.yml`: on a tag, it no longer runs goreleaser. Instead it:
  - packages the skills tarball (`scripts/package-skills.sh`)
  - writes `checksums.txt`
  - creates the GitHub release with both files, marked as a **pre-release** when the tag contains `-`
  
  Use `gh release create` with `--prerelease` set conditionally, or the equivalent.
- `.github/workflows/ci.yml`: drop the Go jobs. It runs `bash tests/skills/compose-architecture/run-tests.sh` and
  validates the plugin manifests (JSON parse, plus each referenced path exists).
- `catalog/skills.json` was only read by the Go CLI. Keep it if `scripts/package-skills.sh` or the README use it;
  otherwise delete it and update the packaging script.

## Checks before you finish

- `bash tests/skills/compose-architecture/run-tests.sh` passes (90 or more).
- `bash scripts/package-skills.sh test`: `tar tzf` lists the 7 skills only.
- `python3 -m json.tool` on every new JSON file; every path they reference exists.
- `grep -rn "composekit init\|install\.sh\|go install\|goreleaser" README.md docs .github` returns nothing, apart
  from a deliberate historical note.
- `actionlint` on the workflows if available; otherwise state that it was not run.
- `grep -rn "handoff/\|/Users/\|HaatPartner"` over every published path returns nothing.

## Report

Write `handoff/work/reports/fix-round-12.md` with:
- the files added, removed and changed
- the URLs of every doc page fetched
- the check outputs
- anything left undone, and why
