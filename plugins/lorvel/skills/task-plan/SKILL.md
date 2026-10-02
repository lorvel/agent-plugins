---
name: task-plan
description: Step 2 (optional) — plan a Lorvel task without starting it
when_to_use: Use when the user explicitly asks for a plan to be written for a Lorvel task that already exists, in any language and whether or not they name Lorvel, or when you are a subagent handed that job on the user's behalf. Do NOT use it when the user wants a task worked on, implemented or closed, wants a task created, asks about a task or about the plan it has, asks for Claude Code's plan mode, or wants a plan that belongs to no task in Lorvel — and never because you decided on your own that a task needs a plan.
argument-hint: <task-ref>
metadata:
  lorvel:
    schema: 1
    ids:
      - {id: locate, kind: step, mode: extend, what: "Step 1 — find the task, get the guide and the planning method, check the tools"}
      - {id: GATE-1, kind: gate, in: [locate], mode: locked, what: "No guide, or no section on plans in it ⇒ stop; a missing write tool ⇒ stop too"}
      - {id: GATE-2, kind: gate, in: [locate], mode: locked, what: "The task already has a plan ⇒ ask whether to replace it, write nothing until yes"}
      - {id: read, kind: step, mode: extend, what: "Step 2 — read what the planning method lists; change nothing"}
      - {id: ask, kind: step, mode: locked, what: "Step 3 — ask what cannot wait for the plan"}
      - {id: write, kind: step, mode: extend, what: "Step 4 — write the plan and save it"}
      - {id: report, kind: step, mode: extend, what: "Step 5 — once the plan is saved: one log entry, the link, stop"}
      - id: plan-only
        kind: rule
        mode: locked
        what: "Writes the plan of one task and one log entry on it: no status, no other task, no file, no start on the work"
        source: ["The `plan` of that one task, and one log entry on it.", "No status moves", "No other task is created or edited", "No file of the repository is changed", "No start on the work"]
      - id: no-one-to-ask
        kind: rule
        mode: locked
        what: "Nobody who can answer reads the reply ⇒ end with the questions"
        source: ["No one to ask."]
      - id: no-secrets
        kind: rule
        mode: locked
        what: "Never print a token, bearer or key, not even truncated"
        source: ["never print a token, bearer or key"]
---

Plan this Lorvel task, without starting it: **$ARGUMENTS**

A ref like `LA-12` is the task to plan. No ref there ⇒ take it from the request that brought you here; only when there is none, **ask**. Never pick a task yourself. Whatever else the user wrote with the ref says what they want of the plan, or answers a question this command would ask.

This file carries **sequence only**. **How to get to a plan is not in here**: it is in the plugin's planning method, `${CLAUDE_PLUGIN_ROOT}/skills/task-work/reference/plan-method.md`. **What a plan holds is in neither file**: it is the "Writing a plan" section of `task_authoring_guide`, read at runtime. Do not write a plan out of what you remember about Lorvel.

## Language

You are handed a ref, not prose — so **the task itself tells you which language to work in**: a task written in Vietnamese gets Vietnamese replies, a Vietnamese plan and a Vietnamese log entry. This file being in English is no reason to answer in English. **The user's own words win for chat**: if they write to you in another language, answer in that one; the plan and the log entry still follow the task.

**Never translate identifiers** — file paths, function and column names, command names, task refs, UI labels and anything quoted stay verbatim.

## What this command writes

**The `plan` of that one task, and one log entry on it.** Nothing else:

- **No status moves** — not this task's, not its parent's.
- **No other task is created or edited.** No subtask either, even when the plan maps slices: creating them is the user's to do.
- **No file of the repository is changed.**
- **No start on the work**: no code, no branch, no commit. Finishing step 5 is the end of the command.

And **no approval round**: the user reads the plan once it is saved, and can rewrite or remove it.

## Stop gates

