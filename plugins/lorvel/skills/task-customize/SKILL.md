---
name: task-customize
description: Customise task-create or task-work for this repository, in .lorvel/
argument-hint: <task-work|task-create> [what to change]
disable-model-invocation: true
allowed-tools: Bash("${CLAUDE_PLUGIN_ROOT}/scripts/lorvel-customize" *)
---

Customise a Lorvel command for this repository: **$ARGUMENTS**

`/lorvel:task-work` and `/lorvel:task-create` each read two files in the session folder when they start: `.lorvel/<command>.md`, shared with the team, and `.lorvel/<command>.local.md`, personal. You write those files here, and only through the plugin's script, `lorvel-customize`: it checks every draft with the loader those commands run, and writes only what that loader would apply.

**Nothing about the two commands is written in this file** — not their steps, gates, rules, modes or settings. The script's `show` prints them from the commands' own declarations. Work from what it printed in this run, never from what you remember of them: this file stays right when the commands change only because it holds none of that.

## Rules that hold throughout

- **Never open a file in `.lorvel/` yourself** — not with Read, `cat`, `grep`, an editor, or a listing of the folder. You see those files only as `show` prints them: through the loader, which checks them before any of their text reaches you. What it does not print — text it refuses, comments — must not reach you any other way.
- **Never write a file in `.lorvel/` except with `write`**, which writes only a draft the loader applies in full: no Write or Edit on them, no shell redirection, no deleting. The user wants a file gone altogether ⇒ name it; deleting it is theirs to do.
- **A file only tightens.** A request that would make a command do less — skip or replace what `show` does not allow there, weaken what it marks locked, or set a default it says no file can set — is refused when it is asked, and nothing is written for it.
- **Never print a token, bearer or key**, not even truncated, and never put one in a draft.
- **Reply in the language the user writes in.** A section's text is in whatever language they want the command to read. Identifiers — command names, step and gate IDs, file names, a review skill and its arguments — stay verbatim.

## Running the script

Every call has this shape, with the session folder on the first line of the heredoc exactly as written here:

    "${CLAUDE_PLUGIN_ROOT}/scripts/lorvel-customize" <verb> <command> … <<'LORVEL_INPUT'
    ${CLAUDE_PROJECT_DIR}
    LORVEL_INPUT

- `show <command>`
- `check <command> <shared|personal>`, and `write <command> <shared|personal> <new|replace>`: the whole draft follows the folder line, from the `---` that opens its frontmatter to its last line. No line of a draft may be exactly `LORVEL_INPUT`.
- `gitignore <command>`, and `gitignore <command> add`

The script always exits 0. A line starting with `- ` says what it did, or why it did not.

Claude Code runs the script without asking only in the turn that started this command: once the user has answered a question, each call asks for their approval first. A call refused — they said no, or it needs an approval nobody here can give — ⇒ do not try it again and do not reach `.lorvel/` another way: say what was not done, show the draft if there is one, and stop.

## The steps

1. **The command.** `$ARGUMENTS` names `task-work` or `task-create`, or makes plain which one ⇒ that one. Otherwise ask which, and nothing else yet.
2. **`show`.** It prints where a customisation of that command can act, then what applies now, as a run of the command would print it: every file of that command that exists shows up there. With both files there, it also prints what each applies on its own, and for a file with comments or a title, how many such lines a rewrite drops. It prints only a `- ` line instead ⇒ say what that line says, and stop.
3. **Refuse at once what `show` does not allow**, before asking anything else:
   - a section at an ID `show` does not list it for, or at a rule;
   - text that would skip, replace or weaken something `show` marks locked, wherever it is anchored — judge it by what it does, as `show` quotes the modes;
   - a setting `show` does not list, or a value it says no file can set — and say what the person can type instead, where `show` names it.

   One line for each refused part, with the reason. All of the request refused ⇒ that is the end: nothing is asked, drafted, checked or written. Part of it refused ⇒ ask whether to do the rest, in step 4's round.
4. **Ask what the user has not said**, in one round:
   - what to change, when `$ARGUMENTS` does not say — a user who does not know what can change gets the steps and settings `show` printed, in their words;
   - which file: shared — committed, so the whole team gets it — or personal — theirs alone, its settings winning, and taking only what `show` lists for the personal file.
5. **Draft the whole file** for that layer: frontmatter holding `schema: 1` and the settings, then each section as a `## <operation>: <ID>` heading with its text.
   - The file exists ⇒ start from what `show` printed for it — what it applies on its own, when both files exist: its settings from the `- ` lines that name it, each section's text from the `  > ` lines under its heading, without the `  > `. Then make the change.
   - A rewrite keeps only that. A part the loader does not apply — named in a `Not applied` or `Nothing in` line — is dropped, and so are the comment and title lines `show` counts for the file. Either for this file ⇒ tell the user what the rewrite drops, and ask. No ⇒ stop; the file stays as it is.
   - The file is refused as a whole ⇒ you cannot see it. Refused as a symbolic link or as not a regular file ⇒ it cannot be replaced from here either: say so, and that removing it is the user's to do. Refused for anything else ⇒ offer only to replace all of it; nothing is written without their yes.
6. **`check`** the draft when a question comes before `write` (step 7); otherwise go straight to step 8, as `write` checks it the same way. It says whether the loader applies all of the draft, and prints the lines a run would start with. Not clean ⇒ fix the draft and check again; where the fix changes what the user asked for, ask first. A line about the other file is how that file already is: mention it, but it does not block.
7. **A personal file being created:** `gitignore`.
   - Not a git repository, or nothing reported missing ⇒ nothing to ask.
   - It says nothing was checked ⇒ say so, and that the file could end up in a commit.
   - Otherwise one question for what it reports missing — git ignoring the file, `.worktreeinclude` listing it: add it? Yes ⇒ `gitignore <command> add`. No ⇒ carry on, and tell the user what its lines say that means.
8. **`write`** the same draft: `new` for a file that does not exist, `replace` for one the user agreed to rewrite. It checks again, and writes only a clean draft. `check` or `write` refusing because of `.lorvel/` itself — a link, not a folder, unreadable, or holding a file named like this one but for case — ⇒ say what it says: that is the user's to fix.
9. **Show the flow after it**, from what `write` printed and from `show`: first the lines the command will print when it starts; then its steps and gates in order, each section at its place — before or after a step, or in place of it — with what is locked marked. A shared file ⇒ remind the user it reaches the team once committed — unless `write` said git ignores it: then say that instead. That is the end of the command.
