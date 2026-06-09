# Compose Multiplatform Resources

## Android R vs CMP Res

Android uses `R` — a generated class with integer IDs. Compose Multiplatform uses `Res` — a generated class with typed accessors. The API surface is intentionally similar, but the types and import paths differ.

| Concern | Android (Jetpack Compose) | Compose Multiplatform |
|---|---|---|
| Generated class | `R` (integer resource IDs) | `Res` (typed resource objects) |
| String access | `stringResource(R.string.app_name)` | `stringResource(Res.string.app_name)` |
| Drawable access | `painterResource(R.drawable.icon)` | `painterResource(Res.drawable.icon)` |
| Plural access | `pluralStringResource(R.plurals.items, count)` | `pluralStringResource(Res.plurals.items, count)` |
| Font access | `FontFamily(Font(R.font.inter))` | `FontFamily(Font(Res.font.inter))` |
| String array | `stringArrayResource(R.array.items)` | `stringArrayResource(Res.array.items)` |
| Resource directory | `res/` (under each source set) | `composeResources/` (under each source set) |
| Import path | `import com.example.app.R` | `import project.module.generated.resources.Res` |
| Suspend access | N/A | `getString(Res.string.app_name)` |
| Raw file access | `context.assets.open("file.bin")` | `Res.readBytes("files/file.bin")` |
| Platform URI | `ContentResolver` / asset URI | `Res.getUri("files/video.mp4")` |

**Import convention:** `{group}.{module}.generated.resources.Res`. Individual accessors imported separately:

```kotlin
import project.composeapp.generated.resources.Res
import project.composeapp.generated.resources.app_name
import project.composeapp.generated.resources.my_image
```

## Directory Structure

Place resources under `composeResources/` in the owning source set. `commonMain` for shared, platform source sets for platform-specific.

```text
commonMain/composeResources/
├── drawable/              PNG, JPG, BMP, WebP, Android XML vectors, SVG (all except Android)
│   ├── drawable-dark/     dark theme variants
│   └── drawable-xxhdpi/   density-specific variants
├── font/                  TTF, OTF
├── values/                strings.xml (strings, string-arrays, plurals) — base locale
│   ├── values-es/         Spanish
│   ├── values-fr/         French
│   └── values-ja/         Japanese
└── files/                 raw files, any sub-hierarchy
    └── myDir/data.json
```

Qualifiers use hyphens and can combine: `drawable-en-rUS-mdpi-dark`. Fallback: unqualified resource.

## Gradle Setup

```kotlin
kotlin {
    sourceSets {
        commonMain.dependencies {
            implementation(compose.components.resources)
        }
    }
}

compose.resources {
    publicResClass = true              // default: internal; needed for library modules
    packageOfResClass = "com.example.app.resources"  // default: {group}.{module}.generated.resources
    generateResClass = auto            // auto | always
}
```

For `androidLibrary` targets (AGP 8.8.0+), enable explicitly: `kotlin { androidLibrary { androidResources.enable = true } }`.

Build the project to generate/regenerate the `Res` class and typed accessors.

## Drawables and Images

Store in `composeResources/drawable/`. Use `painterResource` as the primary API — returns `Painter` for both raster and vector. Works synchronously except web (empty on first composition, then loads).

```kotlin
Image(painter = painterResource(Res.drawable.my_image), contentDescription = null)
val bitmap: ImageBitmap = imageResource(Res.drawable.photo)      // raster only
val vector: ImageVector = vectorResource(Res.drawable.ic_arrow)  // XML vector only
```

## Icons

