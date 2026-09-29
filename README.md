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
| `/lorvel:task-customize` | Writes this repository's customisation of the other two commands, in `.lorvel/`: shows where each can be changed, asks what you want, checks it, and shows the flow once it applies. |

`/lorvel:task-create` needs a connected Lorvel MCP server with write access. It
checks for that up front and stops if the tools aren't there, rather than
writing a malformed task.

You don't have to type `/lorvel:task-create`: ask Claude for a task in plain
words and it will usually run the same command — type it when you want to be
sure. Another agent working for you can run it too. It is written to run only
when someone asks for a task, never because Claude decided something deserves
one. If it needs to ask you something and the agent running it can't reach
you, it hands the questions back to that agent and creates nothing.
`/lorvel:task-work` and `/lorvel:task-customize` still run only when you type them.

`/lorvel:task-work` assumes your setup already has a way to review a change and a
way to commit one; it says when to reach for them and leaves the choice to you.
It never commits or pushes on its own unless you pass `--auto`, and even then a
change with no undo — a migration, a deploy pin — falls back to waiting for you.

Both commands carry **sequence, not shape**. What is specific to a project — its
field rules, its status vocabulary, its conventions — is read at runtime from
`task_authoring_guide` and `search_knowledge`, so the project's own answers win
over anything written into these files. That split is deliberate: a procedure that
hardcodes a project's facts drifts away from them the moment they change.

## Customising the commands

A repository can change parts of both commands without forking the plugin, with files in
`.lorvel/` in the folder the session was opened in:

- `.lorvel/task-work.md` and `.lorvel/task-create.md` — shared: commit them, and the whole
  team gets them.
- `.lorvel/task-work.local.md` and `.lorvel/task-create.local.md` — personal: keep them out
  of git. Their settings win over the shared file's, and where both files have a section
  at the same place, the shared one runs first.

`/lorvel:task-customize` writes them for you. It lists where a command can be customised, asks
what you want and in which file, refuses what a file cannot do before writing anything, and
checks every draft with the loader the commands run, so what it writes is what applies. Before it
first writes a personal file in a git repository, it asks whether to add `.lorvel/*.local.md` to
`.gitignore` — and to `.worktreeinclude`, without which a new worktree starts without your
personal file. (In a linked worktree it leaves `.worktreeinclude` alone: Claude Code copies into a
new worktree from the main one.) It never opens a file in `.lorvel/` itself: it sees one only as
the loader prints it — each file on its own when there are two — so changing a file rewrites it
from that view, and it asks first when that would drop something: a part the loader does not
apply, or comment and title lines. Its script runs without a prompt only in the turn you start
the command in: once it has asked you something, Claude Code asks you before each further run of
the script, which shows you the draft it is about to check or write.

Settings go in the frontmatter, and sections in the body:

```markdown
---
schema: 1
review: code-review xhigh --fix
defaults:
  plan: true
---

## after: implement

Run the linter with its fix option before the review.

## before: ship

Follow the release checklist in `docs/RELEASE.md`.
```

The settings are `/lorvel:task-work`'s; `/lorvel:task-create` has none yet.

- `review` — the skill phase 4 calls to review the change, with its arguments, instead
  of the command picking whatever review tooling it finds. A skill that is not there,
  or that Claude is not allowed to call, is said out loud, and the command reviews the
  change itself. The value is refused if it names one of this plugin's commands, would
  start another command, or looks like it carries a key.
- `defaults.plan: true` — STOP-2 is on without typing `--plan`. A file can only tighten:
  `plan: false`, and `auto` of any kind, are refused, because a file cannot delegate a
  run on behalf of the person typing the command. `--no-plan` turns STOP-2 off for one
  run; typed together with `--plan`, STOP-2 stays on.

A section is a `## before: <ID>`, `## after: <ID>`, `## replace: <ID>` or `## skip: <ID>`
heading and the text Claude follows there. The IDs are each command's steps, gates and
rules, declared with what a customisation may do at each in the `metadata` of its
`SKILL.md`; `plugins/lorvel/ids.md` says what the fields and modes mean.

- `before:` and `after:` add a step next to any step or gate. A gate keeps its place when
  it is switched off, and GATE-2 of `/lorvel:task-create`, which sits in two steps, runs
  its sections in both. An `after:` on a command's last step runs before its closing
  report, which stays last.
- `replace:` puts your text in place of a step's own, where the step allows it — in this
  version, only `classify` of `/lorvel:task-create`. An empty `replace:` counts as a `skip:`.
- `skip:` drops a step marked optional; its text, if any, says why. No step is optional in
  this version, so every `skip:` is refused for now.
