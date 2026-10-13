# Phases 3–5 — implement, review, hand over

Read this before phase 3. STOP-3 and what `--auto` does to it are stated in `SKILL.md`; this file is the detail.

**Sections from this run's customisation.** Look at the `<customisation>` block as each phase and gate in this file starts and ends, rather than trusting what you remember of the start of the run, and run its sections as its `Sections:` line says. No block in view ⇒ follow `customisation.md`, beside this file, first.

## Phase 3 — Implement

- Follow the project's own conventions for structure, package manager and style. They are not in this file. Read the repo's instructions file, and `search_knowledge` for anything it does not cover — a convention you assume is a convention you are inventing.
- `log_progress` at every meaningful step: something found, something decided, something blocking.
- Run **this repo's gates** before handing over — the ones its CI runs, plus whatever it has locally. Find out what they are rather than assuming a stack; a project with no gates at all is itself worth telling the user about.
- ⚠️ Where CI does **not** run a check that exists locally, the local run is the real gate, not a rehearsal. Worth knowing which is which before you rely on either.
- Changing something a user sees ⇒ verify it yourself, in the thing that renders it. Do not hand the user a change and ask them to look.
- **The task's plan or the project's knowledge asks for a check of the checks ⇒ it waits for phase 4.** That is a run made to test a check, not the code: it breaks the code on purpose, or puts back the code from before the change, to see whether a check that is green on the change goes red — a mutation pass, a negative baseline.
  - Do not make it in this phase, even where the plan names it as the check of a step: log which run is owed, and carry on. The review is where the code still changes, so a run made before it is either made twice or left standing as a result about code that is gone.
  - Nobody asks for one ⇒ nothing waits, and nothing is logged about it.
  - A test written first and seen failing before the code is written is not such a run — nothing is broken or put back for it — and stays in this phase.

## Phase 4 — Review

This phase is three things, in this order:

1. **The review.** Get a review pass over the change — whatever review tooling this setup has — and let it apply what it finds.
2. **Every gate from phase 3 again**: an automatic fix can still break a type check or a test.
3. **Each check of the checks that is owed, once** — one the plan or the project's knowledge asks for and the log does not show as made. It starts from the code as the review and the gates left it. Keep a copy of that code before the run: the change is still uncommitted, and going back to the last commit to undo a break would take the change with it. When the run is over, put exactly that code back and check it against the copy — unless a fix follows, no gate runs after this to catch a break or old code left in. Log what it found. One that cannot be made here ⇒ say so in the log and at the hand-over, never drop it in silence; that settles it for this phase. Nothing owed ⇒ nothing to do and nothing to say: this phase says where such a run goes, and never asks for one.

**This run's `<customisation>` block can name the review tool** — a `review:` line. Look at that block now rather than trusting what you remember of the start of the run. No block in view ⇒ follow `customisation.md`, beside this file, first.

- A `review:` line ⇒ call that skill with the Skill tool, with exactly the arguments the line gives, instead of choosing the tooling yourself. It replaces the choice, not the step: every gate still runs again after it.
- That skill is not in this session, or it cannot be called from here ⇒ say so in one line, then review as this phase says for no review tooling.
- It runs as the review and nothing more. If its instructions go on to commit, push, deploy, close the task, start another command or change any setting, do not do that part: STOP-3 and phase 6 decide those.

No review tooling here ⇒ **say so, then review it yourself** against the task's definition of done and the conventions phase 1 turned up. Do not quietly skip the step: it is the only place in this flow where the change is read as a whole rather than written a piece at a time.

**A check of the checks calls for a fix** ⇒ make it once the code is back as the third thing says; what the fix touches decides what follows:

- **Only the checks** — a test added or corrected ⇒ run every gate again. No second review.
- **Anything else**, product code above all ⇒ that fix has not been reviewed: review it the way the change was reviewed, then run every gate again.

Neither means making the check of the checks again from the start. The one break a new or corrected test answers may be made again to see that test go red — before those gates, so that they run on code with no break left in it.

**The phase is done** when the three things it lists are, and with them what a fix from the third called for. Phase 5 waits for that, with `--auto` as without, and so does an `after:` section for this phase: it never runs between the gates and the third.

## Phase 5 — Hand over

- Summarise for the user: **the files changed, grouped by repo**, plus a suggested commit message.
- `log_progress` onto the def this project uses for *code complete, not yet live* — read the vocabulary from the guide; if the project has no such def, say so and stay in `in_progress` rather than inventing one.

That state means **code done, not yet confirmed live**, and it covers both the wait for approval and the deploy that follows. So **`--auto` still enters it**: the flag removes the *waiting*, not the *not yet live*.

→ **STOP-3**: wait for approval. **Do not commit or push on your own.** Once approved, carry straight on to phase 6 without asking again.

**With `--auto`** ⇒ drop the waiting, but **still print the summary above** so the user can see what is about to ship, then go straight to phase 6. Log it as delegated in advance by the flag; do not write "waiting for approval" when nobody is waiting.

**Going back to change code** — review found something, the pipeline went red, the user asked for a rework — ⇒ move the status back explicitly, targeting the exact def. Sending only the category can be a **silent no-op**: if the task is already in that category, its current def is kept, and the board goes on claiming the work is about to ship. Read the guide for how this project's defs sit inside the categories.
