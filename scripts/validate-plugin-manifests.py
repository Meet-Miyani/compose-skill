#!/usr/bin/env python3
"""Parse plugin manifests and verify their local references."""

import json
from pathlib import Path


ROOT = Path(__file__).resolve().parent.parent
MANIFESTS = (
    ROOT / ".claude-plugin/marketplace.json",
    ROOT / ".claude-plugin/plugin.json",
    ROOT / ".codex-plugin/plugin.json",
    ROOT / ".agents/plugins/marketplace.json",
)

data = {path: json.loads(path.read_text()) for path in MANIFESTS}
claude_marketplace, claude_plugin, codex_plugin, codex_marketplace = (
    data[path] for path in MANIFESTS
)

assert len(claude_marketplace["plugins"]) == 1
assert len(codex_marketplace["plugins"]) == 1
assert claude_marketplace["plugins"][0]["name"] == claude_plugin["name"]
assert codex_marketplace["plugins"][0]["name"] == codex_plugin["name"]
assert claude_plugin["version"] == codex_plugin["version"]

claude_source = claude_marketplace["plugins"][0]["source"]
codex_source = codex_marketplace["plugins"][0]["source"]["path"]
assert (ROOT / claude_source).is_dir()
assert (ROOT / codex_source).is_dir()
assert (ROOT / codex_plugin["skills"]).is_dir()

skills = sorted((ROOT / "skills").iterdir())
assert len(skills) == 7
assert all((skill / "SKILL.md").is_file() for skill in skills)
print("Plugin manifests: 4 JSON files parsed; references exist; 7 skills found")
