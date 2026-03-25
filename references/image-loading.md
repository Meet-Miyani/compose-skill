# Image Loading (Coil 3 + Compose Multiplatform)

Production-focused guidance for loading remote and local images in Jetpack Compose and Compose Multiplatform using Coil 3.

References:
- [Coil Compose docs](https://coil-kt.github.io/coil/compose/)
- [Coil Getting Started](https://coil-kt.github.io/coil/getting_started/)
- [Coil Image Loaders](https://coil-kt.github.io/coil/image_loaders/)
- [Coil Network Images](https://coil-kt.github.io/coil/network/)
- [Coil Extending the Image Pipeline](https://raw.githubusercontent.com/coil-kt/coil/main/docs/image_pipeline.md)
- [Coil SVG support](https://coil-kt.github.io/coil/svgs/)
- [Coil Recipes](https://coil-kt.github.io/coil/recipes/)
- [Coil 3 upgrade notes](https://coil-kt.github.io/coil/upgrading_to_coil3/)

## Setup and Dependencies

Coil 3 does not include network loading by default. Add `coil-compose` and exactly one network integration.

```kotlin
// Shared for Compose UI
implementation("io.coil-kt.coil3:coil-compose:<version>")

// Android/JVM only
implementation("io.coil-kt.coil3:coil-network-okhttp:<version>")

// Multiplatform-friendly network options
implementation("io.coil-kt.coil3:coil-network-ktor2:<version>")
// or
implementation("io.coil-kt.coil3:coil-network-ktor3:<version>")
```

If you use Ktor networking, add platform engines for your targets (Android, Apple, JVM).

## Choose the Right API

| Use case | Best API | Why |
|---|---|---|
| Most image rendering in UI | `AsyncImage` | Best default; resolves image size from constraints |
| Need a `Painter` or manual request restart/state observation | `rememberAsyncImagePainter` | More control, lower-level painter API |
| Need composable slots per loading state and need first-frame state correctness | `SubcomposeAsyncImage` | Slot API with immediate state, but slower |

### Performance note

`SubcomposeAsyncImage` uses subcomposition and is generally less suitable for dense `LazyColumn`/`LazyGrid` cells. Prefer `AsyncImage` for list-heavy screens.

## Default AsyncImage Pattern

Prefer one reusable pattern for avatar/card/list images:

```kotlin
AsyncImage(
    model = ImageRequest.Builder(LocalPlatformContext.current)
        .data(imageUrl)
        .crossfade(true)
        .build(),
    placeholder = painterResource(Res.drawable.placeholder),
    error = painterResource(Res.drawable.image_error),
    fallback = painterResource(Res.drawable.image_fallback),
    contentDescription = title, // null only for decorative images
    contentScale = ContentScale.Crop,
    modifier = Modifier.clip(RoundedCornerShape(12.dp)),
)
```

For accessibility, provide `contentDescription` unless the image is purely decorative.

## ImageLoader Configuration

Create one shared `ImageLoader` per app process. Multiple loaders fragment memory/disk caches and reduce hit rates.

```kotlin
setSingletonImageLoaderFactory { context ->
    ImageLoader.Builder(context)
        .crossfade(true)
        .memoryCache {
            MemoryCache.Builder()
                .maxSizePercent(context, 0.25)
                .build()
        }
        .diskCache {
            DiskCache.Builder()
                .directory(context.cacheDir.resolve("image_cache"))
                .maxSizePercent(0.02)
                .build()
        }
        .build()
}
```

For libraries, prefer `coil-core` and pass your own `ImageLoader` instead of overriding the app singleton.

## Extended Pipeline

Coil's pipeline is extensible and executes in this order:

1. `Interceptor`
2. `Mapper`
3. `Keyer`
4. `Fetcher`
5. `Decoder`

Register custom components once when building `ImageLoader`:

```kotlin
val imageLoader = ImageLoader.Builder(context)
    .components {
        add(CustomCacheInterceptor())
        add(ItemMapper())
        add(ItemKeyer())
        add(PartialUrlFetcher.Factory())
        add(SvgDecoder.Factory())
    }
    .build()
```

### Decision table: Need X -> Customize Y

| Need | Customize | Why |
|---|---|---|
| Add request retry/short-circuit/global policy | `Interceptor` | Wraps entire pipeline; can modify/proceed/return early. Cross-cutting: timeouts, retries, custom cache layer, metrics. |
| Accept custom model type in `.data(...)` | `Mapper` | Normalizes domain data to a supported type (for example `ProductImage` → URL string). |
| Keep custom data memory-cacheable | `Keyer` | Stable memory cache key segment for custom models. If a custom `Fetcher` introduces a new data type, add a matching `Keyer` so memory caching works. |
| Support custom source/protocol | `Fetcher.Factory<T>` | Data transport: custom scheme, signed URLs, alternate client. |
| Decode custom encoded data/format | `Decoder.Factory` | Converts fetched source to a renderable image. |
| Add auth headers for all image requests | Network fetcher + client interceptor | Centralized networking behavior. |
| Per-request dynamic headers | `ImageRequest.httpHeaders(...)` | Scoped request-level networking metadata. |

### Compose Multiplatform placement

- Domain-level model wrappers and mapping intent in `commonMain`; OkHttp/Android-only client setup in platform source sets; prefer Ktor network for broad CMP.
- One shared `ImageLoader` configuration per app entry point.

### Pipeline anti-patterns

| Anti-pattern | Problem |
|---|---|
| Registering pipeline components per screen/composable; duplicating what request options already cover (`httpHeaders`, cache policy, size resolver) | Fragments caches; redundant complexity |
| Custom `Fetcher` without a stable `Keyer`; volatile data (timestamps, random values) in cache keys | Poor memory cache hit rate |
| Heavy blocking work in `Interceptor` without bounds/timeouts; platform-only types in `commonMain` pipeline contracts | Jank; wrong layering for CMP |

For HTTP cache semantics with OkHttp, register `CacheControlCacheStrategy` with the network fetcher when you need response `Cache-Control` behavior.

## Caching Strategy

Default request cache policies are enabled; override `memoryCachePolicy` / `diskCachePolicy` / `networkCachePolicy` only when you need non-default behavior.

### Stable keys for smooth transitions

Use stable keys when the same logical image appears in multiple places (list → detail, shared element).

```kotlin
ImageRequest.Builder(LocalPlatformContext.current)
    .data(url)
    .memoryCacheKey("image-$id")
    .placeholderMemoryCacheKey("image-$id")
    .build()
```

`placeholderMemoryCacheKey` helps avoid visual flashes by reusing an in-memory result as the placeholder for the next request.

## Transformations

Use `.transformations(...)` (for example `RoundedCornersTransformation`) only for pixel-level changes to decoded output. Prefer `Modifier.clip` / shapes for UI-only effects; transformations materialize bitmaps and can collapse animated images to one frame.

## SVG

```kotlin
implementation("io.coil-kt.coil3:coil-svg:<version>")
```

Coil auto-detects and decodes SVGs after this dependency is on the classpath. Register `SvgDecoder.Factory()` explicitly only if you need non-default wiring.

## Compose Multiplatform Resources

To load images from Compose Multiplatform resources with Coil, use `Res.getUri(...)`:

```kotlin
AsyncImage(
    model = Res.getUri("drawable/sample.jpg"),
    contentDescription = null,
)
```

Use string URIs from `Res.getUri`. Direct compile-safe handles like `Res.drawable.someImage` are not currently passed directly as Coil models.

## List and Shared-Element Patterns

- Prefer `AsyncImage` in list cells.
- Keep item size predictable to avoid layout thrash.
- Use stable item keys (`LazyColumn`/`LazyGrid`) and stable cache keys (`memoryCacheKey`) together.
- For shared-element transitions, reuse memory cache key + placeholder memory cache key between source and destination.
- If you must use `rememberAsyncImagePainter`, provide a size resolver (`rememberConstraintsSizeResolver`) to avoid always loading original size.

## Preview, Testing, and Debugging

- Compose preview has no network access by default. Use `LocalAsyncImagePreviewHandler` to inject deterministic preview images.
- Enable `DebugLogger` only in debug builds when diagnosing request/decoder/cache behavior.
- For testability in large apps, inject a custom/fake `ImageLoader` instead of relying on global singleton state.
