# Composition-root sources (CMP shape, M-15)

Copy each file into the module shown. Replace `com.example` with the
project's `BASE_PACKAGE` (see `.composekit.conf`).

| Template file | Destination |
|---|---|
| `App.kt` | `composeApp/src/commonMain/kotlin/<pkg>/App.kt` |
| `AppModule.kt` | `composeApp/src/commonMain/kotlin/<pkg>/AppModule.kt` |
| `DesktopMain.kt` | `composeApp/src/jvmMain/kotlin/<pkg>/Main.kt` (rename on copy) |
| `MainViewController.kt` | `composeApp/src/iosMain/kotlin/<pkg>/MainViewController.kt` |
| `MainActivity.kt` | `androidApp/src/main/kotlin/<pkg>/MainActivity.kt` |
| `MainApplication.kt` | `androidApp/src/main/kotlin/<pkg>/MainApplication.kt` |
| `AndroidManifest.xml` (in `templates/modules/`) | `androidApp/src/main/AndroidManifest.xml` |

`App()` is the single entry every platform shell renders. `AppModule.kt`
aggregates every feature and data Koin module: extend its module list for
every scaffolded feature. Each `entry<>` builder resolves its
ViewModel with `koinViewModel()` and passes the instance into the Route;
each `onEffect` SEAM maps that feature's effects to back-stack calls.
The `iosApp` Xcode project is created from the official KMP wizard or
template, never scaffolded here; it calls `MainViewController()`.