Use Material Symbols XML icons from [Google Fonts Icons](https://fonts.google.com/icons). Download the Android XML variant, place in `composeResources/drawable/`, set `android:fillColor` to `#000000`, remove `android:tint`.

```kotlin
Image(
    painter = painterResource(Res.drawable.ic_settings),
    contentDescription = "Settings",
    modifier = Modifier.size(24.dp),
    colorFilter = ColorFilter.tint(MaterialTheme.colorScheme.onSurface),
)
```

## Strings, Templates, Arrays, and Plurals

Store in `composeResources/values/strings.xml`. Each element generates a typed accessor on `Res`.

| Type | XML | Composable API | Suspend API |
|---|---|---|---|
| String | `<string name="k">text</string>` | `stringResource(Res.string.k)` | `getString(Res.string.k)` |
| Template | `<string name="k">Hello, %1$s!</string>` | `stringResource(Res.string.k, name)` | `getString(Res.string.k, name)` |
| String array | `<string-array name="k"><item>A</item></string-array>` | `stringArrayResource(Res.array.k)` | `getStringArray(Res.array.k)` |
| Plurals | `<plurals name="k"><item quantity="one">%1$d item</item><item quantity="other">%1$d items</item></plurals>` | `pluralStringResource(Res.plurals.k, count, count)` | `getPluralString(Res.plurals.k, count, count)` |

Canonical example:

```xml
<resources>
    <string name="app_name">My App</string>
    <string name="welcome">Hello, %1$s! You have %2$d new messages.</string>
    <string-array name="categories">
        <item>Electronics</item>
        <item>Clothing</item>
    </string-array>
    <plurals name="items_count">
        <item quantity="one">%1$d item</item>
        <item quantity="other">%1$d items</item>
    </plurals>
</resources>
```

Special characters: `\n`, `\t`, `\uXXXX`. Unlike Android, no need to escape `@` or `?`. For plurals, the first `count` selects the form; additional args are format arguments. No functional difference between `$s` and `$d`. Supported quantities: `zero`, `one`, `two`, `few`, `many`, `other` — not all apply to every language.

## Fonts

Store `.ttf`/`.otf` in `composeResources/font/`. `Font()` is a **composable** in CMP (unlike Android), so dependent `TextStyle`/`Typography` construction must also be composable:

```kotlin
@Composable
fun AppTypography(): Typography {
    val fontFamily = FontFamily(
        Font(Res.font.Inter_Regular, FontWeight.Normal),
        Font(Res.font.Inter_Bold, FontWeight.Bold),
    )
    return MaterialTheme.typography.copy(
        bodyLarge = MaterialTheme.typography.bodyLarge.copy(fontFamily = fontFamily),
        titleLarge = MaterialTheme.typography.titleLarge.copy(fontFamily = fontFamily, fontWeight = FontWeight.Bold),
    )
}
```

## Raw Files and URIs

Place arbitrary files in `composeResources/files/` with any sub-hierarchy.

```kotlin
// Read bytes (suspend)
val bytes = Res.readBytes("files/data.json")

// Convert to images
val bitmap: ImageBitmap = bytes.decodeToImageBitmap()
val vector: ImageVector = bytes.decodeToImageVector(LocalDensity.current)
val painter: Painter = bytes.decodeToSvgPainter(LocalDensity.current)  // all platforms except Android

// Get platform URI for external APIs (WebView, media players)
val uri: String = Res.getUri("files/intro.mp4")
```

Since CMP 1.7.0, multiplatform resources are packed into Android assets — enabling `@Preview` and `WebView`/media access via URI.

## Qualifiers Reference

| Qualifier | Format | Example |
|---|---|---|
| Language / region | ISO 639-1/2; optional `r` + ISO 3166-1-alpha-2 | `values-es/`, `values-fra/`, `values-es-rMX/` |
| Theme | `light` or `dark` | `drawable-dark/` |
| Density | `ldpi`/`mdpi`/`hdpi`/`xhdpi`/`xxhdpi`/`xxxhdpi` | `drawable-xxhdpi/` |

`stringResource()` automatically selects the correct locale at runtime — no code changes needed.

## Remote Images

For loading images from URLs, use a dedicated library — multiplatform resources are for bundled assets only. See [image-loading.md](image-loading.md).

## MVI Integration

**Rule: semantic keys in state, resource resolution in UI.** ViewModels use enums/semantic values — never resolved strings or resource IDs. UI maps semantic keys to `stringResource()`/`painterResource()` at render time.

```kotlin
enum class ErrorKey { NetworkError, InvalidInput, Unauthorized }
data class ProfileState(val userName: String = "", val error: ErrorKey? = null)

state.error?.let { key ->
    Text(stringResource(when (key) {
        ErrorKey.NetworkError -> Res.string.error_network
        ErrorKey.InvalidInput -> Res.string.error_invalid_input
        ErrorKey.Unauthorized -> Res.string.error_unauthorized
    }))
}
```

For full MVI ViewModel collection pattern, see [architecture.md](architecture.md).

## Rules

- Use `composeResources/` for all shared strings, images, fonts, and raw files
- Use typed accessors (`Res.string.name`) for compile-time safety
- Use qualifiers for localization (`values-es/`), theme (`drawable-dark/`), density (`drawable-xxhdpi/`)
- Keep resource resolution in composables — call `stringResource()`/`painterResource()` at render time
- Use suspend variants (`getString()`, `getPluralString()`) for non-composable contexts
- Set `publicResClass = true` when sharing resources from a library module
- Use semantic keys/enums in state; map to resources in UI
- Never resolve strings or load resources inside reducers or ViewModels
- Never use Android `R.string`/`R.drawable` in `commonMain` — use `Res`
- Never place platform-only assets (Android adaptive icons, iOS asset catalogs) in `composeResources/`
- Rebuild after adding new resources — the `Res` class needs regeneration
