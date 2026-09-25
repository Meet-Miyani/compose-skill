# Existing Projects

Load this reference when the project diverges from the kit, or when migrating from Navigation 2, Hilt, or MVVM.

## Policy

Name the case with project evidence before writing code. (STANDARDS §6)

1. **New project, new module, new feature: the kit's architecture, strictly.** A green field or a new slice in a kit-shaped project takes every non-negotiable. (STANDARDS §6; SKILL.md rules 1-16)
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

## Pressure script

Answer no first, with the violated rule and the project evidence. State the correct approach in the project's own pattern. Name the consequence in one sentence. (Stance item 3; SKILL.md rule 1)

If the requester insists, restate the consequence once. Then follow the explicit decision and record the deviation. Never soften a violation into silent agreement. (Stance item 3)

## Red flags

| Thought | Reality |
|---|---|
| "I'll just add one kit MVI screen inside this MVVM feature to save time." | No. SKILL.md rule 1 forbids mixing two patterns in one feature. Build in the feature pattern and propose migration separately. |
| "The file next to mine uses a `Result` wrapper, so I will copy it." | Precedent is evidence, not permission (STANDARDS §6 case 4). SKILL.md rule 6 forbids wrappers in kit work; in a coherent wrapper project, case 2 applies instead. |
| "I'll migrate this Hilt feature to Koin while I am here." | No. SKILL.md rule 14 mandates Koin annotations for new kit code, but STANDARDS §6 case 2 forbids unasked migration. Propose it as a separate task. |
| "I'll rewrite this Navigation 2 graph to Navigation 3 in the same change." | No. SKILL.md rule 15 mandates Navigation 3 for new kit work, but migration ships leaf screens first as its own task (NAVMIG-09). |
| "This screen is 300 lines, so I must split it now." | No. Size is a review trigger, not a failure (CONTRACT_BRIEF §12.4). SKILL.md rule 1 moves structural changes to a separate task: propose the split and ship the fix. |

## Verification

- [ ] The existing-project case (1, 2, or 3) is stated with file-path evidence: yes or no?
- [ ] Touched files use one pattern per feature with no kit/project mix: yes or no?
- [ ] The answer names the divergence from the kit where one exists: yes or no?
- [ ] No Hilt, Navigation 2, MVVM, or wrapper tutorial code was added outside this note: yes or no?
- [ ] `rg -l "NavHostController|@HiltViewModel|Result<" <touched-feature-dir>` shows no new out-of-kit construct in kit-case work: pass or fail?
