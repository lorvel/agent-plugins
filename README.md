# Lorvel agent plugins

Claude Code plugins for working with [Lorvel](https://lorvel.ai).

> **Scope:** Claude Code only. Despite the repository name, this is not an
> implementation of the cross-vendor *Agent Plugins 1.0* specification — the
> repo ships `.claude-plugin/` manifests and nothing else. Support for other
> agent clients is not a promise made here.

## Install

```bash
claude plugin marketplace add lorvel/agent-plugins
claude plugin install lorvel@lorvel-plugins
```

## Commands

| Command | What it does |
|---|---|
| `/lorvel:task-create` | Turns a one-line description into a Lorvel task, asking for what's missing and showing you the full draft before anything is written. |

`/lorvel:task-create` needs a connected Lorvel MCP server with write access. It
checks for that up front and stops if the tools aren't there, rather than
writing a malformed task.

The command carries **sequence, not shape**: the shape of a task comes from
`task_authoring_guide` at runtime, so a project's own field rules and status
vocabulary win over anything hardcoded here.

## Updating

This repo ships no `version` field, so a plugin's version is its commit SHA:
every push to `main` is a new version, and there is no release step.

Refresh the marketplace, then the plugin:

```bash
claude plugin marketplace update lorvel-plugins
claude plugin update lorvel
```

`claude plugin update` needs a restart to take effect. Installing does the first
step for you — `claude plugin install lorvel@lorvel-plugins` refreshes the
marketplace before resolving the plugin, so a freshly pushed plugin installs
without a manual marketplace update.

### Shared setup for a team

Declare the marketplace and the plugin in `settings.json` (user-level, or a
project's `.claude/settings.json`) so a teammate gets both on their next start:

```json
{
  "extraKnownMarketplaces": {
    "lorvel-plugins": {
      "source": {
        "source": "github",
        "repo": "lorvel/agent-plugins"
      }
    }
  },
  "enabledPlugins": {
    "lorvel@lorvel-plugins": true
  }
}
```

`additionalMarketplaces` is accepted as an alias for `extraKnownMarketplaces`.

## Local development

The plugin directory can be symlinked into a project so edits take effect
without reinstalling. From the project root:

```bash
mkdir -p .claude/commands
ln -s ../../agent-plugins/plugins/lorvel/commands .claude/commands/lorvel
```

Naming the symlink `lorvel` matters: a directory under `.claude/commands/`
becomes the typed namespace, so the command stays `/lorvel:task-create` —
the same name the installed plugin gives it.

```bash
claude plugin validate .
```
