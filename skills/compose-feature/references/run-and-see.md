# Run and See

Load this before calling a change done when it alters what a user sees on a Notes destination. Compile checks and tests prove the wiring; only a running screen proves the result.

## Choose the target

1. The request names a target, or the change sits in that target's source set (`iosMain`, `desktopMain`) → use that target.
2. Otherwise → the first one you can run here: Android emulator, desktop, iOS simulator, browser.
3. None can run (CI, headless, no emulator or tool) → write `not run` and the reason in the answer, then stop.

## Rules

1. (non-negotiable) **Never report a visible change as working unless you ran it and looked; otherwise say `not run` and why.** A green build says nothing about whether the Notes list shows the right rows. *Prevents:* done claims on a screen nobody has seen. (RUN-01)
2. (non-negotiable) **Use only tools already on this machine.** Installing a CLI, an MCP server or a dependency for this check needs the user's yes. *Prevents:* a verification step that changes the project or the machine. (RUN-02)
3. (non-negotiable) **Use an emulator or simulator, and touch a physical device only when the user names it.** Installing a build can replace the user's real app and data. Pass the device serial whenever more than one device is attached. *Prevents:* a debug build overwriting the app on someone's phone. (RUN-03)
4. (default) **Open the changed destination, capture the screen, read the UI tree, then drive the one flow the request changed.** Confirm the requested text, control or state is there. A crash or blank screen is a failed check, so read the logs. A system dialog over the app is not a result, so dismiss it and capture again. *Prevents:* launching the app and reporting only that it started; a literal `\$count` on screen passes the compiler and every ViewModel test. (RUN-04)
5. (default) **Report the target you ran and what you saw; one target is enough unless the request names more.** A run proves that target only, so never claim another from it. *Prevents:* an Android run reported as iOS proof, and a device matrix nobody asked for. (RUN-05)

## Android

Use `:androidApp` in a CMP project and `:app` in an Android-only project. `<serial>` comes from `adb devices`.

| Step | With the `android` CLI | Without it |
|---|---|---|
| Start an emulator | `android emulator list`, then `android emulator start <name>` | Start it from Android Studio |
| Build, install, launch | `android run :androidApp --device=<serial>` | `./gradlew :androidApp:installDebug`, then `adb -s <serial> shell monkey -p <applicationId> 1` |
| Read the UI tree | `android layout --device=<serial> --pretty` (add `--full` for non-interactive nodes) | `adb -s <serial> shell uiautomator dump /sdcard/w.xml`, then `adb -s <serial> exec-out cat /sdcard/w.xml` |
| Capture the screen | `android screen capture --device=<serial> --output=ui.png` | `adb -s <serial> exec-out screencap -p > ui.png` |
| Tap or type | `android input --device=<serial> tap 'text=Save'`, `android input --device=<serial> text 'Groceries' 'clz=EditText'` | `adb -s <serial> shell input tap <x> <y>` |
| Logs | `adb -s <serial> logcat -d` | same |

`android preview` fails on a shared KMP module, because it needs the `com.android.application` or `com.android.library` plugin and those modules use the Android-KMP library plugin. Run the app instead. On an Android-only project it renders `@Preview` functions with no device, when run from the module directory. https://developer.android.com/tools/agents/android-cli (RUN-06, RUN-07)

For repeatable natural-language flows (Journeys), the android/skills `android-cli` skill goes deeper, if installed; optional depth only.

## Desktop

When the project has a desktop target and Compose Hot Reload, connect the MCP server through the Gradle task `hotMcpServer` (`:<module>:hotMcpServer<Target>` with several JVM targets), then use its `reload`, `take_screenshot`, `get_semantic_tree`, `click`, `type_text`, `get_ui_error` and `get_logs` tools. It is experimental; see the `compose-platform` skill, `desktop-and-web.md` rules 13–16. https://github.com/JetBrains/compose-hot-reload#mcp-server-for-ai-agents (RUN-08)

Without that server, `./gradlew :composeApp:run` starts the app but gives you no way to see it, so report `not run` unless another tool can capture the window.

## iOS

| Step | Command |
|---|---|
| Find the scheme and a simulator | `xcodebuild -list -project iosApp/iosApp.xcodeproj`, `xcrun simctl list devices available` |
| Build | `xcodebuild -project iosApp/iosApp.xcodeproj -scheme <scheme> -sdk iphonesimulator -derivedDataPath build/ios` |
| Boot, install, launch | `xcrun simctl boot <udid>`, `xcrun simctl install <udid> <path-to-.app>`, `xcrun simctl launch <udid> <bundle-id>` |
| Capture the screen | `xcrun simctl io <udid> screenshot ui.png` |

`simctl` cannot tap. To drive a flow, use `mobile-mcp`, Maestro or an equivalent only if one is already set up; otherwise report that you checked the first screen only. (RUN-09)

## Browser

Use a browser tool the agent already has on the `wasmJs` run; otherwise report `not run`.
