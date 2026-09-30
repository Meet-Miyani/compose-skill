# Fix round 9: reproducible bootstrap (release plan step 7, worker brief)

**Starts after fix round 8 (`75187bd`), on the owner's go.** **Worker:** GPT-6-Sol via Codex. **Rules:**
`handoff/WORKER_RULES.md` applies in full. Write only under `skills-v2/**` and `handoff/work/**`. Never commit. Never
open `evals-v2/heldout*`.

**Problem (review R16, verified).** The template project has no Gradle wrapper scripts or JAR, and its `.gitignore`
ignores `gradle/wrapper/gradle-wrapper.jar`. The moderator's assembler copies the wrapper from a private,
gitignored scratch project. No reference tells a user or agent how to obtain the wrapper. A fresh clone cannot
build.

**Principle:** follow the Gradle docs. The wrapper (scripts, JAR, properties) is committed with the project and
its JAR is verified by checksum. Fetch and cite https://docs.gradle.org/current/userguide/gradle_wrapper.html
(and the wrapper-verification section).

## Changes

1. **Generate an official wrapper for the pinned Gradle 9.8.0** into
   `skills-v2/compose-project/templates/project/`, producing `gradlew`, `gradlew.bat` and
   `gradle/wrapper/gradle-wrapper.jar`, next to the existing `gradle-wrapper.properties`:
   - Generate it in a temporary directory under `handoff/work/scratch/fr9-wrapper/`: an empty
     `settings.gradle.kts`, then `gradle wrapper --gradle-version 9.8.0` if a `gradle` binary exists; otherwise
     run `./gradlew wrapper --gradle-version 9.8.0` from any existing Gradle project under
     `handoff/work/scratch/`.
   - Copy the three files in. Keep the existing `gradle-wrapper.properties` comments and add
     `distributionSha256Sum=<sha256 of gradle-9.8.0-bin.zip>`, taken from the official checksum published by
     Gradle (`https://services.gradle.org/distributions/gradle-9.8.0-bin.zip.sha256`).
   - Verify the JAR against Gradle's published wrapper-JAR checksums (https://gradle.org/release-checksums/, or the
     `gradle-9.8.0-wrapper.jar.sha256` file). Record both hashes in the report. **If the JAR checksum does not
     match an official one, stop and report; do not ship it.**
   - `gradlew` stays executable (`chmod +x`).
2. **`templates/project/.gitignore`:** remove the `gradle/wrapper/gradle-wrapper.jar` line.
3. **`compose-project/references/bootstrap.md`:** in the skeleton step, list `gradlew`, `gradlew.bat` and
   `gradle/wrapper/gradle-wrapper.jar` with the properties file. Add one sentence: the wrapper is committed; the
   JAR is checked in CI. Cite the Gradle page.
4. **CI template `templates/project/composekit.yml`:** add the official wrapper-validation step
   (`gradle/actions/wrapper-validation`; fetch its README for the current major version) right after checkout.
5. **`scripts/package-skills.sh` note:** do not edit it (outside your write scope). In the report, state whether a
   binary JAR inside `skills-v2/compose-project/templates/` needs a packaging change.

## Checks before you finish

- `bash skills-v2/_tests/compose-architecture/run-tests.sh` passes (90 or more).
- `bash handoff/tools/budget.sh` passes (the JAR is not Markdown, so it must not count as content; if budget.sh
  counts it, say so in the report and do not change the tool).
- `sh skills-v2/compose-project/templates/project/gradlew --version` prints Gradle 9.8.0, run from a copy of the
  template in `handoff/work/scratch/fr9-check/`.

## Report

Write `handoff/work/reports/fix-round-9.md` with:
- the files added and changed
- the JAR SHA-256 and the official one
- the distribution SHA-256
- the URLs fetched
- the checks

**Moderator then:** changes `handoff/tools/eval/assemble-verify-project.sh` to take the wrapper from the templates,
commits, clones the repository into a clean directory with no `handoff/work/scratch/`, and builds Android, desktop
and the iOS framework there (the plan step 7 finish condition).
