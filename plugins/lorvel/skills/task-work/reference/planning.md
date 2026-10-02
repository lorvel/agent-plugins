# Phases 1–2 — understand, then plan

Read this before phase 1. The stop gates that end these phases are stated in `SKILL.md`; this file is the detail.

**Sections from this run's customisation.** Look at the `<customisation>` block as each phase and gate in this file starts and ends, rather than trusting what you remember of the start of the run, and run its sections as its `Sections:` line says. No block in view ⇒ follow `customisation.md`, beside this file, first.

**How to get to a plan is in the plugin's planning method**: `plan-method.md`, beside this file. Read it now, before anything else in phase 1. What phase 1 reads and how it asks is in that file, and so is how phase 2 writes a plan; this file adds the order of the two phases and their gates. Missing ⇒ say so and stop.

## Phase 1 — Read and analyse

- Read everything the planning method lists.
- Pull it together: what you understand, which files this will touch, what is still unclear.

→ **STOP-1**: if you have questions, ask them and wait. Ask them the way the planning method says, and ask more than it requires: this command goes on to build, so nothing still unclear is left for the plan to carry. What a plan the task already has leaves open, or gets wrong, is asked here too.

## Phase 2 — Plan

Where `SKILL.md` and this file say to write or save the plan, they mean a plan this run wrote. A plan the task already had is kept, as the second case here says.

**The task has no plan** ⇒

1. `task_authoring_guide` for a `token`.

   ⚠️ The token lives roughly fifteen minutes, and with STOP-2 on, step 3 sits behind a human reading a plan. Expiring here is **ordinary, not a fault**: call the guide again for a fresh token and retry once. Never drop a plan the user already approved because a token aged out.
2. Write the plan the way the planning method says. What a plan holds is in the guide you just called, not in this file.
3. **Save it**: `update_task` with the plan, then `log_progress` moving the task to `in_progress`.

**The task already had a plan when this run began** ⇒ that plan is the plan. Write no other, and do not ask whether to: a plan being there is the answer. The planning method's rules for writing a plan are for a plan this run writes; they are no reason to change that one, or to ask about changing it.

- **What STOP-1 settled** goes into the note of the `log_progress` that moves this task to `in_progress`, whether or not it touches the plan.
- **No answer changed the approach or a step** ⇒ the plan is not saved again. That `log_progress` is the only write to this task.
- **An answer changed the approach or a step** ⇒ the guide says a plan is rewritten when the approach changes. Rewrite the lines that answer changed, in place, and nothing else — no other line re-worded, added or dropped: a plan is replaced whole, so what you do not send back is gone. Say which lines changed, then save it as steps 1 and 3 say.
- **The user asks for a new plan in this run** ⇒ write one, as for a task with none.

**The plan maps slices instead of the work itself**, because the user chose to split it ⇒ in either case this run builds nothing and moves no status. A plan this run wrote or changed is saved with `update_task` alone. What STOP-1 settled goes into a `log_progress` note that carries no status and says the plan maps slices and is not to be built from, so a later run reads that in the log. Stop and say so: the slices are the user's to create, and each is worked by a run of its own.

**Links.** Inside Lorvel fields — the plan, a log note — use `lorvel://task/<ref>`; when talking to the user, link the `url` from the response instead: `lorvel://` is a dead link in chat.

**STOP-2 on** ⇒ show the plan in chat and wait before anything is written, the status move included; save and code only once it is approved. A plan the task already had is shown as it stands, not summarised, and waited on the same way, with the lines an answer changed pointed out. STOP-2 is on with `--plan`, and when this run's `<customisation>` block says STOP-2 is on by default — unless `--no-plan` was typed for this run without `--plan`. Look at that block now rather than trusting what you remember of the start of the run. No block in view ⇒ follow `customisation.md`, beside this file, before deciding.

**STOP-2 off** ⇒ save and carry on — but still **print the plan once** before coding, so the user can stop you if the direction is wrong. A plan the task already had is not printed: say in one line that the run follows the plan already on the task, and say it in the `log_progress` note too.

**If this task is a subtask** — as you move it to `in_progress`, check the parent:

- Parent not started and not closed ⇒ `log_progress` moving the parent to `in_progress`, with a one-line note saying which slice just began.
- Parent already in progress ⇒ leave it alone.
- Parent closed while this slice is still open ⇒ **tell the user**; do not reopen it yourself. Most likely it was closed deliberately.

Do this in phase 2, not phase 0: the work only really starts once phase 1 is through, and stopping at STOP-1 would leave the parent wearing a status that lies.
