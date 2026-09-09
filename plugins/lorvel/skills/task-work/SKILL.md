---
name: task-work
description: Work one Lorvel task end to end, with stop gates
argument-hint: <task-ref> [--plan] [--auto]
disable-model-invocation: true
---

Work this Lorvel task: **$ARGUMENTS**

A ref like `LA-12` is the task to work. No ref ⇒ **ask**. Never pick a task yourself.

- `--plan` ⇒ turns **STOP-2 on**: show the plan and wait for approval before writing code. Without it, write the plan to Lorvel and carry on.
- `--auto` ⇒ turns **STOP-3 off**: gates green means commit and push without waiting for the diff to be approved.
- Independent, and they combine. Either order around the ref.

The user saying *"let me approve the plan first"* or *"don't code yet"* counts as `--plan`.

This file carries **sequence only**. What is specific to a project — its status vocabulary, its gates, how it ships — is **not in here**, and must not be written into here later. Ask at runtime: `task_authoring_guide` for the fields and this project's status vocabulary, `search_knowledge` for the conventions and gotchas the team already settled. If you catch yourself about to *recall* one of those instead of reading it, stop and go read it.

## Language

You are handed a ref, not prose — so **the task itself tells you which language to work in.** Read its `title`, `body`, `plan` and existing log at phase 0 and follow them: a task written in Vietnamese gets Vietnamese replies, a Vietnamese plan and Vietnamese progress notes. Answering in English because this file is in English is the wrong instinct — the file is instructions to you, not a sample of the output. What you write back outlives the session and is read by the team who wrote the task, so it belongs in their language, not yours.

Two things do **not** follow the task:

- **The user's own words win for chat.** If they speak at a stop gate in another language, answer in the one they used. Nobody should have to read your reply in a language they did not choose. The task still governs what you *write into Lorvel* — so a Vietnamese conversation about an English task means Vietnamese in chat and English in the plan and the log, and that split is correct rather than sloppy.
- **Knowledge units follow the knowledge base**, not the task. Phase 1's `search_knowledge` results show which language the team keeps knowledge in; a unit written against the grain of the rest of the store is a unit their next search finds less well.

**Never translate identifiers.** File paths, function and column names, command names, task refs, UI labels, error strings, and anything quoted stay **verbatim**. Translating them invents a second vocabulary that matches neither the code nor any later search.

Nothing to judge from — a bare title, an empty body — ⇒ fall back to the language the user wrote to you in; with none of that either, ask in one line rather than quietly picking for them.

## Stop gates

| | Where | On when | Rule |
|---|---|---|---|
| **STOP-1** | end of phase 1 | **always** | Anything still unclear ⇒ **ask the user**, do not infer and code on. |
| **STOP-2** | end of phase 2 | **only with `--plan`** | Show the plan, wait for approval, then write it and start coding. |
| **STOP-3** | end of phase 5 | **unless `--auto`** | **Do not commit or push on your own.** Show the diff and wait. Approval ("commit it", "ok push") ⇒ commit, push, then carry straight on to phase 6. |

**No flag turns STOP-1 off**, and "this task is small" is not a reason to skip it. Skipping plan approval or diff approval does **not** carry over into skipping STOP-1 — wherever something is genuinely unclear you still ask. That is the valve that stops "run straight through" from becoming "guess".

**`--auto` switches off the HUMAN gate, not the MACHINE gates.** Gates red, review not run, or a secret scan blocking a file ⇒ **stop and say so**, do not route around it. `--auto` is the user delegating this one turn in advance; it is not a licence to push code that has not been through the checks.

**`--auto` does not apply to changes with no undo** — a database migration, a change to a deploy pin, anything that alters production schema or data. Those **fall back to STOP-3** and wait for approval, flag or no flag. Say it out loud — *"this diff touches a migration, so `--auto` does not apply; waiting for approval"* — rather than waiting in silence. Ask the project which changes those are (`search_knowledge` for its migration and deploy conventions). The reason for carving this one out: anything else pushed by mistake is a revert away, while a migration that has already run in production has no undo button, and that kind of change can lock real tables while it runs.

