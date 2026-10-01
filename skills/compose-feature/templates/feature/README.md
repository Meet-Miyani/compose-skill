# Feature templates

Scaffold for a Notes slice. Copy the files, replace the placeholders, keep the layout.

## Placeholders

| Placeholder | Meaning | Example (Notes) |
|---|---|---|
| `__Name__` | Feature name, PascalCase | `Notes` |
| `__name__` | Feature name, camelCase | `notes` |
| `__Item__` | Record name, singular PascalCase | `Note` |
| `__item__` | Record name, singular camelCase | `note` |
| `__PACKAGE__` | Feature package root | `com.example.feature.notes` |

## Scaffold

Run from the project root:

```sh
scripts/new-feature.sh --name __Name__ --item __Item__ --package __PACKAGE__ --root <project-root>
```

The default scaffold holds the domain `__Item__` in `UiState` directly: no `model/`, no `mapper/` (ruling M-11). Add `--ui-model` to also write `__Item__UiModel` and `__Item__UiMapper` when a trigger fires; name that trigger in the one-line comment on the UiModel. `UI_MODEL=always` in `.composekit.conf` makes `--ui-model` the default (`--no-ui-model` forces it off).

The script copies `templates/feature/` and renames `__Name__`, `__name__`, `__Item__`, `__item__`, and `__PACKAGE__` in paths and contents.

Register the generated `__Name__FeatureModule` in the composition root's Koin module after scaffolding. *Prevents:* a destination whose ViewModel has no binding.

## Composition-root entry

Entries live in the composition root, never in the feature. Register the detail key there:

```kotlin
entry<__Name__DetailKey> {
    __Name__Route(
        viewModel = koinViewModel(parameters = { parametersOf(__Name__Params(__item__Id = it.__item__Id)) }),
        __item__Id = it.__item__Id,
        onEffect = { effect -> /* composition root maps the effect to a back-stack call */ },
    )
}
```

The entry resolves the ViewModel with `parametersOf` and passes it into the Route. The feature owns the key and the Route; the composition root owns the entry. Entry mechanics follow the android/skills `navigation-3` skill, if installed. `__Name__Params` is a top-level class shared by the entry and the tests.
