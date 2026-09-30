# Fix round 9 — reproducible Gradle bootstrap

## Files added and changed

- Added `skills-v2/compose-project/templates/project/gradlew` (executable), `gradlew.bat`, and `gradle/wrapper/gradle-wrapper.jar`, generated with Gradle 9.8.0's `:wrapper` task in `handoff/work/scratch/fr9-wrapper/`.
- Changed `skills-v2/compose-project/templates/project/gradle/wrapper/gradle-wrapper.properties` to pin the official distribution checksum while retaining its existing comments and settings.
- Changed `skills-v2/compose-project/templates/project/.gitignore` to allow the wrapper JAR in version control.
- Changed `skills-v2/compose-project/references/bootstrap.md` to list all wrapper files and say to commit them and validate the JAR in CI.
- Changed `skills-v2/compose-project/templates/project/composekit.yml` to run `gradle/actions/wrapper-validation@v6` immediately after checkout.
- Added this report. `handoff/work/scratch/fr9-wrapper/` holds the generation project; `handoff/work/scratch/fr9-check/` holds the verification copy.

## Checksums and sources

| Artifact | Local SHA-256 | Official Gradle SHA-256 | Result |
|---|---|---|---|
| `gradle-wrapper.jar` | `238e777fcddd7e34f9708186085def2abd6e08e658505b38718d79d74c21abd5` | `238e777fcddd7e34f9708186085def2abd6e08e658505b38718d79d74c21abd5` | Match |
| `gradle-9.8.0-bin.zip` | Not downloaded in this round | `bafd5ce9cfaea0fbccfdc8439a1ac42fbd4cd9c89dc9a988228d8a2639a58e6c` | Pinned as `distributionSha256Sum` |

Fetched URLs:

- [Gradle Wrapper documentation, including distribution and JAR verification](https://docs.gradle.org/current/userguide/gradle_wrapper.html)
- [Gradle 9.8.0 release checksums](https://gradle.org/release-checksums/)
- [Official Gradle 9.8.0 binary ZIP checksum](https://services.gradle.org/distributions/gradle-9.8.0-bin.zip.sha256)
- [Official Gradle 9.8.0 wrapper JAR checksum](https://services.gradle.org/distributions/gradle-9.8.0-wrapper.jar.sha256)
- [Gradle wrapper-validation action directory](https://github.com/gradle/actions/tree/main/wrapper-validation)
- [Gradle wrapper-validation README, current `@v6` example](https://raw.githubusercontent.com/gradle/actions/main/wrapper-validation/README.md)

Gradle's documentation says the scripts, JAR, and properties file should be checked into version control. Its checksum reference and `.sha256` endpoints agree on both values above. The action README gives `gradle/actions/wrapper-validation@v6` as its current example.

## Checks run

| Command | Output | Result |
|---|---|---|
| `bash skills-v2/_tests/compose-architecture/run-tests.sh` | `90 passed, 0 failed` | PASS |
| `bash handoff/tools/budget.sh` | `RESULT: PASS` (existing WARN entries; the JAR was not counted as Markdown content) | PASS |
| `sh ./gradlew --version` from `handoff/work/scratch/fr9-check/` | `Gradle 9.8.0` | PASS |
| `bash handoff/tools/validate-v2.sh --score-only skills-v2/compose-project` | `=== compose-project ===` / `90/100 A` | PASS |
| `shasum -a 256` on template and scratch-copy JARs | Both `238e777fcddd7e34f9708186085def2abd6e08e658505b38718d79d74c21abd5` | PASS |
| `git check-ignore -v` on template JAR | No output; the JAR is not ignored | PASS |

STANDARDS §9 review: no rules, Red flags, Verification items, third-party tutorial code, or example-domain text were changed. The touched skill scores 90/100. The wrapper addition does not duplicate another skill's guidance and preserves the existing validation contract.

## Packaging note

`scripts/package-skills.sh` currently archives only `skills/compose/` and `catalog/skills.json`. A package intended to ship `skills-v2/compose-project/templates/` would need a packaging change to include this JAR and its companion wrapper files. I did not edit that script because it is outside this round's write scope.
