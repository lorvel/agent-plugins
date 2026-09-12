# Steps 6–7 — check again, show the draft, write

Read this before step 6. The approval gate that ends step 6 is stated in `SKILL.md`; this file is the detail.

## 6. Check duplicates again, then show the draft — DO NOT SKIP THIS STEP

Only now do you have a full `title` + `body`. **Call `check_similar_tasks` again with that full version** — the run at step 2 was on a thin draft and was the weakest measurement; this one is the real one. Handle new matches as in step 2.

Then show the user **the whole text** of what is about to be written: `title`, `body`, the kind chosen, and every other field you intend to send.

Ask with `AskUserQuestion`: **Create / Edit / Cancel**.

- **Edit** ⇒ take the notes and show it again. Repeat until they agree.
- **Cancel** ⇒ stop the command, and say plainly that nothing was written to Lorvel.
- Only **Create** may go on to step 7.

If the user says *"up to you"* or *"whatever works"*: **that is not approval.** Put your specific proposal in front of them and ask for explicit confirmation of that proposal.

This step exists because the `body` is text **you** wrote, not the user — and it is indexed text, so one wrong sentence here travels into every future task search. This is the only point in the flow where a human reads it.

## 7. Write

1. `create_task`, with the `token` from step 1.

   ⚠️ The token lives about fifteen minutes, and everything from step 3 to here is lookups plus waiting on a human — **step 4 stretches that window further**. Expiring here is **ordinary, not a fault**. Rejected for an expired token ⇒ call `task_authoring_guide` for a fresh one and retry exactly once. Do not throw away the draft the user just approved.

2. Then **one** `log_progress` on the task you created, opening with this line — **in the same language as the task**:

   > *This task was drafted by an agent via `/lorvel:task-create`; the user read and approved the content before it was written.*

   Translate the sentence; keep `/lorvel:task-create` **verbatim**. That name is the part that makes the receipt findable — anyone auditing which tasks an agent drafted greps for the command, not for a sentence whose wording they would have to guess in every language. The English above is the reference wording: translate its meaning, do not add to it.

   The rest of the entry says briefly where the task came from: the user's own sentence, the kind chosen, any duplicate weighed at step 2 or 6, and **what step 4 turned up** — including when the answer is nothing.

   This call fails ⇒ retry once, then **tell the user the task exists but has no provenance entry**. Do not go quiet: that entry is the only record that an agent drafted this.

3. Report back to the user as `[<ref>](<url>)`, taking `url` from the response — do not build the URL yourself.
