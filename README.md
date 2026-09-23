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
| `/lorvel:task-create` | Turns a one-line description into a Lorvel task, checking for duplicates and asking for what's missing before it writes. There is no draft to approve: edit or drop the task if it came out wrong. |
| `/lorvel:task-work` | Works one task from reading it through to closing it: analyse, plan, implement, review, ship, audit the knowledge, close. Stop gates before planning and before committing. |

`/lorvel:task-create` needs a connected Lorvel MCP server with write access. It
checks for that up front and stops if the tools aren't there, rather than
writing a malformed task.

You don't have to type `/lorvel:task-create`: ask Claude for a task in plain
words and it will usually run the same command — type it when you want to be
sure. Another agent working for you can run it too. It is written to run only
when someone asks for a task, never because Claude decided something deserves
one. If it needs to ask you something and the agent running it can't reach
you, it hands the questions back to that agent and creates nothing.
`/lorvel:task-work` still runs only when you type it.

`/lorvel:task-work` assumes your setup already has a way to review a change and a
way to commit one; it says when to reach for them and leaves the choice to you.
It never commits or pushes on its own unless you pass `--auto`, and even then a
change with no undo — a migration, a deploy pin — falls back to waiting for you.

Both commands carry **sequence, not shape**. What is specific to a project — its
field rules, its status vocabulary, its conventions — is read at runtime from
`task_authoring_guide` and `search_knowledge`, so the project's own answers win
over anything written into these files. That split is deliberate: a procedure that
hardcodes a project's facts drifts away from them the moment they change.

## Updating

This repo ships no `version` field, so a plugin's version is its commit SHA:
every push to `main` is a new version, and there is no release step.

Nothing updates on its own. Claude Code turns auto-update on by default only
for Anthropic's own marketplaces and for ones added through claude.ai; every
other marketplace — this one included — starts with it **off**. So an installed
plugin stays at the commit you installed it at until you say otherwise. That is
not a setting anyone forgot to flip: it is what adding a marketplace someone
else controls is supposed to mean.

Refresh the marketplace, then the plugin:

```bash
claude plugin marketplace update lorvel-plugins
claude plugin update lorvel
```

`claude plugin update` needs a restart to take effect. Installing does the first
step for you — `claude plugin install lorvel@lorvel-plugins` refreshes the
marketplace before resolving the plugin, so a freshly pushed plugin installs
without a manual marketplace update.

### Turning auto-update on

`/plugin` → **Marketplaces** → *Enable auto-update*. The toggle lives in that
menu only; there is no CLI equivalent.

It is worth being clear about what you are agreeing to, because the honest
answer is not "convenience". Auto-update means Claude Code pulls whatever
`main` happens to say at the start of a session and loads it with your
permissions — plugins are trusted code, closer to something you install than
something you read. What is in this repo today is Markdown that instructs
Claude rather than a program that runs on your machine, but that is a fact
about the current contents, not a promise about every future commit.

So: turning it on is a reasonable choice for a team that already trusts this
repo the way it trusts its own, and an unreasonable one as a default for
strangers. Leaving it off costs two commands when you want a new version, and
nothing else — the plugin does not degrade, warn, or nag if you never turn it
on.

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
      },
      "autoUpdate": true
    }
  },
  "enabledPlugins": {
    "lorvel@lorvel-plugins": true
  }
}
```

`autoUpdate` here is the same switch as the menu toggle above, with the same
trade-off — decided once for everyone the settings file reaches. That reach is
the reason to set it deliberately rather than because it came with the snippet:
drop the line and the marketplace falls back to the default, which is off.

`additionalMarketplaces` is accepted as an alias for `extraKnownMarketplaces`.

## What the commands are checked against

`plugins/lorvel/evaluations/task-create.json` holds the criteria
`/lorvel:task-create` is judged on — one entry per case, each saying what the
command has to do and what counts as failing. They were written before the
command body, so they describe what it should do rather than what it happens to
do.

`/lorvel:task-work` has no such file yet, which is worth saying plainly rather
than leaving to be inferred: the command that commits and pushes is the one
without written criteria.

They are read by hand. The shape is borrowed from another plugin's evaluations
and is not the shape `claude plugin eval` executes, which is why they sit in
`evaluations/` rather than `evals/`; the file itself says what porting them to
the runner would buy and what it would still need.

The case worth knowing about is `guide-tool-absent`: run the command somewhere
with no route to a Lorvel MCP server, and it has to stop and say the tool is
missing. Check that there is genuinely none — one machine can reach the same
server through both a project `.mcp.json` and an app-level connector, under
different names, and closing one of them leaves the test proving nothing. If a well-formed task comes out anyway, the shape of a task has been
copied into the command file, and the runtime guide is no longer the only source
of it. That is the one thing a reader cannot check by skimming — a short command
file is not proof of an uncopied one.

## Local development

The plugin directory can be symlinked into a project so edits take effect
without reinstalling. From the project root:

```bash
mkdir -p ~/.claude/skills
ln -s /path/to/agent-plugins/plugins/lorvel ~/.claude/skills/lorvel
```

Point it at the **plugin root**, not a directory inside it. A plugin sitting
under `~/.claude/skills/` loads on its own as `lorvel@skills-dir`, at user
scope, so the commands are there in every project rather than only this one.
`claude plugin list` shows it once it has loaded.

The symlink's own name is not what you type: the prefix comes from `name` in
`plugin.json`, so the commands stay `/lorvel:task-create` and
`/lorvel:task-work` — the same names the installed plugin gives them.

Keep one source at a time. With the symlink in place *and* the published
plugin installed, `/lorvel:task-create` has two copies behind it and which one
you edit stops being obvious — so uninstall the plugin while developing, and
drop the symlink once you switch back to the published copy.

Validate the manifests before pushing:

```bash
claude plugin validate .
```
