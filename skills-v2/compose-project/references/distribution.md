# Distribution

Load this file when packaging the desktop app, signing or notarizing any platform, or wiring the per-OS CI matrix (SKILL.md rules 7, 10).

Contents: desktop module shape (§1), native-packaging gotchas (§2), signing (§3), CI matrix (§4), caches and toolchains (§5), verify gates (§6).

## 1. Desktop module shape

The desktop entry point is a thin JVM module over the shared Notes/Catalog code. Its shape follows the official KMP-App-Template `desktopApp` build file, paraphrased (Apache-2.0).

1. **Apply the JVM, Compose Multiplatform, and Compose compiler plugins together on the desktop module; never ship a desktop entry point from the shared module alone. (non-negotiable)** The shared module holds `commonMain` UI; only the desktop module declares the application block the packager reads. *Prevents:* a packager with no application to package.
2. **Declare the desktop framework dependency through the current-OS accessor, not a fixed platform artifact. (non-negotiable)** A hardcoded macOS artifact breaks the Windows and Linux legs of the matrix. *Prevents:* installers that only build on one OS.
3. **Add the coroutines Swing dispatcher artifact on desktop whenever `viewModelScope` or the lifecycle scope is used. (non-negotiable)** `Dispatchers.Main.immediate` has no desktop default, so scopes backed by it fail without it. *Prevents:* Main-immediate crashes on desktop (CMP-37, CMP-42 pattern).
4. **Hold the main class, package name, and package version in the `compose.desktop` application block; hold every version in `gradle/libs.versions.toml` per SKILL.md rule 7. (non-negotiable)** A name or version repeated in two places diverges at the first release bump. *Prevents:* installer identity drift (SKILL.md rule 7).
5. **Request each installer format (disk image, Windows installer, Linux package) explicitly in `nativeDistributions`. (default)** Formats default to none, so an undeclared format silently produces no artifact. *Prevents:* a release job that "passes" with nothing to publish.

## 2. Native-packaging gotchas

Evidence for this section: https://kotlinlang.org/docs/multiplatform/compose-native-distribution.html (fetched 2026-09-24).

6. **Build each installer on its own OS; the underlying packager does no cross-compilation, and foreign-format tasks skip silently. (non-negotiable)** A Linux runner never produces a disk image, and the skip looks like success. *Prevents:* empty release artifacts mistaken for green builds.
7. **Declare JDK modules explicitly; the packager does not infer them, and a missing module fails only at runtime in the shipped binary. (non-negotiable)** `ClassNotFoundException` in a packaged Notes app that ran fine via `run` is the signature of this trap. *Prevents:* runtime-only failures in shipped binaries.
8. **Run packaging on JDK 17 or newer and keep installer version shapes strict per format. (non-negotiable)** Older JDKs cannot run the packager, and each installer type rejects malformed versions. *Prevents:* packager failures at release time.
9. **Keep one stable Windows upgrade identifier forever; never regenerate it per release. (non-negotiable)** The installer uses it to recognise the installed Notes app, so a changed value installs a second copy instead of upgrading. *Prevents:* duplicate installs that never upgrade.
10. **Expect release packaging to minify with Compose keep rules while obfuscation stays off; reflection access needs extra configuration. (default)** Minified-but-unobfuscated is the default contract, so reflection that works in `run` can break in the packaged image. *Prevents:* release-only reflection crashes.
11. **Run the packaged image before publishing; plain `run` does not reproduce the minified runtime. (non-negotiable)** The smoke run is the only check that exercises the artifact users install. *Prevents:* shipping an image that never launched.

Verify gate: confirm the exact per-format packaging task names in the current Compose Multiplatform docs before wiring them into CI. The harvest ledger marks the commonly quoted names UNVERIFIED, so never write them from memory.

## 3. Signing

12. **Sign plus notarize every macOS distribution; unsigned downloads present as damaged. (non-negotiable)** Gatekeeper rejection is the default, not the exception, and custom entitlements files must retain the Java entries. *Prevents:* "app is damaged" reports on first launch.
13. **Keep iOS signing in Xcode with automatic style and the team set; never duplicate it in Gradle. (non-negotiable)** The Xcode build phase embeds the shared framework (confirm the exact embed task name in the current KMP docs before wiring; the ledger marks the commonly quoted name UNVERIFIED), and Xcode owns the signature. *Prevents:* signature conflicts between two signers.
14. **Read Android signing keys from the secret catalog or environment at build time; never commit keys or key files. (non-negotiable)** A committed keystore cannot be unshipped, and every fork inherits it. *Prevents:* leaked release keys (SKILL.md rule 7 pattern).

## 4. CI matrix

Shape follows the official KMP-App-Template per-target workflows, paraphrased generically (Apache-2.0): checkout plus Java setup plus Gradle setup on every leg.

15. **Fan CI out per target OS: Android assembly on a macOS runner, desktop assembly on Ubuntu, iOS `xcodebuild` on macOS with a pinned Xcode version. (non-negotiable)** One runner OS cannot cover all three signatures, and an unpinned Xcode drifts the iOS leg on every image update. *Prevents:* cross-OS builds that silently skip plus iOS breaks from Xcode drift.
16. **Pin checkout v4 plus Java-setup v4 with the Zulu 21 toolchain on every leg; never let legs diverge toolchains. (default)** Diverged JDKs make "works on Android CI, fails on desktop CI" the norm. *Prevents:* toolchain-drift failures across legs.
17. **Call the guard registry (`run-checks.sh`) before any assembly leg, per SKILL.md rule 10. (non-negotiable)** Guards that run after packaging bless artifacts built from violating code. *Prevents:* shipping guarded violations (SKILL.md rule 10).

## 5. Caches and toolchains

18. **Reuse the Gradle setup action cache on every leg and keep CI Gradle properties (daemon, parallel, configuration cache) checked in. (default)** Uncached legs pay full dependency resolution per OS, tripling CI time. *Prevents:* triple-cost CI without caching (see `enforcement.md` for the full caching rule, which owns it).
19. **Pin one Node version at the root for all Kotlin/JS and Wasm legs. (default)** Newer prebuilt runtimes need newer system libraries than CI images provide, so a floating Node breaks the web leg first. *Prevents:* web-leg failures from runtime drift.

## 6. Verify gates

- [ ] Each installer artifact exists on its own-OS runner; no leg reports success with zero artifacts.
- [ ] The packaged image launches and opens the Notes list before any publish step.
- [ ] macOS artifact is signed and notarized; Windows upgrade identifier matches the previous release.
- [ ] No signing key, keystore, or Apple ID credential is committed: `rg -n "keystore|KEYSTORE|appleID|teamID" --glob '*.gradle.kts' <project-root>` shows only environment or secret-catalog reads.
- [ ] Every per-format packaging task name and the Xcode framework-embed task name were confirmed in the current official docs during this task: yes or no.
