# Adopt an Existing Project

Load this reference when adopting the kit in an existing Compose or Compose Multiplatform project instead of bootstrapping a new one.

## Audit first

Run the skill's read-only audit before writing any plan:

```sh
skills/compose-project/scripts/audit-project.sh <project-root>
```

The script prints four sections: the module list, the dependency edges between modules, the missing convention plugins (per-module target or SDK blocks that `build-logic/` should own), and the guard status (installed, WARN, blocking, or absent). Review all four before classifying. *Prevents:* a plan written from memory that misses the real coupling.

1. **(non-negotiable) Run the skill's `scripts/audit-project.sh` and review its full output before planning.** The audit is read-only evidence; planning without it repeats the guesses the audit exists to replace. *Prevents:* migration plans that miss hidden feature-to-feature edges.
2. **(non-negotiable) Write every gap-report finding as finding, evidence `file:line`, case, incremental step.** One row per finding, for example: notes editor ViewModel hand-rolls `try/catch`, evidence `feature/notes/.../NoteEditorViewModel.kt:88`, case 2, step "leave in place; kit contract applies to new features only". A finding without a `file:line` is a rumor, not a gap. *Prevents:* unactionable gap reports nobody can verify (SKILL.md rule 5).

## Classify, then plan

3. **(non-negotiable) Classify the project as case 1, 2, or 3 per the `compose-architecture` skill `existing-projects.md` policy, with file-path evidence, before writing code.** Link that policy; this file does not restate it. A notes app on Hilt plus MVVM plus Navigation 2 with green builds is case 2; the evidence is the Hilt entry point and the Navigation 2 graph files. *Prevents:* kit rules applied to a project that owns a different coherent pattern (SKILL.md rule 5).
4. **(non-negotiable) Adopt incrementally: guards in WARN mode to a clean baseline first, then convention plugins, then the base contract for new features only.** Guards become blocking only after the WARN baseline is clean. Convention plugins follow one module at a time. The MVI base contract lands on new features; working features keep their pattern. *Prevents:* big-bang rewrites that stall mid-flight (SKILL.md rules 1, 4, 5).

## What never to force-migrate

5. **(non-negotiable) Never force-migrate a working Hilt, MVVM, or Navigation 2 feature, never rewrite everything inside one change, and never mix two patterns in one feature.** New code in a coherent feature follows that feature's own pattern; kit migration is a separate task proposed on its own. A notes editor that ships on Hilt plus MVVM keeps shipping on Hilt plus MVVM until the migration task lands. *Prevents:* half-migrated features carrying two DI shapes and two async contracts (SKILL.md rule 5; `existing-projects.md` items 2 and 4).
6. **(non-negotiable) Read the AGP version in `gradle/libs.versions.toml` first; anything below 9 goes through the Studio Upgrade Assistant before editing build files.** Do not hand-apply the AGP 9 plugin shape to a sub-9 project as a side effect. Evidence: https://github.com/android/skills/blob/main/build-system/agp/agp-9-upgrade/SKILL.md (Apache-2.0). *Prevents:* build files edited against a remembered AGP shape that never applied (SKILL.md version gates).

## Record what stays different

7. **(non-negotiable) Record every kept deviation in `## Project decisions` with its reason.** Defaults the project keeps (UiModel triggers, split thresholds, scaffold options) win with no argument once recorded. A waived non-negotiable needs the recorded reason plus the affected code marked as a known deviation, and the agent does not re-argue it after that. A chat preference applies to the current task, and the agent offers to record it. *Prevents:* the same divergence re-litigated on every change (SKILL.md rules 9, 10; `existing-projects.md` item 5).

## Gotchas

- Guards that skip unregistered modules report green while covering nothing, so register every module in `.composekit.conf` before trusting a clean baseline.
- A gap report that lists findings without the incremental step for each becomes a rewrite wishlist, so every row names the step it belongs to.
- The AGP upgrade skill refuses KMP projects while this stack is CMP, so verify AGP 9 plus KMP against the JetBrains docs instead of that skill alone.
- For a KMP project the AGP 9 migration mechanics (library plugin swap, `androidApp` split, built-in-Kotlin removal) are optional depth in the Kotlin/kotlin-agent-skills `kotlin-tooling-agp9-migration` skill, if installed.
- For a KMP iOS integration still on CocoaPods, the move to `swiftPMDependencies` (add SPM alongside, transform imports, reconfigure Xcode, then remove CocoaPods) is optional depth in the Kotlin/kotlin-agent-skills `kotlin-tooling-cocoapods-spm-migration` skill, if installed.
