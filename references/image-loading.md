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

## Table of Contents

- [Setup and Dependencies](#setup-and-dependencies)
- [Choose the Right API](#choose-the-right-api)
- [Default AsyncImage Pattern](#default-asyncimage-pattern)
- [ImageLoader Configuration](#imageloader-configuration)
- [Extended Pipeline](#extended-pipeline)
- [Caching Strategy](#caching-strategy)
- [Transformations](#transformations)
- [SVG](#svg)
- [Compose Multiplatform Resources](#compose-multiplatform-resources)
- [List and Shared-Element Patterns](#list-and-shared-element-patterns)
- [Preview, Testing, and Debugging](#preview-testing-and-debugging)
- [Do / Don't](#do--dont)

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
| Add request retry/short-circuit/global policy | `Interceptor` | Wraps entire pipeline and can modify/proceed/return early |
| Accept custom model type in `.data(...)` | `Mapper` | Maps domain model to supported data type (URI/String/etc.) |
| Keep custom data memory-cacheable | `Keyer` | Produces stable memory cache key segment for custom model |
| Support custom source/protocol | `Fetcher.Factory<T>` | Fetches bytes/image for unsupported data source |
| Decode custom encoded data/format | `Decoder.Factory` | Converts fetched source to renderable image |
| Add auth headers for all image requests | Network fetcher + client interceptor | Centralized networking behavior |
| Per-request dynamic headers | `ImageRequest.httpHeaders(...)` | Scoped request-level networking metadata |

### Component responsibilities

- `Interceptor`: cross-cutting behavior (timeouts, retries, custom cache layer, metrics).
- `Mapper`: data normalization (for example, `ProductImage -> String` URL).
- `Keyer`: stable keys for custom data to improve memory cache hits.
- `Fetcher`: data transport (custom scheme, signed URLs, alternate client).
- `Decoder`: format handling (custom binary/image format decode).

If your custom `Fetcher` introduces a new data type, add a matching `Keyer` so memory caching is effective.

### Mapper + Keyer pattern

```kotlin
data class ItemImage(val id: String, val url: String)

class ItemImageMapper : Mapper<ItemImage, String> {
    override fun map(data: ItemImage, options: Options): String = data.url
}

class ItemImageKeyer : Keyer<ItemImage> {
    override fun key(data: ItemImage, options: Options): String = "item-image-${data.id}"
}
```

### Custom fetcher pattern

Use a custom `Fetcher` when image location requires pre-resolution (for example: one request to obtain a signed URL, then fetch the image).

```kotlin
data class PartialUrl(val baseUrl: String)

class PartialUrlFetcher(
    private val data: PartialUrl,
    private val options: Options,
    private val imageLoader: ImageLoader,
) : Fetcher {
    override suspend fun fetch(): FetchResult? {
        // Resolve final URL from partial endpoint, then delegate to standard fetchers.
        val resolvedUrl: String = resolveImageUrl(data.baseUrl)
        val mapped = imageLoader.components.map(resolvedUrl, options)
        val output = imageLoader.components.newFetcher(mapped, options, imageLoader)
        val (fetcher) = checkNotNull(output) { "No supported fetcher" }
        return fetcher.fetch()
    }

    class Factory : Fetcher.Factory<PartialUrl> {
        override fun create(
            data: PartialUrl,
            options: Options,
            imageLoader: ImageLoader,
        ): Fetcher = PartialUrlFetcher(data, options, imageLoader)
    }
}
```

### Network fetcher customization

```kotlin
val imageLoader = ImageLoader.Builder(context)
    .components {
        add(
            OkHttpNetworkFetcherFactory(
                callFactory = { baseOkHttpClient.newBuilder().build() },
            )
        )
    }
    .build()
```

For HTTP cache semantics, register `CacheControlCacheStrategy` with the network fetcher if your app needs response `Cache-Control` behavior.

### Compose Multiplatform placement

- Keep domain-level model wrappers (`ItemImage`, mapping intent) in `commonMain`.
- Put platform networking client specifics (OkHttp setup, Android-only pieces) in platform source sets.
- Prefer Ktor network module for broad CMP support.
- Keep one shared `ImageLoader` configuration per app entry point.

### Pipeline anti-patterns

- Registering custom components per screen/composable instead of once in app-level `ImageLoader`.
- Adding custom `Fetcher` for new data without adding a stable `Keyer`, which degrades memory cache hit rate.
- Doing heavy blocking work inside `Interceptor` without clear bounds/timeouts.
- Encoding volatile data (timestamps/random values) into cache keys, causing constant cache misses.
- Duplicating behavior already solved by request options (`httpHeaders`, cache policy, size resolver).
- Mixing platform-only types into `commonMain` custom pipeline contracts.

## Caching Strategy

### Request-level cache controls

Use request policies only when you intentionally need behavior different from app defaults.

```kotlin
ImageRequest.Builder(LocalPlatformContext.current)
    .data(url)
    .memoryCachePolicy(CachePolicy.ENABLED)
    .diskCachePolicy(CachePolicy.ENABLED)
    .networkCachePolicy(CachePolicy.ENABLED)
    .build()
```

### Stable keys for smooth transitions

Use stable keys when the same logical image appears in multiple places (list -> detail, shared element).

```kotlin
ImageRequest.Builder(LocalPlatformContext.current)
    .data(url)
    .memoryCacheKey("image-$id")
    .placeholderMemoryCacheKey("image-$id")
    .build()
```

`placeholderMemoryCacheKey` helps avoid visual flashes by reusing an in-memory result as the placeholder for the next request.

## Transformations

Use image transformations only when you need pixel-level mutation of decoded output.

```kotlin
ImageRequest.Builder(LocalPlatformContext.current)
    .data(url)
    .transformations(RoundedCornersTransformation(16f))
    .build()
```

In Compose, prefer modifier-based visual shaping (for example `Modifier.clip(CircleShape)`) over decode-time transformations when possible. It is usually simpler and more efficient for UI-only presentation.

Important: transformations convert output to bitmap data; for animated images this can reduce output to a single frame.

## SVG

Add SVG support with the `coil-svg` artifact:

```kotlin
implementation("io.coil-kt.coil3:coil-svg:<version>")
```

Coil can auto-detect and decode SVGs after adding the dependency. If needed, you can explicitly register:

```kotlin
ImageLoader.Builder(context)
    .components {
        add(SvgDecoder.Factory())
    }
    .build()
```

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

## Do / Don't

### Do

- Prefer `AsyncImage` for most rendering use cases.
- Use one shared `ImageLoader`.
- Tune memory/disk cache once at loader creation.
- Use stable cache keys for list/detail/shared-element continuity.
- Provide meaningful `contentDescription` for non-decorative images.
- Use `Res.getUri(...)` for CMP bundled assets.

### Don't

- Create a new `ImageLoader` per screen or composable.
- Use `SubcomposeAsyncImage` everywhere, especially in large scrolling lists.
- Default to transformations for simple clipping/shape effects.
- Forget that Coil 3 needs an explicit network module.
- Disable caches globally without a measured reason.
- Treat error/fallback as optional for user-facing network images.
