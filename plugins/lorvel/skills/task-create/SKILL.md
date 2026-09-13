---
name: task-create
description: Step 1 — create a Lorvel task from a description
argument-hint: [what needs doing]
disable-model-invocation: true
---

Create a task on Lorvel from this description: **$ARGUMENTS**

No description given ⇒ ask the user before doing anything else.

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
**GATE-2** turns up a duplicate the user decides to extend instead. None of those is a failure, and
an ending at step 1 or 2 never needs the files for steps 3-7.

Paths are relative to `${CLAUDE_SKILL_DIR}`. If a file is missing, say so and stop — do not
reconstruct the step from memory.

## Boundaries

Finishing **step 7** is **the end of the command**. Do not carry on into planning or implementing the task you just made — that is different work, and the user will ask for it when they want it.
