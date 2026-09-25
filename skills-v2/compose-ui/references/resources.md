# Resources

Load this when touching `Res` accessors, `composeResources` folders, locale `values` folders, icons, or fonts.

Contents:

- CMP Res vs Android R placement
- `composeResources` layout and per-module resource classes
- Locale-qualified values folders and key parity
- Semantic keys in state with resolution at render
- String templates and plurals
- Icon pipeline and runtime tint
- Fonts
- Raw files, URIs, and remote content
- Gotchas, red flags, and verification

## Res vs Android R placement

1. **`commonMain` reads resources through the generated `Res` typed accessors, never through Android `R`.** An Android `R` reference in shared code breaks every non-Android target. *Prevents:* shared code that compiles on Android only. (SKILL.md rule 9)
2. **Each module declares its own generated resource class and package; never mix one module's `Res` with another's.** The generated class is `internal` by default, so cross-module use needs an explicit visibility decision. *Prevents:* a feature resolving design-system strings through the app class. (CMP-02)
3. **[Decision] Decide `Res` visibility deliberately per module.** A library module whose resources other modules consume exposes them with `publicResClass`; everything else stays `internal`. *Prevents:* silently unreachable shared resources. (CMP-03)
4. **Android-only assets stay in the Android shell module; shared UI strings stay in compose resources.** Launcher icons, splash themes, and backup rules live under the Android shell `res/`; the notes list and note editor strings live in shared values folders. *Prevents:* platform assets leaking into every target bundle. (SMP-53)
5. **Rebuild after adding resources before referencing them.** New files have no accessors until generation runs. *Prevents:* referencing accessors that do not exist yet. (CMP-01)

## Layout and qualifiers

6. **Qualifier priority is language, then theme, then density, combined with hyphens; a missing qualified variant falls back to the unqualified default.** A notes drawable without a dark variant resolves to the plain one. *Prevents:* qualifier combinations that never match. (CMP-05)

## Locales and key parity

7. **Every locale values folder carries identical keys with real translations; parity across values folders is a release gate.** A new note-editor string lands in the base `values/` folder and in every locale folder at the same time, translated, never copied English. *Prevents:* untranslated UI and locale drift the guard catches. (CMP-20; brief §11.4; SKILL.md rule 9)

## Semantic keys in state

8. **State holds semantic keys or enums, never resolved strings; resolution happens at render.** The notes `UiState` carries an error key; the Screen maps it to `stringResource` at render time. Never resolve strings or load resources in reducers or ViewModels. *Prevents:* locale-frozen state and untranslatable ViewModels. (RES-14; SKILL.md rule 9)

## Templates and plurals

9. **String template placeholders accept `%N$s` and `%N$d` only.** A notes welcome template takes a name and a count; no other format suffix exists. *Prevents:* templates that fail to format. (CMP-14)
10. **Plurals support `zero`, `one`, `two`, `few`, `many`, and `other`, but each language honors only its own subset.** Prefer quantity-neutral wording for the notes count when it reads naturally. *Prevents:* plural forms a locale never selects. (CMP-15)

## Icons

11. **Downloaded Material Symbols XML ships with fill forced to black and tint attributes stripped; recolor at the call site with a runtime tint filter.** A hardcoded icon color misses every theme change. *Prevents:* icons frozen to one theme. (RES-07; SKILL.md rule 5)
12. Icon homes agree with the design-system reference: stock glyphs stay at the call site and project-drawn glyphs live on the shared set, so this file states no second icon home.

## Fonts

13. **Build custom `Typography` inside a composable, because `Font()` reads `Res` in composition.** A notes type scale that applies bundled fonts therefore constructs its `FontFamily` at render time, not in a top-level val. *Prevents:* font loading outside composition. (RES-10)

## Raw files, URIs, and remote content

14. **Resources packed as Android assets stay reachable to WebViews and media components by path through `getUri`.** A notes export file bundled under `files/` hands its URI to the player instead of its bytes. *Prevents:* bundled media no external API can open. (CMP-19)
15. **[Decision] Bundled assets are resources; downloaded or remote files never are.** Fetch remote note attachments with an image or network library and convert bytes with the decode helpers before display. *Prevents:* network content modeled as a static resource. (CMP-21)
16. **Use the filename-keyed per-type maps (`Res.allDrawableResources`, `Res.allStringResources`, `Res.allStringArrayResources`, `Res.allPluralStringResources`, `Res.allFontResources`) for dynamic lookup when no static accessor can be named up front.** A tag icon chosen by server-sent name resolves through the matching map. *Prevents:* generated-accessor switches over dynamic names. (CMP-22)

## Gotchas

- Region codes are case-sensitive with a lowercase `r` prefix, so a mistyped qualifier folder never matches. (CMP-06)
- Every script-specific language needs a script-less sibling directory, or a script-less request matches all variants and resolution throws. (CMP-08)
- Nearly all resources read synchronously on the caller thread; only raw files and web resources read asynchronously. (CMP-09)
- Big raw files cannot be streamed; pass outside libraries a path through `getUri` instead. (CMP-10)
- `painterResource` is synchronous on every target except web, where the first composition renders empty and the image arrives on later recompositions. (CMP-11)
- Android XML vectors must not reference outside Android resources, and SVG drawables work on all targets except Android. (CMP-12)

## Red flags

| Thought | Reality |
|---|---|
| "I'll put this notes string inline; translation comes later." | No. Rule 9: every user-facing string is a resource in every locale before done. |
| "I'll resolve the label in the ViewModel and store the string; easier to test." | No. Rule 9: state holds the semantic key; the Screen resolves it at render. |
| "I'll hardcode this note-badge icon color; the tokens don't have it." | No. Rule 5: runtime tint from a theme token. Name the missing token as an open gap. |
| "I'll stash this shared tag glyph in my feature package for now." | No. Rule 6: shared glyphs live in the design-system module from the first use. |
| "I'll drop the launcher icon into `composeResources` so all targets share it." | No. Rule 9: platform-only assets stay in the Android shell; shared folders hold shared UI. |
| "I'll fetch this attachment as a resource so it's cached with the rest." | No. Rule 9: remote files are never resources; fetch them with an image or network library. |

## Verification

- [ ] `check-locale-parity.sh` exits 0: identical keys and real translations in every locale folder.
- [ ] `rg -n "import .*\.R\b" --glob '*.kt' <commonMain-root>` is empty.
- [ ] No resolved string or resource load inside a ViewModel or reducer: yes or no.
- [ ] `rg -n "Color\(0x" --glob '*.kt' <feature-root>` is empty outside the design-system module.
- [ ] Every module referencing another module's `Res` has the visibility config set deliberately: yes or no.
- [ ] Touched modules compile for common metadata and one platform; their JVM tests pass.
