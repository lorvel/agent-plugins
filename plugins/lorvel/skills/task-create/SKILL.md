---
name: task-create
description: Step 1 — create a Lorvel task from a description
when_to_use: Use when the user explicitly asks for a task or ticket to be created, filed or opened in Lorvel, in any language and whether or not they name Lorvel, or when you are a subagent handed that job on the user's behalf. Do NOT use it when the user only describes a problem, asks about an existing task, wants a task worked on, updated or closed, or means a to-do list for this session or an issue in another tracker — and never because you decided on your own that something deserves a task.
argument-hint: [what needs doing]
metadata:
  lorvel:
    schema: 1
    ids:
      - {id: intake, kind: step, mode: extend, what: "Step 1 — get the guide, check the tools"}
      - {id: GATE-1, kind: gate, in: [intake], mode: locked, what: "No guide tool ⇒ stop; a missing write tool ⇒ say so now"}
      - {id: duplicates, kind: step, mode: extend, what: "Step 2 — check a draft title for duplicates"}
      - {id: GATE-2, kind: gate, in: [duplicates, recheck], mode: locked, what: "A possible duplicate ⇒ show it, ask, create nothing until answered"}
      - {id: classify, kind: step, mode: replace, what: "Step 3 — settle bug, change or spike"}
      - {id: context, kind: step, mode: extend, what: "Step 4 — read the knowledge, then the code; change nothing"}
      - {id: ask, kind: step, mode: locked, what: "Step 5 — ask what the user has not said"}
      - {id: recheck, kind: step, mode: locked, what: "Step 6 — check the full title and body for duplicates"}
      - {id: write, kind: step, mode: extend, what: "Step 7 — create the task, log the receipt, report the link"}
      - id: no-one-to-ask
        kind: rule
        mode: locked
        what: "Nobody who can answer reads the reply ⇒ end with the questions"
        source: ["No one to ask.", "asking in text reaches nobody who can answer"]
      - id: no-secrets
        kind: rule
        mode: locked
        what: "Never print a token, bearer or key, not even truncated"
        source: ["never print a token, bearer or key"]
      - id: loader-only
        kind: rule
        mode: locked
        what: "A `.lorvel/` file reaches the model only through the plugin's loader, never opened directly"
        source: ["Never open those files any other way"]
---

Create a task on Lorvel from this description: **$ARGUMENTS**

`$ARGUMENTS` empty ⇒ take the description from the request that brought you here; only when there is none, ask the user before doing anything else.

**Customisation.** This repository can set parts of this command in `.lorvel/task-create.md` (shared) and `.lorvel/task-create.local.md` (personal). In the same message as step 1's `task_authoring_guide` call, check for them by name with Bash:

    ls -d -- '${CLAUDE_PROJECT_DIR}/.lorvel/task-create.md' '${CLAUDE_PROJECT_DIR}/.lorvel/task-create.local.md'

- An error for both ⇒ neither exists: nothing more to do, and do not mention it, not even in a status line.
- Either listed ⇒ once GATE-1 has passed, run this with Bash, exactly as written. It checks both files and prints what applies: your first message to the user — step 5's round, or the report at step 7 — opens with every line it prints, the "Not applied" ones too but not a section's quoted lines or the closing `Sections:` line, in the user's language, then one line for each section you will not follow in full, and why, unless all it prints is `No customisation from .lorvel/ for this command.` Each section it prints applies at the step it names, as its `Sections:` line says.

      "${CLAUDE_PLUGIN_ROOT}/scripts/lorvel-load" task-create <<'LORVEL_SESSION_FOLDER'
      ${CLAUDE_PROJECT_DIR}
      LORVEL_SESSION_FOLDER

- That command is refused or fails ⇒ say in one line that customisation is off for this run, and carry on.
- **Never open those files any other way**: the loader is the only thing that checks them before their text reaches you.

This file carries **sequence only**. **The shape of a task is not in here** — it comes from `task_authoring_guide` at runtime. Do not write a task out of what you remember about Lorvel.

## Language

**Write the task in the language the user wrote to you in.** This file is in English because its readers are the people installing the plugin; the task's readers are the user's own team. A description in Vietnamese gets a Vietnamese `title` and `body`; one in Japanese gets Japanese. Answering in English because this file is in English is the wrong instinct — the file is instructions to you, not a sample of the output.

