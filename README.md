# ComposeKit

ComposeKit is a CLI for installing and updating AI coding skills for Jetpack Compose, Compose Multiplatform, and Kotlin Multiplatform workflows.

## Install

### macOS/Linux

```bash
curl -fsSL https://raw.githubusercontent.com/Meet-Miyani/composekit/main/install.sh | bash
```

### Install and initialize

```bash
curl -fsSL https://raw.githubusercontent.com/Meet-Miyani/composekit/main/install.sh | bash -s -- --init
```

## Usage

Install the default Compose skill into detected AI coding agents:

```bash
composekit init
```

Update installed skills to the latest release:

```bash
composekit update
```

List available skills:

```bash
composekit skills list
```

Find skills:

```bash
composekit skills find navigation
```

Detect supported agent skill directories:

```bash
composekit targets detect
```

## Commands

| Command | Description |
|:--------|:------------|
| `composekit init` | Install the Compose skill to detected targets |
| `composekit update` | Update installed skills |
| `composekit doctor` | Check installation status |
| `composekit remove` | Remove installed skills |
| `composekit version` | Print CLI version |
| `composekit skills list` | List available skills |
| `composekit skills find <query>` | Search skills by name, description, or keywords |
| `composekit skills add <skill>` | Install a specific skill |
| `composekit skills remove <skill>` | Remove a specific skill |
| `composekit skills installed` | List installed skills |
| `composekit targets detect` | Detect supported agent skill directories |
| `composekit targets list` | List saved targets |
| `composekit targets add <dir>` | Add a custom target directory |
| `composekit targets remove <dir>` | Remove a custom target directory |

## Supported agent skill directories

ComposeKit detects and installs skills into:

| Agent | Path |
|---|---|
| Antigravity | `~/.gemini/antigravity/skills` |
| Claude | `~/.claude/skills` |
| Codex | `~/.codex/skills` |
| Cursor | `~/.cursor/skills` |
| Firebender | `~/.firebender/skills` |
| Gemini | `~/.gemini/skills` |
| OpenCode | `~/.config/opencode/skills` |

## Building from source

```bash
git clone https://github.com/Meet-Miyani/composekit.git
cd composekit
go build -o bin/composekit .
```

## License

MIT License — see [LICENSE](LICENSE).
