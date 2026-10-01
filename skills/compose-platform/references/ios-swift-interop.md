# iOS and Swift Interop

Load this when exposing Kotlin to Swift, embedding Compose in a SwiftUI app, or embedding native views in Compose.

## Interop choice

1. **(default) Use SKIE for `suspend` and `Flow` exposure in new projects.** SKIE turns `suspend` into Swift `async` and `Flow` into `AsyncSequence` with no annotations in the Kotlin code; hand-written collectors in platform source sets are a second bridge that rots. *Prevents:* parallel interop layers (see the `compose-platform` skill, rule 7).
2. **Check the compat gates before adding SKIE (non-negotiable).** Read the Kotlin and Swift versions in `gradle/libs.versions.toml` and the SKIE release notes; SKIE supports Kotlin 2.0.0–2.4.10 and Swift 5.8+ (Xcode 14.3+) — evidence https://skie.touchlab.co/intro. If the project sits outside that range, stop and report instead of adding it. *Prevents:* an interop plugin that silently breaks the iOS build.
3. **Apply the SKIE plugin only in the module that builds the Xcode framework (non-negotiable).** Plugin id `co.touchlab.skie` from Maven Central — evidence https://skie.touchlab.co/Installation. Applying it in feature or data modules multiplies build cost with no benefit. *Prevents:* SKIE running where no framework is produced.
4. **(default) Use KMP-NativeCoroutines only where the project already adopted it.** A recorded project decision keeps the annotations; new projects never add `@NativeCoroutinesState` / `@NativeCoroutinesFlow` clutter. *Prevents:* annotation clutter in greenfield code (see the `compose-platform` skill, rule 8).

- Without SKIE, `suspend` exports as completion-handler callbacks, and direct Swift `async` calling stays experimental — evidence https://kotlinlang.org/docs/native-objc-interop.html.
- SKIE generates genuine Swift `async` from `suspend` with two-way cancellation, callable from any thread.
- SKIE converts the `Flow` family into `AsyncSequence`-conforming Swift classes that preserve the generic type argument.

## Flow to Swift

9. **Expose UI state to Swift as `StateFlow`; tie collection to the Swift owner's lifecycle and consume UI-bound values on the main thread (non-negotiable).** A `StateFlow` always holds a current value and replays the latest to each new subscriber, so it is the natural fit for UI; a cold `Flow` has no initial value and only runs while collected, so it needs an explicit collection lifecycle (verified: https://kotlinlang.org/api/kotlinx.coroutines/kotlinx-coroutines-core/kotlinx.coroutines.flow/-state-flow/). SKIE converts both into `AsyncSequence`-conforming Swift classes (`SkieSwiftStateFlow`, `SkieSwiftFlow`) with two-way cancellation (verified: https://skie.touchlab.co/features/flows). Start collection from the Swift owner's task (a SwiftUI `.task` modifier is cancelled when the user leaves the screen) and consume UI-bound values on the main actor (`@MainActor`), as in the SKIE example. *Prevents:* a Swift screen with no value until the first emission, a leaked collector after the screen is gone, and UI updates off the main thread.

## SKIE limits

- `suspend` members of generic classes need the generated SKIE wrapper call; Swift overrides target the double-underscore rename, which breaks the cancellation bridge for nested `async` calls.
- SKIE `Flow`s cannot propagate custom exceptions without crashing, cannot be `as`-cast, support no custom types, convert in only one direction, and convert nothing inside nested generics or SKIE `suspend` return types.
- Nullable `Flow` arguments get separate `Optional` Swift classes with no inheritance between variants — convert only through the provided constructors.
- Without SKIE, sealed classes match through non-exhaustive `as?` chains, so a new subclass silently falls through; with SKIE, switch exhaustively so the compiler fails on a new subclass.
- Generic sealed classes never convert to Swift enums — expose concrete types (a notes-list state, not a generic list state) at the boundary.
- Nested sealed hierarchies flatten names in Swift, so confirm each case name at the call site instead of recalling it.

## ObjC boundary gotchas

5. **Declare every Kotlin exception a Swift caller may see in `Throws` (non-negotiable).** Undeclared exception types terminate the app; `suspend` without `Throws` forwards only `CancellationException`. *Prevents:* Swift-side crashes on ordinary failures.
6. **(default) Keep the iOS-exported surface small and concrete.** A plain `Unit` return exports as `Void`; `KotlinUnit` appears in function types such as callbacks and in generics, so narrow those surfaces. Limit mutable collections; hide internals with `HiddenFromObjC` and rename exports with `ObjCName`; link the framework statically (`isStatic`). https://kotlinlang.org/docs/native-objc-interop.html *Prevents:* awkward callback and generic bridges and double-copied collections.

- Kotlin enums export as classes with one property per entry, so every Swift `switch` over them needs a `default` case to compile.
- Kotlin collections cross into Swift through an Objective-C copy plus a Swift copy — batch results in Kotlin, never iterate across the boundary in a loop.
- Exported generic members read nullable in Swift unless the type parameter is constrained non-nullable (`T: Any`).
- Kotlin subclasses an Objective-C type only as a `final` class with identical constructor signatures via `OverrideInit`; non-`final` heirs of ObjC types are unsupported.
- Kotlin reaches Swift only through Objective-C-visible APIs; pure Swift modules with no ObjC export are unreachable.
- `KDoc` on exported declarations ships into the ObjC headers and Xcode completion; dependency `KDoc` needs the export-kdoc compiler option.

## Embedding

- Compose inside SwiftUI goes through a `MainViewController` returning `UIViewController`, wrapped in a `UIViewControllerRepresentable` struct.
- SwiftUI inside Compose cannot be written in Kotlin — wrap the SwiftUI view in a `UIHostingController` in Swift and pass its factory into the Kotlin entry point.
- `UIKitView` splits creation from sync: the factory lambda creates the `UIView` once, the update lambda syncs Compose state on recomposition — never recreate the view per recomposition and never skip `update`.
- The host `Info.plist` must set the high-refresh-rate key, otherwise the app crashes at runtime.
- Camera flows on device need the camera usage key in `Info.plist`, otherwise the app crashes at runtime.

## Shared ViewModel with native UI

7. **Switch to the plain `androidx.lifecycle` artifact declared as `api` and export it from the iOS framework (non-negotiable).** The Compose lifecycle artifact cannot back a native-UI host; without the plain artifact the shared ViewModel has no owner on iOS. *Prevents:* a shared ViewModel that native UI cannot observe.
8. **(default) Consider KMP-ObservableViewModel only when native SwiftUI screens observe a shared ViewModel.** It handles the iOS ViewModel lifecycle and store-owner boilerplate that SwiftUI observation needs; fully shared Compose UI never needs it. Evidence: https://www.jetbrains.com/help/kotlin-multiplatform-dev/compose-viewmodel.html ("no built-in ViewModelStoreOwner" on iOS; KMP-ObservableViewModel "lets SwiftUI observe Kotlin Multiplatform ViewModels directly"). *Prevents:* two observation bridges fighting over one ViewModel.
