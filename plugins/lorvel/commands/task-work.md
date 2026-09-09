---
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
4. Work out which phase you are entering, and **say which one**.

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

## Phase 1 — Read and analyse

- Read the task's `body` and `plan` properly.
- `search_knowledge`, two or three queries on the *identifiers* in the task — endpoint, column, function, rule name — then `get_knowledge` on the plausible hits. **Do not guess a project convention.** This is the step that keeps this command portable: the procedure lives here, the project's truth lives in Lorvel and is read at runtime.
- Find the code the task is about. Read the repo's agent instructions file (`CLAUDE.md`, `AGENTS.md`) before the code — a rule stated there outranks your reading of the code.
- Pull it together: what you understand, which files this will touch, what is still unclear.

→ **STOP-1**: if you have questions, ask them and wait.

## Phase 2 — Plan

1. `task_authoring_guide` for a `token`.

   ⚠️ The token lives roughly fifteen minutes, and with `--plan` step 5 sits behind a human reading a plan. Expiring here is **ordinary, not a fault**: call the guide again for a fresh token and retry once. Never drop a plan the user already approved because a token aged out.
2. Write a plan with: **Context** · **Changes by file** · **Order of work** · **Definition of done** · **Risks and gotchas**.
3. The order of work **must** include a **knowledge audit** step immediately before closing the task.
4. Links inside Lorvel fields use `lorvel://task/<ref>`; when talking to the user, link the `url` from the response instead — `lorvel://` is a dead link in chat.
5. **Write it**: `update_task` with the plan, then `log_progress` moving the task to `in_progress`.

**With `--plan`** ⇒ insert **STOP-2** before step 5: show the plan in chat, wait, and only write and code once it is approved.

**Without the flag** ⇒ write it and carry on — but still **print the plan once** before coding, so the user can stop you if the direction is wrong.

**If this task is a subtask** — as you move it to `in_progress`, check the parent:

- Parent not started and not closed ⇒ `log_progress` moving the parent to `in_progress`, with a one-line note saying which slice just began.
- Parent already in progress ⇒ leave it alone.
- Parent closed while this slice is still open ⇒ **tell the user**; do not reopen it yourself. Most likely it was closed deliberately.

Do this in phase 2, not phase 0: the work only really starts once phase 1 is through, and stopping at STOP-1 would leave the parent wearing a status that lies.

## Phase 3 — Implement

- Follow the project's own conventions for structure, package manager and style. They are not in this file. Read the repo's instructions file, and `search_knowledge` for anything it does not cover — a convention you assume is a convention you are inventing.
- `log_progress` at every meaningful step: something found, something decided, something blocking.
- Run **this repo's gates** before handing over — the ones its CI runs, plus whatever it has locally. Find out what they are rather than assuming a stack; a project with no gates at all is itself worth telling the user about.
- ⚠️ Where CI does **not** run a check that exists locally, the local run is the real gate, not a rehearsal. Worth knowing which is which before you rely on either.
- Changing something a user sees ⇒ verify it yourself, in the thing that renders it. Do not hand the user a change and ask them to look.

## Phase 4 — Review

Get a review pass over the change — whatever review tooling this setup has — and let it apply what it finds. Then **run every gate from phase 3 again**: an automatic fix can still break a type check or a test.

No review tooling here ⇒ **say so, then review it yourself** against the task's definition of done and the conventions phase 1 turned up. Do not quietly skip the step: it is the only place in this flow where the change is read as a whole rather than written a piece at a time.

## Phase 5 — Hand over

- Summarise for the user: **the files changed, grouped by repo**, plus a suggested commit message.
- `log_progress` onto the def this project uses for *code complete, not yet live* — read the vocabulary from the guide; if the project has no such def, say so and stay in `in_progress` rather than inventing one.

That state means **code done, not yet confirmed live**, and it covers both the wait for approval and the deploy that follows. So **`--auto` still enters it**: the flag removes the *waiting*, not the *not yet live*.

→ **STOP-3**: wait for approval. **Do not commit or push on your own.** Once approved, carry straight on to phase 6 without asking again.

**With `--auto`** ⇒ drop the waiting, but **still print the summary above** so the user can see what is about to ship, then go straight to phase 6. Log it as delegated in advance by the flag; do not write "waiting for approval" when nobody is waiting.

**Going back to change code** — review found something, the pipeline went red, the user asked for a rework — ⇒ move the status back explicitly, targeting the exact def. Sending only the category can be a **silent no-op**: if the task is already in that category, its current def is kept, and the board goes on claiming the work is about to ship. Read the guide for how this project's defs sit inside the categories.

## Phase 6 — Ship, verify, and close

Enter here once the user approved at STOP-3, **or** with `--auto` and the gates green.

1. **Commit and push**, one repo at a time, in **dependency order** — whatever the others build on goes first, its consumers after. If an earlier repo's pipeline is not green yet, **do not push the next one**. A chain broken in the middle is worse than nothing deployed, and with `--auto` nobody is watching.
2. **Watch the pipeline**, if this project has one. A failure that looks transient rather than caused by the change ⇒ retry it **before** digging into the logs. No pipeline ⇒ skip to step 3 and say you did — with nothing between the push and production, that live check is the only gate left.
3. **Verify it live.** Not "the pipeline is green" — find the change itself in what is now running: a marker string this change and only this change produced, an endpoint that answers differently, a row that now exists. A generic string proves nothing, because it was already there.
4. **Knowledge audit** — mandatory, never skipped:
   - `search_knowledge`, two or three queries on the identifiers you just changed; follow `links_to` / `linked_from` from any unit you created or edited.
   - Open the candidates and look for a sentence that is **now wrong, or now missing a clause**. The second kind is the one that survives review: still true, no longer complete.
   - `check_knowledge_conflict` before editing. **Fix in place — never append a correction under the old text**, or the unit ends up asserting both.
   - A knowledge unit holds contract and semantics. **Cut implementation detail**; do not mirror the code, which will move without telling you.
   - Found nothing to change? **Say that too** — "audited N units, none needed changing". Silence cannot be told apart from never having looked.
5. `log_progress` closing the task with `status: "completed"`, carrying the evidence from step 3.
6. **Record what stays true.** The task dies; the knowledge outlives it. Anything you learned that the code cannot say — a decision and why, a trade-off, a gotcha that cost you an hour — goes to `propose_knowledge`, not into a note on your own machine. One governed source is the whole point; a second copy in a local file is how the two start disagreeing.
7. **If the task was a subtask**, look up what comes next: `get_task` on the parent and read its subtasks **in the order the array returns them** — that order is the implementation order, and each subtask's `position` is auxiliary, so never re-sort by it. The next slice is the first still-open one after this — unless the parent's plan states a dependency order, which wins. If that slice is **blocked** (waiting on a decision, on another slice), say where it is blocked and **do not hand over a command** — handing someone a blocked slice is inviting them into a wall. **No open slices left** ⇒ check the parent's own definition of done: close it if it is met, and if it is not, say exactly which line cannot be shown yet.
8. **Remind the user to compact.** You cannot run `/compact` — only they can. Hand them a line to copy, naming what to keep and what to drop: keep the closed task's ref and the evidence it closed on, the knowledge that changed, any convention discovered, and what is still unfinished; drop the contents of files read, build and test output, and the diffs. Put this **last**, after the next-slice suggestion — compacting discards what they have not read yet.

## Boundaries

Working the task means working the task. Do not deploy anything the task did not ask for, do not go fix things you noticed on the way — note them for the user instead — and do not open the next slice because this one went well.
