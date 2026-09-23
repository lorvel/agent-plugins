---
name: task-create
description: Step 1 — create a Lorvel task from a description
when_to_use: Use when the user explicitly asks for a task or ticket to be created, filed or opened in Lorvel, in any language and whether or not they name Lorvel, or when you are a subagent handed that job on the user's behalf. Do NOT use it when the user only describes a problem, asks about an existing task, wants a task worked on, updated or closed, or means a to-do list for this session or an issue in another tracker — and never because you decided on your own that something deserves a task.
argument-hint: [what needs doing]
---

Create a task on Lorvel from this description: **$ARGUMENTS**

`$ARGUMENTS` empty ⇒ take the description from the request that brought you here; only when there is none, ask the user before doing anything else.

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

**No one to ask.** What decides this is **who reads your reply**, not who started the command. Typed by the user, invoked by you from their plain-words request, or chained from another skill in this conversation ⇒ the user reads it: ask as usual. Running as a **subagent** — or as a skill that runs forked — whose final message goes to another agent ⇒ nobody who can answer will see a question. Then wherever this command would ask the user — no description, the working language, **GATE-2**, step 5 — **end the command there**: hand back the questions, or the matches with ref, link, verdict and similarity, say plainly that nothing was created, and stop. Having no way to reach the user is not permission to answer for them. Taking the questions to them is the caller's job, and the command then runs again with the answers in its description. A description that already answers everything ⇒ straight through to step 7.

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
