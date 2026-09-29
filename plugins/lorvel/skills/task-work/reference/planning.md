# Phases 1–2 — understand, then plan

Read this before phase 1. The stop gates that end these phases are stated in `SKILL.md`; this file is the detail.

**Sections from this run's customisation.** Look at the `<customisation>` block as each phase and gate in this file starts and ends, rather than trusting what you remember of the start of the run, and run its sections as its `Sections:` line says. No block in view ⇒ follow `customisation.md`, beside this file, first.

## Phase 1 — Read and analyse

- Read the task's `body` and `plan` properly.
- `search_knowledge`, two or three queries on the *identifiers* in the task — endpoint, column, function, rule name — then `get_knowledge` on the plausible hits. **Do not guess a project convention.** This is the step that keeps this command portable: the procedure lives here, the project's truth lives in Lorvel and is read at runtime.
- Find the code the task is about. Read the repo's agent instructions file (`CLAUDE.md`, `AGENTS.md`) before the code — a rule stated there outranks your reading of the code.
- Pull it together: what you understand, which files this will touch, what is still unclear.

→ **STOP-1**: if you have questions, ask them and wait.

## Phase 2 — Plan

1. `task_authoring_guide` for a `token`.

   ⚠️ The token lives roughly fifteen minutes, and with STOP-2 on, step 5 sits behind a human reading a plan. Expiring here is **ordinary, not a fault**: call the guide again for a fresh token and retry once. Never drop a plan the user already approved because a token aged out.
2. Write a plan with: **Context** · **Changes by file** · **Order of work** · **Definition of done** · **Risks and gotchas**.
3. The order of work **must** include a **knowledge audit** step immediately before closing the task.
4. Links inside Lorvel fields use `lorvel://task/<ref>`; when talking to the user, link the `url` from the response instead — `lorvel://` is a dead link in chat.
5. **Write it**: `update_task` with the plan, then `log_progress` moving the task to `in_progress`.

**STOP-2 on** ⇒ insert it before step 5: show the plan in chat, wait, and only write and code once it is approved. It is on with `--plan`, and when this run's `<customisation>` block says STOP-2 is on by default — unless `--no-plan` was typed for this run without `--plan`. Look at that block now rather than trusting what you remember of the start of the run. No block in view ⇒ follow `customisation.md`, beside this file, before deciding.

**STOP-2 off** ⇒ write it and carry on — but still **print the plan once** before coding, so the user can stop you if the direction is wrong.

**If this task is a subtask** — as you move it to `in_progress`, check the parent:

- Parent not started and not closed ⇒ `log_progress` moving the parent to `in_progress`, with a one-line note saying which slice just began.
- Parent already in progress ⇒ leave it alone.
- Parent closed while this slice is still open ⇒ **tell the user**; do not reopen it yourself. Most likely it was closed deliberately.

Do this in phase 2, not phase 0: the work only really starts once phase 1 is through, and stopping at STOP-1 would leave the parent wearing a status that lies.