- A personal file can only add steps: `replace:` and `skip:` are for the shared file.
- A section can ask the user something, even where the command would carry straight on.
  When `/lorvel:task-create` runs for another agent, that question ends the command, as
  its own questions do.
- A section can point Claude to another file in the repository, but never into `.lorvel/`:
  the loader refuses a section that names it, and Claude never opens a file there whatever
  a section says.
- `/lorvel:task-create` reads its files after its first step's checks, so a section
  before `intake` or `GATE-1` cannot apply.
- The sections of one file take at most 1,536 bytes once printed: they reach Claude at the
  start of every run, before anything else it reads there. For more, point to a file.

Whatever a section says, it cannot skip or replace a step other than through its own
`skip:` or `replace:` heading, and it cannot make a locked step or rule do less — the stop
gates, the duplicate checks and step 5 of `/lorvel:task-create`, never printing a key, and
the others the `metadata` marks `locked`. Claude does not do that part and says so.
Claude reads a section's text quoted, under the line that names its place.

The first reply of every run lists what applied and which file it came from, and what
was refused and why.

**What the loader refuses.** A script that ships with the plugin,
`plugins/lorvel/scripts/lorvel-load`, reads these files before Claude sees anything,
and Claude is told never to open them itself. A file that contains invisible Unicode
characters (zero-width, bidirectional and tag characters, among others) or anything
that looks like a token or a key is refused as a whole: only a line naming the file
reaches the conversation, never its text. So is a file that is a symbolic link, is
larger than 64 KiB, or has frontmatter the loader does not understand. A section is
refused on its own when it names no ID of the command, when the ID or the file's layer
does not allow what it does, when it has no text, when it names `.lorvel/`, when it looks
like it carries a key, or when a code fence in it is never closed. All the sections of a file
are refused when its body holds text a rendered view of the file does not show — HTML or
anything shaped like a tag, an image, a link's title, a link definition such as `[//]: # (…)`,
or words after a code fence's language — so that what applies is what a reviewer reading the
file rendered by a code host sees. Only `.lorvel/`
in the session folder is read — never a parent folder's or a subfolder's — and only
files named exactly `task-work.md`, `task-work.local.md`, `task-create.md` and
`task-create.local.md`. The scripts need `sh`, `awk`, `od` and `find`; `/lorvel:task-customize`
also runs git, to see what git ignores.

**`/lorvel:task-work` now runs a script before Claude starts.** The plugin pre-approves
it, so there is no prompt. But a permission rule that asks about it or denies it — a
blanket `ask` or `deny` for Bash, say, or managed settings that ignore a plugin's own
allowed tools — stops `/lorvel:task-work` from starting at all, whether or not the
repository has a `.lorvel/`. On Windows it needs Git Bash.

`/lorvel:task-create` reads `.lorvel/task-create.md` and `.lorvel/task-create.local.md`
with the same loader, but not before it starts. Claude checks for the two names first,
and runs the loader through Bash only when one of them exists, so in the default
permission mode it asks before running it; refuse, and the command carries on without
customisation.

If your organisation sets `disableSkillShellExecution`, customisation is off for
`/lorvel:task-work`. It does not reach `/lorvel:task-create`, whose loader runs
through Bash under the normal permission rules: a `deny` rule for
`Bash(*/scripts/lorvel-load task-create*)` turns that one off. Do not widen the rule
to `lorvel-load *`: that also matches the script `/lorvel:task-work` runs before
starting, and stops that command altogether.

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
something you read. What is in this repo today is mostly Markdown that instructs
Claude, plus a small loader and writer — three shell scripts and seven awk programs — that runs
on your machine to read a project's `.lorvel/` files. When you run `/lorvel:task-customize`, it
also writes them, runs git, and — once you say yes — adds a line to `.gitignore` in the session
folder and to `.worktreeinclude` at the root of the repository. `/lorvel:task-work` runs the
loader at every start without asking, because the plugin pre-approves it, and
`/lorvel:task-customize` runs its script without asking in the turn you start it. That is a fact about
the current contents, not a promise about every future commit.

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

`plugins/lorvel/evaluations/task-work.json` does the same for `/lorvel:task-work`,
but only for the customisation cases that came with `.lorvel/`. That is worth saying
plainly rather than leaving to be inferred: the rest of the command — the part that
commits and pushes — still has no written criteria.

`plugins/lorvel/evaluations/task-customize.json` does the same for
`/lorvel:task-customize`, written from its definition of done before the runs that
checked it.

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

Validate the manifests and run the tests before pushing:

```bash
claude plugin validate .
sh tests/loader.test.sh
sh tests/customize.test.sh
ruby tests/ids.test.rb
```

`tests/` sits outside the plugin directory, so it is not part of what gets installed.
