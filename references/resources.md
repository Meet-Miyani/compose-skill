# Compose Multiplatform Resources

## Table of Contents

- [Android R vs CMP Res](#android-r-vs-cmp-res)
- [Directory Structure](#directory-structure)
- [Gradle Setup](#gradle-setup)
- [Drawables and Images](#drawables-and-images)
- [Icons](#icons)
- [Strings](#strings)
- [String Templates](#string-templates)
- [String Arrays](#string-arrays)
- [Plurals](#plurals)
- [Fonts](#fonts)
- [Raw Files](#raw-files)
- [Qualifiers](#qualifiers)
- [Localization](#localization)
- [Generated Resource Maps](#generated-resource-maps)
- [Android Assets Interop](#android-assets-interop)
- [External Libraries and Remote Files](#external-libraries-and-remote-files)
- [MVI Integration](#mvi-integration)
- [Do / Don't](#do--dont)

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

**Import convention:** The generated import follows the pattern `{group}.{module}.generated.resources.Res`. Individual resource accessors are imported separately:

```kotlin
import project.composeapp.generated.resources.Res
import project.composeapp.generated.resources.app_name
import project.composeapp.generated.resources.my_image
```

## Directory Structure

Place resources under `composeResources/` in the source set that owns them. `commonMain` for shared resources, platform source sets for platform-specific ones.

```text
commonMain/composeResources/
├── drawable/          PNG, JPG, BMP, WebP, Android XML vectors, SVG (all platforms except Android)
├── font/              TTF, OTF
├── values/            strings.xml (strings, string-arrays, plurals)
│   └── strings.xml
└── files/             raw files, any sub-hierarchy
    └── myDir/
        └── data.json
```

Qualified directories for localization, theme, and density use hyphens:

```text
commonMain/composeResources/
├── drawable/              default drawables
├── drawable-dark/         dark theme variants
├── drawable-xxhdpi/       density-specific variants
├── values/                default strings (base locale)
├── values-es/             Spanish strings
├── values-fr/             French strings
└── values-ja/             Japanese strings
```

## Gradle Setup

### Dependency

Add the resource library to `commonMain`:

```kotlin
kotlin {
    sourceSets {
        commonMain.dependencies {
            implementation(compose.components.resources)
        }
    }
}
```

### Accessor class configuration

Customize the generated `Res` class in the `compose.resources {}` block:

```kotlin
compose.resources {
    publicResClass = true              // default: internal
    packageOfResClass = "com.example.app.resources"  // default: {group}.{module}.generated.resources
    generateResClass = auto            // auto | always
}
```

- `publicResClass = true` — makes `Res` public (needed for library modules exposing resources)
- `packageOfResClass` — controls the package of the generated class
- `generateResClass = always` — forces generation even when the resource library is only a transitive dependency

### Android library target

For `androidLibrary` targets (AGP 8.8.0+), enable resource support explicitly:

```kotlin
kotlin {
    androidLibrary {
        androidResources.enable = true
    }
}
```

Build the project (or re-import in IDE) to generate/regenerate the `Res` class and all typed accessors.

## Drawables and Images

Store images in `composeResources/drawable/`. Supported formats: PNG, JPG, BMP, WebP, Android XML vectors. SVG is supported on all platforms except Android.

### painterResource — primary API

Returns a `Painter` (either `BitmapPainter` for raster or `VectorPainter` for XML vectors). Works synchronously on all targets except web (web returns empty `Painter` on first composition, then loads).

```kotlin
Image(
    painter = painterResource(Res.drawable.my_image),
    contentDescription = null,
)
```

### imageResource — rasterized bitmap

```kotlin
val bitmap: ImageBitmap = imageResource(Res.drawable.photo)
```

### vectorResource — XML vector

```kotlin
val vector: ImageVector = vectorResource(Res.drawable.ic_arrow)
```

## Icons

Use Material Symbols XML icons from [Google Fonts Icons](https://fonts.google.com/icons):

1. Download the Android XML variant of the icon
2. Place it in `composeResources/drawable/`
3. Set `android:fillColor` to `#000000` and remove `android:tint` or other Android-specific color attributes

```kotlin
Image(
    painter = painterResource(Res.drawable.ic_settings),
    contentDescription = "Settings",
    modifier = Modifier.size(24.dp),
    colorFilter = ColorFilter.tint(MaterialTheme.colorScheme.onSurface),
)
```

## Strings

Store strings in XML files inside `composeResources/values/`. Each `<string>` element generates a typed accessor on `Res.string`.

```xml
<resources>
    <string name="app_name">My App</string>
    <string name="save_label">Save</string>
</resources>
```

### Composable access

```kotlin
Text(stringResource(Res.string.app_name))
```

### Suspend access (outside composition)

```kotlin
coroutineScope.launch {
    val name = getString(Res.string.app_name)
}
```

Special characters: `\n` (newline), `\t` (tab), `\uXXXX` (Unicode). Unlike Android, no need to escape `@` or `?`.

## String Templates

Use `%<number>$s` or `%<number>$d` placeholders. There is no functional difference between `$s` and `$d` — both accept any argument type.

```xml
<resources>
    <string name="welcome">Hello, %1$s! You have %2$d new messages.</string>
</resources>
```

```kotlin
Text(stringResource(Res.string.welcome, userName, messageCount))
```

## String Arrays

Group related strings into `<string-array>` elements. Accessed as `List<String>`.

```xml
<resources>
    <string-array name="categories">
        <item>Electronics</item>
        <item>Clothing</item>
        <item>Books</item>
    </string-array>
</resources>
```

```kotlin
val categories: List<String> = stringArrayResource(Res.array.categories)
```

Suspend variant:

```kotlin
val categories = getStringArray(Res.array.categories)
```

## Plurals

Use `<plurals>` for quantity-dependent strings. Supported quantities: `zero`, `one`, `two`, `few`, `many`, `other`. Not all quantities apply to every language — rely on locale rules.

```xml
<resources>
    <plurals name="items_count">
        <item quantity="one">%1$d item</item>
        <item quantity="other">%1$d items</item>
    </plurals>
</resources>
```

```kotlin
Text(pluralStringResource(Res.plurals.items_count, count, count))
```

The first `count` selects the plural form; the second `count` is the format argument for `%1$d`.

Suspend variant:

```kotlin
val text = getPluralString(Res.plurals.items_count, count, count)
```

## Fonts

Store `.ttf` or `.otf` files in `composeResources/font/`.

### Loading a font

`Font()` is a composable in CMP (unlike Android where it is a regular function):

```kotlin
@Composable
fun Font(
    resource: FontResource,
    weight: FontWeight = FontWeight.Normal,
    style: FontStyle = FontStyle.Normal,
): Font
```

### Building a FontFamily and Typography

```kotlin
@Composable
fun AppTypography(): Typography {
    val fontFamily = FontFamily(
        Font(Res.font.Inter_Regular, FontWeight.Normal),
        Font(Res.font.Inter_Bold, FontWeight.Bold),
    )
    return MaterialTheme.typography.copy(
        bodyLarge = MaterialTheme.typography.bodyLarge.copy(fontFamily = fontFamily),
        bodyMedium = MaterialTheme.typography.bodyMedium.copy(fontFamily = fontFamily),
        titleLarge = MaterialTheme.typography.titleLarge.copy(
            fontFamily = fontFamily,
            fontWeight = FontWeight.Bold,
        ),
    )
}
```

Since `Font()` is composable in CMP, any dependent `TextStyle` / `Typography` construction must also be composable.

## Raw Files

Place arbitrary files in `composeResources/files/` with any sub-hierarchy.

### Read bytes

```kotlin
var bytes by remember { mutableStateOf(ByteArray(0)) }
LaunchedEffect(Unit) {
    bytes = Res.readBytes("files/data.json")
}
```

Suspend variant:

```kotlin
coroutineScope.launch {
    val bytes = Res.readBytes("files/config.json")
}
```

### Convert to images

```kotlin
// Bitmap (PNG, JPG, BMP, WebP)
val bitmap: ImageBitmap = bytes.decodeToImageBitmap()
Image(bitmap, contentDescription = null)

// Android XML vector
val vector: ImageVector = bytes.decodeToImageVector(LocalDensity.current)
Image(vector, contentDescription = null)

// SVG (all platforms except Android)
val painter: Painter = bytes.decodeToSvgPainter(LocalDensity.current)
Image(painter, contentDescription = null)
```

## Qualifiers

Qualifiers customize resources per environment. Add them to directory names with hyphens.

### Supported qualifiers (in priority order)

| Qualifier | Format | Example directory |
|---|---|---|
| Language | ISO 639-1 (2-letter) or ISO 639-2 (3-letter) | `values-es/`, `values-fra/` |
| Region | lowercase `r` + ISO 3166-1-alpha-2 | `values-es-rMX/`, `values-en-rGB/` |
| Theme | `light` or `dark` | `drawable-dark/` |
| Density | `ldpi`, `mdpi`, `hdpi`, `xhdpi`, `xxhdpi`, `xxxhdpi` | `drawable-xxhdpi/` |

Qualifiers can be combined: `drawable-en-rUS-mdpi-dark`

If a qualified resource is not found, the default (unqualified) resource is used as fallback.

### Density values

| Qualifier | DPI | Scale |
|---|---|---|
| `ldpi` | 120 | 0.75x |
| `mdpi` | 160 | 1x |
| `hdpi` | 240 | 1.5x |
| `xhdpi` | 320 | 2x |
| `xxhdpi` | 480 | 3x |
| `xxxhdpi` | 640 | 4x |

## Localization

### Directory convention

```text
commonMain/composeResources/
├── values/              default / base locale
│   └── strings.xml
├── values-es/           Spanish
│   └── strings.xml
├── values-fr/           French
│   └── strings.xml
└── values-ja/           Japanese
    └── strings.xml
```

### Base locale strings (values/strings.xml)

```xml
<resources>
    <string name="app_name">My App</string>
    <string name="greeting">Hello, world!</string>
    <string name="welcome">Welcome, %1$s!</string>
</resources>
```

### Localized strings (values-es/strings.xml)

```xml
<resources>
    <string name="app_name">Mi Aplicación</string>
    <string name="greeting">¡Hola mundo!</string>
    <string name="welcome">¡Bienvenido, %1$s!</string>
</resources>
```

`stringResource()` automatically selects the correct locale at runtime. No code changes are needed — locale resolution is handled by the framework.

## Generated Resource Maps

CMP generates maps keyed by resource filename for dynamic access:

```kotlin
val Res.allDrawableResources: Map<String, DrawableResource>
val Res.allStringResources: Map<String, StringResource>
val Res.allStringArrayResources: Map<String, StringArrayResource>
val Res.allPluralStringResources: Map<String, PluralStringResource>
val Res.allFontResources: Map<String, FontResource>
```

```kotlin
Image(
    painterResource(Res.allDrawableResources["my_icon"]!!),
    contentDescription = null,
)
```

Use these for data-driven resource selection (e.g., loading icons by name from a config). Prefer typed accessors (`Res.drawable.my_icon`) for static usage.

## Android Assets Interop

Since Compose Multiplatform 1.7.0, all multiplatform resources are packed into Android assets. This enables:

- Android Studio `@Preview` for CMP composables in Android source sets
- Direct access from `WebView` and media components via URI

### Res.getUri

```kotlin
val uri: String = Res.getUri("files/index.html")
```

Use this to pass resource paths to external libraries or platform APIs that accept URIs:

```kotlin
// WebView loading a bundled HTML page
AndroidView(
    factory = { context ->
        WebView(context).apply {
            layoutParams = ViewGroup.LayoutParams(MATCH_PARENT, MATCH_PARENT)
        }
    },
    update = { webView ->
        webView.loadUrl(Res.getUri("files/webview/index.html"))
    },
)
```

For non-Android platforms, `Res.getUri()` still returns a valid platform-specific path.

## External Libraries and Remote Files

### Passing resources to other libraries

Use `Res.getUri()` to get a platform-specific path any external API can consume:

```kotlin
val videoUri = Res.getUri("files/intro.mp4")
// Pass videoUri to a media player library
```

### Remote images

For loading images from URLs, use a dedicated library — multiplatform resources are for bundled assets only:

- [Coil](https://coil-kt.github.io/coil/) (recommended for Compose)
- [Compose ImageLoader](https://github.com/qdsfdhvh/compose-imageloader)
- [Kamel](https://github.com/Kamel-Media/Kamel)

## MVI Integration

Resources follow the same MVI principle: **ViewModels operate on semantic values, UI resolves display strings and images at render time**.

### Semantic keys in state, resolution in UI

```kotlin
// Contract — reducer uses enums, never resolved strings
enum class ErrorKey { NetworkError, InvalidInput, Unauthorized }

data class ProfileState(
    val userName: String = "",
    val error: ErrorKey? = null,
)

// Screen — UI resolves the resource
@Composable
fun ProfileScreen(state: ProfileState) {
    state.error?.let { key ->
        val message = when (key) {
            ErrorKey.NetworkError -> stringResource(Res.string.error_network)
            ErrorKey.InvalidInput -> stringResource(Res.string.error_invalid_input)
            ErrorKey.Unauthorized -> stringResource(Res.string.error_unauthorized)
        }
        Text(message, color = MaterialTheme.colorScheme.error)
    }
}
```

### Formatting with template strings

```kotlin
// Reducer sets: state = state.copy(itemCount = 42)
// UI resolves:
Text(pluralStringResource(Res.plurals.items_count, state.itemCount, state.itemCount))
```

### Images and icons

```kotlin
// Reducer sets: state = state.copy(status = OrderStatus.Shipped)
// UI resolves:
val icon = when (state.status) {
    OrderStatus.Pending -> Res.drawable.ic_pending
    OrderStatus.Shipped -> Res.drawable.ic_shipped
    OrderStatus.Delivered -> Res.drawable.ic_delivered
}
Image(painterResource(icon), contentDescription = null)
```

### Why this matters

- Reducers stay pure and testable — no platform dependency on resource resolution
- Localization changes require zero ViewModel/reducer modifications
- Tests assert on semantic keys, not locale-dependent strings

## Do / Don't

### Do

- Use `composeResources/` for all shared strings, images, fonts, and raw files
- Use typed accessors (`Res.string.name`) for compile-time safety
- Use qualifiers for localization (`values-es/`), theme (`drawable-dark/`), and density (`drawable-xxhdpi/`)
- Keep resource resolution in composables — call `stringResource()` / `painterResource()` at render time
- Use `Res.getUri()` when passing resources to platform APIs or external libraries
- Use suspend variants (`getString()`, `getPluralString()`) for non-composable contexts
- Set `publicResClass = true` when sharing resources from a library module
- Use semantic keys/enums in state; map to resources in UI

### Don't

- Resolve strings or load resources inside reducers or ViewModels
- Use Android `R.string` / `R.drawable` in `commonMain` — use `Res` instead
- Store resolved display strings in state — store semantic keys
- Use `Res.allDrawableResources["name"]!!` for static known resources — use typed `Res.drawable.name`
- Place platform-only assets (Android adaptive icons, iOS asset catalogs) in `composeResources/` — keep them in their platform source sets
- Hardcode locale-specific text in code — use qualified `values-{lang}/` directories
- Forget to rebuild after adding new resources — the `Res` class needs regeneration