Two more rules hold whatever the flags say.

**A task closes on evidence, not on effort.** Where the work ships something, that evidence is the change running where it actually runs — not a green pipeline. Where the work ships nothing — a spike, a decision, a piece of documentation, a knowledge unit — the evidence is whatever its definition of done asked for, quoted back. What is never acceptable is closing because the steps were followed: if you cannot point at the thing the task said would be true, it is not done.

**A knowledge audit is mandatory before closing** (phase 6), and that one has no exception.

## Phase 0 — Locate

1. `get_task` with the ref. No Lorvel tools in this session ⇒ **stop here and say plainly which ones are missing.** Do not work the task from what you remember about it — a task worked off a remembered description is the exact failure STOP-1 exists to prevent.

   ⛔ Reporting missing tools means **reporting that they are missing** — nothing more. Do not go digging through MCP config files to diagnose it, and **never print a token, bearer or key**, not even truncated. Users can open their own files; printing it pushes their secret into a chat window they may copy elsewhere.
2. **Subtask guard**: the task has subtasks ⇒ **STOP**. List them with their status and ask which one to work. Splitting work into slices is the user's call, not yours.
3. **Closed guard**: already in the `completed` category ⇒ say so and ask before redoing anything.
4. **Note the task's language** from what you just read, and say which one you will be working in.
   Everything from here — replies, the plan, every log entry — follows it. Deciding this once, out
   loud, at the top is what stops a run from drifting into English three logs later.
5. Work out which phase you are entering, and **say which one**.

Read this project's status vocabulary from `task_authoring_guide` before you read the table below. Status *categories* (`todo` / `in_progress` / `completed` / `dropped`) are the same everywhere; the *defs* over them are each project's own. A def name you remember from somewhere else is a project-fact you invented.

| Sign | Enter at |
|---|---|
| A def meaning "code done, not yet live", log has no commit | STOP-3 — ask whether it was approved |
| Same def, already committed and pushed | Phase 6 step 2 |
| Same def, evidence of it running live already logged | Phase 6 step 4 |
| `in_progress` — no log, or only the entry that created the task | Phase 1 |
| `in_progress` — plan settled, nothing logged about implementing | Phase 3 |
| `in_progress` — implementation logged part-way | Phase 3, read the log for how far |
| `in_progress`, log shows a commit — project has no such def | Phase 6, at the first step the log does not already cover |

The last row matters for projects whose vocabulary is just the four categories: with no def for *code done, not yet live*, shipped work sits in `in_progress` looking exactly like unstarted work. The log is what tells them apart — read it before deciding you are at phase 1.

## The phases

Each phase's detail sits beside this file, and **you read the file for a phase before you work that
phase** — the steps, their order and the traps are in there. The one-line summaries below are a map,
not the instructions; working from them is the guessing this command exists to prevent. Phase 0 can
send you straight into the middle of this list, so read whichever file that phase lands in, not the
ones you skipped past.

| Phase | In one line | Read first |
|---|---|---|
| **1** Read and analyse | The task, the knowledge, the code — then what is still unclear. Ends at **STOP-1**. | `reference/planning.md` |
| **2** Plan | Write the plan, put a knowledge audit in it, move the task to `in_progress`. **STOP-2** with `--plan`. | *(same file)* |
| **3** Implement | Build it, log as you go, run this repo's own gates. | `reference/building.md` |
| **4** Review | A review pass, then every gate again. | *(same file)* |
| **5** Hand over | Files changed by repo, move to *code done, not yet live*. Ends at **STOP-3**. | *(same file)* |
| **6** Ship, verify, close | Push in dependency order, prove it live, audit the knowledge, close on evidence. | `reference/shipping.md` |

Paths are relative to `${CLAUDE_SKILL_DIR}`. If a file is missing, say so and stop — do not
reconstruct the phase from memory.

## Boundaries

Working the task means working the task. Do not deploy anything the task did not ask for, do not go fix things you noticed on the way — note them for the user instead — and do not open the next slice because this one went well.