**Never translate identifiers.** File paths, function and column names, command names, UI labels, error strings, and anything the user quoted stay **verbatim**. Translating them invents a second vocabulary that matches neither the code nor any later search.

If the tasks that come back at step 2 are consistently in a different language from the user's, that difference is the project's working language, not a mistake — say so and ask which to use. Do not switch on your own. Mixing languages inside one project costs more than it looks: `title` and `body` are the indexed text, so a split vocabulary weakens every duplicate check that follows.

## Stop gates

| | Where | Rule |
|---|---|---|
| **GATE-1** tools | step 1 | `task_authoring_guide` missing ⇒ **stop and say plainly that it is missing**. Report it and nothing more: do not go digging through MCP config, and never print a token, bearer or key. A missing **write** tool ⇒ say so at step 1, not at step 7. |
| **GATE-2** duplicates | steps 2 and 6 | Any match that **could** be the same work ⇒ show it to the user, ask, and **create nothing** until they answer. |

Neither has an off switch: this command takes no flags, and "this one is small" is not a reason to skip one. Where the user has not said something, **ask** — no `AskUserQuestion` in the session means ask in text, not ask less.

**No one to ask.** What decides this is **who reads your reply**, not who started the command. Typed by the user, invoked by you from their plain-words request, or chained from another skill in this conversation ⇒ the user reads it: ask as usual. Running as a **subagent** — or as a skill that runs forked — whose final message goes to another agent ⇒ nobody who can answer will see a question. Then wherever this command would ask the user — no description, the working language, **GATE-2**, step 5, or a question a customisation section adds — **end the command there**: hand back the questions, or the matches with ref, link, verdict and similarity, say plainly that nothing was created — or, for a question that comes after step 7 has written the task, give its link — and stop. Having no way to reach the user is not permission to answer for them. Taking the questions to them is the caller's job, and the command then runs again with the answers in its description. A description that already answers everything ⇒ straight through to step 7.

**There is no approval gate, and adding one back is not a safe default.** Nothing duplicating at step 6 means the task gets written: the user can edit or drop it the moment they see the link, so a round asking permission to write charges every run to undo the occasional bad one. What the missing gate used to buy is paid at **step 5** instead — the last place a wrong sentence is caught before it reaches indexed text, which is why skipping it is the one shortcut here that nothing downstream makes up for.

## The steps

Each step's detail sits beside this file, and **you read the file for a step before you work that
step** — the steps, their order and the traps are in there. The one-line summaries below are a map,
not the instructions; working from them is the guessing this command exists to prevent.

| Step | In one line | Read first |
|---|---|---|
| **1** Guide and tools | `task_authoring_guide`, keep the token, check the write tools are there. **GATE-1**. | `reference/intake.md` |
| **2** Duplicates | A draft title into `check_similar_tasks`, then read the matches. **GATE-2**. | *(same file)* |
| **3** Classify | Bug, change or spike — **you** settle it; step 5 states it, and asks only when there is nothing to go on. | `reference/drafting.md` |
| **4** Context | Knowledge first, then the code. Read only; do not design the fix. | *(same file)* |
| **5** Ask | What the user has not said — **do not skip this step**. | *(same file)* |
| **6** Re-check | The full `title` + `body` into `check_similar_tasks` once more; nothing new ⇒ on to step 7. **GATE-2**. | `reference/writing.md` |
| **7** Write | `create_task`, one `log_progress` receipt, then report the link. | *(same file)* |

The command can end early at **step 1** — no guide tool — or at **step 2** or **step 6**, wherever
**GATE-2** turns up a duplicate the user decides to extend instead, or wherever **No one to ask**
hands the questions or matches back to the caller. None of those is a failure, and an ending at
step 1 or 2 never needs the files for steps 3-7.

Paths are relative to `${CLAUDE_SKILL_DIR}`. If a file is missing, say so and stop — do not
reconstruct the step from memory.

## Boundaries

Finishing **step 7** is **the end of the command**. Do not carry on into planning or implementing the task you just made — that is different work, and the user will ask for it when they want it.
