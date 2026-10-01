# Existing Projects

Load when: deciding whether an existing project's conventions or kit defaults apply.

## Choose

- Is this a kit project or green field?
  - Yes: follow the kit for new code. *Prevents:* inconsistent foundations.
  - No: does the project use one coherent pattern, such as Hilt, MVVM, Navigation 2, or its own base class?
    - Yes: follow that pattern for this change, with no waiver. *Prevents:* a mixed feature and surprise migration.
    - No: use the kit for new code and name the incoherence. *Prevents:* adding another competing pattern silently.
- Did the user ask to conform existing code?
  - Yes: run the guards, fix blocking items and agreed deviations, and keep behaviour intact. See `../../compose-feature/references/review-mode.md`. *Prevents:* a style pass becoming a rewrite.
- Not covered here → use judgement and state the assumption.

## Policy

Decide the case silently from project evidence before writing code; it never appears in a user-facing answer. (STANDARDS §6)

1. **New project or new code in a kit-shaped project: use the kit.** (STANDARDS §6; SKILL.md rules 1-16)
2. **Coherent different architecture: follow the project's pattern for the change at hand.** Hilt, MVVM, Navigation 2, or its own base class, used consistently, stays for that change. Never mix two patterns in one feature. Say the project diverges from the kit. Propose migration as a separate task. Do not migrate unless asked. (STANDARDS §6; ARCH-01; SKL-17; ARCH-19)
3. **Incoherent project: use the kit's pattern for new code.** Several competing patterns with no consistent convention means new code follows the kit. Name the incoherence. Propose migration as a separate task. (STANDARDS §6)
4. **Precedent is evidence, not permission.** A neighboring file that violates a non-negotiable does not license a copy. Copying it copies the defect. Check the file against the rules first. (STANDARDS §6)
5. **Recorded project decisions win over kit defaults; non-negotiables need a recorded, reasoned waiver.** The kit has two kinds of rule. **Defaults and conditionals** (UiModel triggers, file-split thresholds, optional layers, scaffold options): an owner decision recorded in the project's `## Project decisions` section (`AGENTS.md` / `CLAUDE.md`) wins with no argument; the agent may state the cost once, the first time it applies, then follows the decision everywhere. Machine-readable switches the scripts need (e.g. `UI_MODEL=always`) go in `.composekit.conf`. A preference said once in chat and not recorded applies to the current task, and the agent offers to record it. **Non-negotiables** (the iron laws: DTO boundary, guarded async with `onError`, cancellation rethrow, one owner per value, identity-only nav keys, and so on): these hold against an in-chat push; a project waives one only through a recorded decision that gives a reason, and the agent then follows it, marks the affected code as a known deviation, and does not re-argue. (STANDARDS §6; ruling M-12)

## What never to force-migrate

Keep a coherent existing screen architecture unless asked to migrate or it cannot satisfy a required constraint. (ARCH-01; SKL-17)

Suggest structural changes only when asked or on clear violations. Business logic in composables and scattered state mutations count as clear violations. Anything smaller gets the minimal fix in the project's own pattern. (SKL-05)

Oversized files are review triggers, not migration triggers. A notes ViewModel above 250 lines, a notes Screen above 250 lines, or a notes Contract above 200 lines earns a split proposal, never a forced rewrite. (CONTRACT_BRIEF §12.4)

## Migrating from Navigation 2

Navigation 2 is not taught. The string-routes `NavHostController` API belongs only in this note. (CMP-32)

Migrate incrementally: leaf screens first, shared ViewModels last. One destination per task, with tests passing before the next move. (NAVMIG-09)

Navigation 2 API mechanics live in the android/skills `navigation-3` skill, if installed. That skill is optional depth, never a prerequisite. This kit keeps only its own key and ownership conventions. (CONTRACT_BRIEF §7.1)

## Divergences

Hilt: the official sample injects entry points, ViewModels, and modules with Hilt annotations. That contradicts the kit Koin-annotations decision. The divergence is known and intentional. In a Hilt project, follow Hilt for the change at hand. (SMP-44; STANDARDS §6 case 2)

MVVM: in a coherent MVVM project, write the notes screen in MVVM for the change at hand. Never plant one kit MVI screen inside a coherent MVVM feature. (STANDARDS §6 case 2; SKILL.md rule 1)

Result wrappers: in a project that uses `Result` wrappers or its own base class consistently, follow that shape for the change at hand. New kit work never adopts wrappers. (ARCH-19; SKILL.md rule 6)

Koin flavours: new kit code uses the compiler plugin, where `@KoinViewModel` is `org.koin.core.annotation.KoinViewModel` (ruling M-13). Projects on the KSP flavour keep `org.koin.android.annotation.KoinViewModel` for the change at hand (STANDARDS §6 case 2).

Java sources: convert leaf dependencies first with `git mv` history preserved. The framework-aware batch methodology is optional depth in the Kotlin/kotlin-agent-skills `kotlin-tooling-java-to-kotlin` skill, if installed.

## Pressure script

Answer no first, with a plain reason and the project evidence. State the correct approach in the project's own pattern. Name the consequence in one sentence. (Stance item 3; SKILL.md rule 1)

If the requester insists, restate the consequence once. Then follow the explicit decision and record the deviation. Never soften a violation into silent agreement. (Stance item 3)


## Verification

- [ ] The existing-project case (1, 2, or 3) was decided internally from file-path evidence and never printed: yes or no?
- [ ] Touched files use one pattern per feature with no kit/project mix: yes or no?
- [ ] The answer names the divergence from the kit where one exists: yes or no?
- [ ] No Hilt, Navigation 2, MVVM, or wrapper tutorial code was added outside this note: yes or no?
- [ ] `rg -l "NavHostController|@HiltViewModel|Result<" <touched-feature-dir>` shows no new out-of-kit construct in kit-case work: pass or fail?
