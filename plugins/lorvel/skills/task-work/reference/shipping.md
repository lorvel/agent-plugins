# Phase 6 — ship, verify, and close

Read this before phase 6, including when phase 0 sends you straight here. The knowledge audit in step 4 is mandatory and has no exception.

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
7. **If the task was a subtask**, look up what comes next: `get_task` on the parent and read its subtasks **in the order the array returns them** — that order is the implementation order, and each subtask's `position` is auxiliary, so never re-sort by it. The next slice is the first still-open one after this — unless the parent's plan states a dependency order, which wins. Whatever you judge from a log in the rest of this step, such as whether that slice is blocked or whether a line of the parent's definition of done is met, judge from all of that log, reading any part `get_task` left out as in phase 0 step 5. If that slice is **blocked** (waiting on a decision, on another slice), say where it is blocked and **do not hand over a command** — handing someone a blocked slice is inviting them into a wall. **No open slices left** ⇒ check the parent's own definition of done: close it if it is met, and if it is not, say exactly which line cannot be shown yet.
8. **Remind the user to compact.** You cannot run `/compact` — only they can. Hand them a line to copy, naming what to keep and what to drop: keep the closed task's ref and the evidence it closed on, the knowledge that changed, any convention discovered, and what is still unfinished; drop the contents of files read, build and test output, and the diffs. Put this **last**, after the next-slice suggestion — compacting discards what they have not read yet.
