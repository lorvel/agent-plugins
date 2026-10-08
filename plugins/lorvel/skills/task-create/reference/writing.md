# Steps 6–7 — check again, then write

Read this before step 6. The duplicate gate that can still end the command here is stated in `SKILL.md`; this file is the detail.

**Sections from this run's customisation.** Look at the loader's output from step 1 as each step and gate in this file starts and ends, and run its sections as its `Sections:` line says. That output no longer in view ⇒ run the loader again, as `SKILL.md` says; refused ⇒ customisation is off for the rest of this run.

## 6. Check duplicates again — DO NOT SKIP THIS STEP

Only now do you have a full `title` + `body`. **Call `check_similar_tasks` again with that full version, and pass as `exclude_ids` every match the earlier checks of this run returned** — each by its `ref` or its `id`. All of them: do not pick by `verdict` or similarity, and include a match the user has already answered about. The run at step 2 was on a thin draft and was the weakest measurement; this one is the real one for every task step 2 did not return. Its answer holds only the closest few, and the matches you have seen would take those places again: leaving them out gives the places to tasks you have not.

Call without `exclude_ids`, and the tool measures every task itself, when any of these holds:

- step 2 returned no match, or you no longer know which it returned;
- the tool as this session lists it takes no `exclude_ids`;
- this session has no `get_task` for the second look below.

**What you excluded does not come back, so weigh it again yourself.** The tool held those tasks against a thin draft and will not hold them against the full one, and all it gave you of each is a title. Before going on, judge each against the full `title` + `body` the way step 2 judged its matches: could this be the same work? Rule a task out on its title only when the title plainly puts it in a different area from the draft — another screen, endpoint, column, function or rule. Every other one — its title touches the draft's area, does not say which area it is in, or is gone from view ⇒ open it with `get_task` and read its body before you decide: a title is as thin on its side as your draft was at step 2. A `get_task` call that is refused or fails ⇒ you have not read that task: call `check_similar_tasks` once more without `exclude_ids`, and let the tool measure it.

A match that could be the same work — from this call or from that second look — is handled exactly as at step 2: show it with its ref, link, verdict and similarity, ask, and **create nothing until they answer**. That gate has not moved. For one from the second look the verdict and similarity are step 2's, measured on the draft title: say so — and if they are gone from view, say that; do not make them up. One the user has already answered about — after you showed it earlier in this run, or by its ref or title in the description this run was given — is not asked about again, unless the work has moved or widened since they answered, by what they said at step 5 or by what step 4 turned up: then their answer was about other work, and it is a new question. Apart from *No one to ask* in `SKILL.md`, this gate is now the only thing that can end this command after step 2, so read the matches and not the verdict — the warning at step 2 about a well-developed task scoring low applies here too.

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

3. An `after:` section for step 7 runs here, once the task and its receipt exist: the report below stays last.

4. Report back to the user as `[<ref>](<url>)`, taking `url` from the response — do not build the URL yourself. The loader printed lines at step 1 that no round has shown yet ⇒ the report opens with them, as `SKILL.md` says.

   They are meeting this text for the first time here, so the report is where a wrong guess still gets caught cheaply. Name in one line what you settled on and what you leaned on: the kind, and anything step 4 turned up that shaped the scope. Then say plainly that it is theirs to change — they can edit the title and body, or drop the task outright — so a sentence you got wrong costs a correction rather than a rewrite.
