# Steps 6–7 — check again, then write

Read this before step 6. The duplicate gate that can still end the command here is stated in `SKILL.md`; this file is the detail.

## 6. Check duplicates again — DO NOT SKIP THIS STEP

Only now do you have a full `title` + `body`. **Call `check_similar_tasks` again with that full version** — the run at step 2 was on a thin draft and was the weakest measurement; this one is the real one.

A match that could be the same work is handled exactly as at step 2: show it with its ref, link, verdict and similarity, ask, and **create nothing until they answer**. That gate has not moved. Apart from *No one to ask* in `SKILL.md`, it is now the only thing that can end this command after step 2, so read the matches and not the verdict — the warning at step 2 about a well-developed task scoring low applies here too.

Nothing duplicates ⇒ **go straight to step 7. Do not ask permission to write.** There is no create-or-edit-or-cancel round here and there is not meant to be. A task is not a deploy: `update_task` rewrites the title and body of one that already exists, and one nobody wants moves to a `dropped` status. A round spent here sells the user a decision they already hold, and charges it on every single run to undo the occasional bad one.

**What that trade costs, and where the bill lands.** The `body` is text **you** wrote, not the user, and it is **indexed** — one wrong sentence in it travels into every future `check_similar_tasks`, on this task and on every task drafted after it. An approval round used to put a human in front of that text before it went in. Nothing does now. That does not make the accuracy optional; it moves where it has to be bought, and the place is **step 5**. Every question you talk yourself out of asking there becomes a sentence that reaches the index unread. It is why step 5 says ask rather than infer, and why skipping it is the one shortcut in this command that has nothing downstream left to catch it.

## 7. Write

1. `create_task`, with the `token` from step 1.

   ⚠️ The token lives about fifteen minutes, and everything from step 4 to here is lookups plus the user's own answers at step 5 — **the reading at step 4 stretches that window further**. Expiring here is **ordinary, not a fault**. Rejected for an expired token ⇒ call `task_authoring_guide` for a fresh one and retry exactly once. Do not throw the draft away over it: the user answered questions to build that text.

2. Then **one** `log_progress` on the task you created, opening with this line — **in the same language as the task**:

   > *This task was drafted by an agent via `/lorvel:task-create`, from the user's own description and their answers to its questions. The user did not read the final text before it was written.*

   The description came from **another agent** rather than from the user — you are running as a subagent, or another skill composed it ⇒ open with this line instead:

   > *This task was drafted by an agent via `/lorvel:task-create`, from a description another agent passed on for the user. The user did not read the final text before it was written.*

   Translate the sentence; keep `/lorvel:task-create` **verbatim**. That name is the part that makes the receipt findable — anyone auditing which tasks an agent drafted greps for the command, not for a sentence whose wording they would have to guess in every language. Either English line is reference wording: translate its meaning, do not add to it.

   **Do not soften the second half of it, and do not drop it as noise.** It is the one thing a later reader cannot work out for themselves: this `body` is indexed text that no human checked. Without it the receipt implies a review that never happened.

   The rest of the entry says briefly where the task came from: the user's own sentence, the kind you settled on, any duplicate weighed at step 2 or 6, and **what step 4 turned up** — including when the answer is nothing.

   This call fails ⇒ retry once, then **tell the user the task exists but has no provenance entry**. Do not go quiet: that entry is the only record that an agent drafted this.

3. Report back to the user as `[<ref>](<url>)`, taking `url` from the response — do not build the URL yourself.

   They are meeting this text for the first time here, so the report is where a wrong guess still gets caught cheaply. Name in one line what you settled on and what you leaned on: the kind, and anything step 4 turned up that shaped the scope. Then say plainly that it is theirs to change — they can edit the title and body, or drop the task outright — so a sentence you got wrong costs a correction rather than a rewrite.
