# Phases 3–5 — implement, review, hand over

Read this before phase 3. STOP-3 and what `--auto` does to it are stated in `SKILL.md`; this file is the detail.

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
