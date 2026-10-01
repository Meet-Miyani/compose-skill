# Releasing Compose Kit

1. Update the release notes and verify the seven skill directories and project guards.
2. Set the new release version in `.claude-plugin/plugin.json` and `.codex-plugin/plugin.json`.
   Claude Code uses the plugin manifest version for updates: if it stays the same, installed users keep their cached copy.
3. Run the architecture tests, validate the Claude marketplace, parse the plugin JSON files, and package the skills bundle.
4. Publish a `v<version>` tag through the normal review process. The release workflow attaches the skills tarball and checksum; a tag containing `-` creates a pre-release.