| | Where | Rule |
|---|---|---|
| **GATE-1** guide and tools | step 1 | `task_authoring_guide` missing, or its answer has no "Writing a plan" section ⇒ **stop and say so plainly**. `update_task` or `log_progress` missing ⇒ **stop and say so now**, not at step 4. Report what is missing and nothing more: do not go digging through MCP config, and never print a token, bearer or key, not even truncated. |
| **GATE-2** a plan already there | step 1 | The task already has a plan ⇒ **ask whether to replace it** once step 1's reads are in, before the reading of step 2, and **write nothing until the user says yes**. Say what a yes costs: saving a plan replaces the whole of the one before, and nothing keeps the old text. No ⇒ the command ends, and the plan stays as it is. The request that started this run already says to replace it ⇒ that is the yes. |

Neither has an off switch.

**No one to ask.** What decides this is **who reads your reply**, not who started the command. Typed by the user, invoked by you from their plain-words request, or chained from another skill in this conversation ⇒ the user reads it: ask as usual. Running as a **subagent** — or as a skill that runs forked — whose final message goes to another agent ⇒ nobody who can answer will see a question. Then wherever this command would ask — no ref, a closed task, **GATE-2**, step 3 — **end the command there**: hand back the questions, say plainly that nothing was written, and stop. Having no way to reach the user is not permission to answer for them: the caller takes the questions to them and runs the command again with the answers. Nothing to ask ⇒ straight through to step 5.

## The steps

| Step | In one line |
|---|---|
| **1** Locate | The task, the guide, the planning method. **GATE-1**, then **GATE-2**. |
| **2** Read | What the planning method lists. Read only. |
| **3** Ask | What cannot wait for the plan. |
| **4** Write | The plan; then save it. |
| **5** Report | Once saved: one log entry, the link, stop. |

### 1. Locate

Three reads, all before any question about the task, in one message where you can: `get_task` with the ref; `task_authoring_guide` — keep its `token`, and read its "Writing a plan" section whole; and the planning method, with the Read tool.

- **No Lorvel tools in this session, or the planning method cannot be read** ⇒ stop, and report it as **GATE-1** reports a missing tool.
- **The task is closed** — its status is in the `completed` or the `dropped` category ⇒ say so and ask whether to plan it anyway, before the reading of step 2 and in the same round as **GATE-2**'s question when both apply. No ⇒ the command ends, with nothing written.
- **The task has subtasks** ⇒ the work is already split, which answers what the planning method asks about splitting. Plan the task you were given, as the method says for work that is split: those subtasks are its slices. Read each with `get_task`; write to none, their order included.

### 2. Read

Read everything the planning method lists. Where `get_task` returned only the newest part of the log, the method means the whole of it.

**Change nothing while you read**: no file edited, no command that writes. **Open no file in a `.lorvel/` folder**: what is there is written for other commands, and reaches a model only through the loader they run.

Part of that list cannot be read here — no codebase, no `search_knowledge` ⇒ carry on without it, and say which in the log entry and the report.

### 3. Ask

Ask what the planning method says cannot wait for the plan, the way it says to ask. This command asks no more than that.

**Nothing to ask ⇒ go straight to step 4. Do not ask permission to write.**

### 4. Write

Write the plan the way the planning method says. What a plan holds is in the guide's section, not in this file.

Save it with `update_task` alone in its message, passing the `token` from step 1 and `plan` — no other field.

- **Refused for an expired token** ⇒ ordinary, not a fault: call `task_authoring_guide` again for a fresh one and retry once.
- **Refused for anything else** — a credential that can only read, a permission nobody gave ⇒ say plainly that the plan is not saved, show it in chat so the work is not lost, and write no log entry.

### 5. Report

Only once the plan is saved:

1. **One** `log_progress` on the task, with no status. It opens with this line, **in the language of the task**:

   > *This plan was written by an agent via `/lorvel:task-plan`. Nobody read it before it was saved.*

   Translate the sentence; keep `/lorvel:task-plan` **verbatim** — that name is how anyone finds which plans an agent wrote. The rest says briefly what the user answered on the way, whether a plan the task had was replaced, what of the reading was skipped, and — where the plan maps slices — that it does and is not to be built from.

   This call fails ⇒ check the task's log before one more try: the entry may be there. Still missing ⇒ tell the user the plan is saved but has no log entry.
2. Report to the user as `[<ref>](<url>)`, taking `url` from the response. Say in a line or two what is still undecided and what of the reading was skipped, and that the plan is theirs to rewrite or remove.
