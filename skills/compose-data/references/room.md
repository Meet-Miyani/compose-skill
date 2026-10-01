# Room (KMP)

Load this when touching a `@Dao`, `@Query`, `@Database`, migration, Room transaction, or Room-backed cache in shared code.

Setup, queries, transactions, relations, indexes, migrations. API shape always re-checked against the KMP Room page and the version in `gradle/libs.versions.toml`.

## Version gate

1. (non-negotiable) **If `libs.versions.toml` shows Room below 2.7.0, the first KMP-stable release per the official release notes, stop and report instead of writing Room KMP code.** Pre-2.7.0 Room has no shared KMP runtime, so remembered KMP APIs do not exist there. *Prevents:* code written against an API the pinned version never shipped.

## Setup shape

2. (non-negotiable) **`@Database` + `@ConstructedBy` live in `commonMain`; the `RoomDatabase.Builder` comes from per-platform source sets; shared code only configures (`setDriver`, query context) and calls `build`.** The filesystem path differs per platform, so only the builder construction is platform code. *Prevents:* `commonMain` that cannot resolve a file path on iOS or desktop.
3. (default) **Re-verify the builder entry point against the KMP Room page before writing setup code; the docs own the signature, this file owns the split.** A remembered entry point the pinned version renamed does not compile. *Prevents:* setup code written against a renamed builder entry point.
4. (non-negotiable) **Configure the database with `BundledSQLiteDriver` unless the project records another driver choice.** It ships SQLite from source, giving one consistent SQLite version on every target. *Prevents:* OS-version-dependent SQL behavior across targets.
5. (non-negotiable) **The database instance is one Koin `single`, built once and shared.** A second builder call opens a second connection pool against the same file. *Prevents:* two pools writing to one file with separate caches.

## DAOs and queries

6. (non-negotiable) **KMP `@Dao` functions are `suspend`, return `Flow`, or return `PagingSource` with room-paging.** Room Paging became KMP in 2.7.0-alpha08; use the pinned version's release notes. https://developer.android.com/jetpack/androidx/releases/room *Prevents:* blocking calls starving the writer connection or excluding supported paging.
7. (default) **Keep `@Query` SQL compile-verified by building after every query change; Room validates SQL at compile time, so a green build is the query test.**
8. (default) **Page unbounded scrolling (notes list, catalog list) through Paging against the DAO source; never `SELECT *` with no limit into a list the UI holds whole.**
9. (non-negotiable) **Prefer `@Upsert` over hand-rolled `REPLACE` semantics where foreign keys exist.** `REPLACE` deletes then re-inserts, firing cascading deletes on child rows that an update would have kept. *Prevents:* child rows of a note (tags, links) vanishing on a parent refresh.

## Relations and converters

10. (non-negotiable) **Every `@Relation` read runs under `@Transaction`.** Relation children are fetched by separate queries; without the transaction a concurrent write lands between parent and child reads. *Prevents:* a note detail showing tags from before the edit it just saved.
11. (default) **Map relations used by one screen into that screen's relation holder; no reusable mega-holder with every relation a note ever has.**
12. (non-negotiable) **Domain carries `kotlin.time.Instant`; store it as epoch millis through converters, and keep stored values to simple mappings — normalized tables over JSON blobs.** A blob column cannot be queried or indexed, so filtering moves into memory on every read. *Prevents:* full-table scans for a date filter the database could have served.
13. (default) **Converters convert and nothing else: no formatting, no defaults for absent values, no parsing that invents data (absence stays absent per the data skill).**

## Indexes

14. (default) **Index queried and foreign-key columns; skip indexes on tiny lookup tables where a scan costs less than index upkeep.**
15. (default) **In composite indexes put the most selective column first, so the common notes-by-tag-and-date query narrows early.**

## Transactions

16. (non-negotiable) **KMP writes use `useWriterConnection` + `immediateTransaction`; `withTransaction` never appears in `commonMain`.** `withTransaction` is Android-only; it fails shared compilation on every other target. *Prevents:* shared code that compiles on Android only.
17. (default) **Reach for `deferredTransaction` only when the block may not write at all; `immediateTransaction` stays the common case.**
18. (non-negotiable) **Multi-query atomicity inside a `@Dao` goes on the DAO function with `@Transaction`.** Two sequential DAO calls from a repository are two transactions with a visible gap between them. *Prevents:* a crash between "delete old tags" and "insert new tags" leaving a note tagless.

## Migrations

19. (non-negotiable) **Every version bump ships a versioned `Migration` object or an `AutoMigration`; exported schema stays in version control.** Without the schema history a migration cannot be generated or tested. *Prevents:* upgrades that crash on launch with no path back.
20. (default) **Use `AutoMigration` for schema changes, including renames and deletes with an `AutoMigrationSpec`; hand-write `Migration` for data moves.** https://developer.android.com/training/data-storage/room/migrating-db-versions *Prevents:* unnecessary hand migrations and lost row transforms.
21. (non-negotiable) **Destructive fallback is early-development only and never the sole strategy.** It deletes user notes on upgrade to avoid writing a migration. *Prevents:* shipping data loss as a migration policy.

## Boundary

22. (non-negotiable) **Entities never reach the UI; the repository maps them to domain before returning.** An entity in a ViewModel turns a column rename into a UI change (see the `compose-data` skill, rule 1). *Prevents:* wire rename becoming a UI change.

## Red flags

| Thought | Reality |
|---|---|
| "I will call `withTransaction` in `commonMain`; it worked on Android." | No. Rule 16: Android-only. `useWriterConnection` + `immediateTransaction`. |
| "I will return `List` from a blocking DAO call; `suspend` is ceremony." | No. Rule 6: KMP DAOs are `suspend`-or-`Flow` only. Blocking calls stall the single writer. |
| "I will read the `@Relation` without `@Transaction`; it is one call site." | No. Rule 10: children are separate queries. Without `@Transaction` a write lands mid-read. |
| "I will import the entity into the ViewModel; the fields match." | No. Rule 22 (skill rule 1): entities stay `internal`. Map to domain first. |
| "I will store the timestamp as text in `commonMain` with `java.time`." | No. Rule 12 (skill rule 9): no `java.*` in `commonMain`. Domain carries `kotlin.time.Instant`, stored as epoch millis. |
| "I will skip the migration; destructive fallback covers upgrades." | No. Rules 19 and 21: destructive fallback deletes user data. Ship a versioned `Migration` or `AutoMigration`. |
| "This Room API probably still looks like I remember." | Stop and verify now (skill stance item 1). Fetch the KMP Room page for the pinned version before writing. |

## Verification

- [ ] Room version in `libs.versions.toml` is at or above 2.7.0: `grep -n "room" gradle/libs.versions.toml` — yes or no, else stopped and reported.
- [ ] No `withTransaction` in shared code: `grep -rn "withTransaction" --include='*.kt' <commonMain-root>` returns nothing.
- [ ] No blocking DAO returns: every `@Dao` function is `suspend` or returns `Flow` — yes or no.
- [ ] Every `@Relation` holder is read through a `@Transaction` DAO function — yes or no.
- [ ] No entity outside the data layer: `grep -rn "^import.*Entity" --include='*.kt' <feature-root> <domain-root>` returns nothing.
- [ ] No `java.*`/`android.*` import in `commonMain` data files: `grep -rn "^import \(java\|android\)\." --include='*.kt' <commonMain-root>` returns nothing.
- [ ] Exported schema files for the current version are committed — yes or no.
- [ ] Every Room API named in the change was seen on the fetched KMP Room page for the pinned version — yes or no.
