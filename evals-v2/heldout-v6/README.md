# Held-out tasks, v6.x A/B

Pre-registered in `../method/preregistration-v6.md` (with Amendment 1). Six tasks in a reading-log domain on the
v5 base app (`../heldout-v5/base-app.tar.gz`):
- **T1-T2:** conform
- **T3-T4:** review only
- **T5-T6:** new feature

- `tasks.md`: prompts, setups, checks and rubrics. `[eng]` items come from the independent author (Gemini 3.1 Pro),
  as repaired by the moderator. `[kit]` items are marked "(moderator)".
- `setup/`: `common.sh` (the shared reading-log base) and one script per task, run from the project root.
- `hidden/`: the conform tasks' behaviour tests and where they go (`DEST`).
- `fix/`: reference conform patches, used only by the gate.
- `verification.md`: the gate output on both base variants, and every moderator repair with its reason.
