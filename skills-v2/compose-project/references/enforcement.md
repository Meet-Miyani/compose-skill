# Enforcement

Load this file when installing guards, wiring CI, wiring agent hooks, activating the kit, or enforcing stability baselines (SKILL.md rule 10).

Contents: install script (§1), registry discipline (§2), CI job (§3), agent hooks (§4), kit activation (§5), verification gates (§6), stability baselines (§7), gotchas (§8), further CI depth (§9).

## 1. What install-guards.sh does

Run `install-guards.sh <project-root>` once per project. It copies every `check-*.sh` plus `run-checks.sh` into `<root>/scripts/composekit/`, writes `.composekit.conf` from `composekit.conf.example` only when the project has none (an existing file is kept, never overwritten), and prints the CI snippet plus the hook snippets. It never writes user config.

1. **Run the installer instead of hand-copying checks or hand-writing the config. (non-negotiable)** The installer is the only path that keeps installed scripts and config in sync with the kit. *Prevents:* installer/installed drift (brief §11.15).
2. **Adjust `.composekit.conf` to the project layout before done: module prefixes, composition root, locale dirs, base package. (non-negotiable)** A Notes project registers its `:feature:notes` and `:feature:tags` prefixes; defaults that match nothing guard nothing. *Prevents:* green runs that skip real modules (SKILL.md rule 4).

The script prints exactly this tail (copy it, do not reword it; the head
reports what was installed and whether `.composekit.conf` was written):

```text
CI snippet (GitHub Actions):
  - name: composekit guards
    run: bash scripts/composekit/run-checks.sh .
Agent hook snippets (run before finishing a Compose change):
  Claude Code / OpenCode / Cursor: bash scripts/composekit/run-checks.sh .

Kit activation (the compose-project skill owns this; a request to wire hooks is consent):
  1. Add one line to the project's AGENTS.md / CLAUDE.md:
     Compose/CMP work: load the compose skill first; it picks the path and the files to read.
  2. Optional Claude Code SessionStart hook that injects compose-architecture's
     routing section; see the compose-project skill (references/enforcement.md)
     for the exact snippet. A user's request to wire CI or agent hooks is consent:
     install them, then show exactly what was written. Unprompted, print the snippet
     and write nothing.
```

## 2. Registry discipline

3. **CI and hooks call `scripts/composekit/run-checks.sh` (the registry), never individual check scripts. (non-negotiable)** One caller means one ordering. *Prevents:* a second registry that drifts (SKILL.md rule 10; PROJ-03).
4. **One line per check; a missing script fails before any check runs; the run ends with a fail-fast summary. (non-negotiable)** The registry lists each check by name, aborts missing entries up front, and prints the pass/fail table. *Prevents:* silent skips and green theater (brief §11.14; PROJ-03).

## 3. CI job

5. **The guard step lives in the build job and runs on every change. (non-negotiable)** Guards that run nightly or on release branches find violations after they compound. *Prevents:* late-found boundary breaks (brief §11.14).
6. **[Default] Copy `templates/project/composekit.yml` for CI guards; keep the shape generic across forges.** The template checks out the repo, sets up Java 21, and runs guards only. Add the build and test legs from `distribution.md` §4. *Prevents:* claiming CI compilation coverage that the template does not run (SMP-64, SMP-67 pattern).

The only guard line in any CI job is:

```yaml
- name: composekit guards
  run: bash scripts/composekit/run-checks.sh .
```

## 4. Agent hooks

7. **Claude Code, OpenCode, and Cursor hooks run the registry before finishing a Compose change. (non-negotiable)** The house guards existed but no hook called them, so agents skipped them silently. *Prevents:* silently skipped guards (brief §12.2; SKILL.md rule 10).
8. **A user's request to wire CI or agent hooks is consent: install them, then show exactly what was written. Otherwise print hook snippets and write nothing. (non-negotiable)** The consent rule covers kit activation (the AGENTS.md pointer and the SessionStart hook) offered unprompted, and any write the user did not ask for. *Prevents:* clobbered user configuration.

## 5. Kit activation

Activation makes routing reliable without depending on skill matching.

9. **Every project carries the one-line kit pointer in `AGENTS.md`/`CLAUDE.md`. (non-negotiable)** Exact line: `Compose/CMP work: load the compose skill first; it picks the path and the files to read.` *Prevents:* routing by description-match luck (SKILL_SPECS §5 item 4).
10. **[Default] Offer the optional Claude Code SessionStart hook that injects the routing excerpt (a short excerpt, never the whole skill).** Exact snippet for `.claude/settings.json`:

```json
{
  "hooks": {
    "SessionStart": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "printf '%s\\n' 'Compose/CMP work: load the compose skill first; it picks the path and the files to read.'"
          }
        ]
      }
    ]
  }
}
```

*Prevents:* sessions that start Compose work without the router loaded. Field names verified against https://code.claude.com/docs/en/hooks (an omitted matcher matches all SessionStart modes; Claude Code adds the command's plain-text stdout as context).

## 6. Verification gates

11. **Verify with IDE sync plus a build dry-run; never `clean` as verification. (non-negotiable)** Sync exercises the project model and the dry-run exercises configuration without wiping caches. *Prevents:* clean hiding incremental breakage (AND-35).

## 7. Stability baselines

12. **Commit baseline and config files next to sources, never under a gitignored build directory. (non-negotiable)** A baseline the repo does not track cannot gate anything. *Prevents:* gate theater (SKY-29).
13. **Diagnose and repair stability before seeding the baseline. (non-negotiable)** Baselining a broken state locks the brokenness in. *Prevents:* frozen regressions (SKY-32).
14. **Every ignore entry carries a co-located rationale comment; never silence a production package to hide a regression. (non-negotiable)** An unexplained ignore is a hidden waiver. *Prevents:* hidden regressions (SKY-33).
15. **Run the stability check in the same CI job as compilation. (non-negotiable)** One daemon delivers the earliest signal without doubling build time. *Prevents:* slow, late stability signals (SKY-34).
16. **[Default] Ship the strict-fail setting as the committed default with an explicit per-invocation local opt-out for iteration speed.** The repo stays strict; only the local command line relaxes. *Prevents:* committed leniency from local convenience (SKY-30).

## 8. Gotchas

- Declare a concurrency group with cancel-in-progress on every workflow, or stale runs on the same ref burn CI minutes (SMP-69).
- A stability check applied to the app module only stays blind to feature-module regressions; cover every UI module (SKY-31).
- A green stability gate with rising recomposition counts proves a runtime-only invalidation source; pair the gate with runtime tracing (SKY-35).
- UNVERIFIED: prefer the community baseline-diff plugin on targets outside the Android plugin reach, keeping the same commit-baseline plus fail-on-diff shape (SKY-36; plugin fit not re-checked against current docs).

## 9. Further CI depth (optional, one line each)

- Turn on the lint convention for every library and app module with reports enabled (SMP-07).
- Generate module dependency graphs in CI and fail when the checked-in graph is stale (SMP-15).
- Publish the design-system custom lint rules to consumers through the in-repo lint module (SMP-29).
- Verify screenshot references in CI and record new images on failure (SMP-61).
- Run instrumented tests on declared managed devices mirrored by an emulator matrix job (SMP-62).
- Use the Gradle setup action with a checked-in CI properties file (no daemon, parallel, configuration cache) for caching (SMP-65).
- Verify dependency-guard baselines first; regenerate them automatically on pull requests while blocking forks from pushing baseline updates (SMP-66).
- Enforce coverage thresholds overall and on changed files from the library-module coverage plugin (SMP-70).
