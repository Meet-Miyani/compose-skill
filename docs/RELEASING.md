# Releasing Compose Kit

1. Update the release notes and verify the seven skill directories and project guards.
2. Set the new release version in `.claude-plugin/plugin.json` and `.codex-plugin/plugin.json`.
   Claude Code uses the plugin manifest version for updates: if it stays the same, installed users keep their cached copy.
3. Run the architecture tests, validate the Claude marketplace, parse the plugin JSON files, build the Claude plugin
   folder (`bash scripts/build-plugin.sh <empty-dir>`), and package the skills bundle.
4. Publish a `v<version>` tag through the normal review process. The release workflow attaches the skills tarball and checksum; a tag containing `-` creates a pre-release.
   For a stable tag, the publish-claude-plugin workflow also rebuilds the `claude-plugin` branch (step 5).

## Anthropic's plugin directory

Anthropic's directory installs only the plugin folder, and on `main` that folder would be the whole repository:
evals, tests and the site included. So the directory follows the `claude-plugin` branch instead. It holds the
manifest and icon, `skills/`, the listing README (`.claude-plugin/README.md`), `LICENSE` and `NOTICE.md`, built and
checked by `scripts/build-plugin.sh` against the directory's file rules.

5. **On each stable tag**, the publish-claude-plugin workflow builds that folder and adds one commit to
   `claude-plugin`. It refuses a tag that is not the latest stable one, or whose `plugin.json` version doesn't
   match it. The directory picks up the commit, scans it, and publishes it under the plugin's publish setting.
   The Gradle wrapper JAR in the `compose-project` template holds each version for a reviewer by design.
6. **To change only the listing** (README, icon, description) for the current release, merge the change to `main`
   and run the workflow by hand: `gh workflow run publish-claude-plugin.yml --ref main`. It refuses if `skills/`
   has changed since the latest stable tag; release a new version instead.

The directory submission uses repository `Meet-Miyani/compose-skill`, an empty plugin path, and branch
`claude-plugin`. Open issues and pull requests against `main`, never the generated branch.
