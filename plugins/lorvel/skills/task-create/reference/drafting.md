# Steps 3–5 — classify, gather context, ask

Read this before step 3. This file is the detail for the three steps between the duplicate check and the draft.

## 3. Classify the work

Use `AskUserQuestion`, one question, three options:

- **Bug** — something that runs is wrong
- **Change** — deliberately add or alter behaviour
- **Spike** — not enough is known yet, find out first

This kind is **not a Lorvel field**. It only decides what step 5 asks. If the user picks "Other" and names their own kind, take it as given — do not push it back into the three above.

## 4. Gather context: knowledge first, then code

This step is for **understanding the work**, not for solving it.

**Knowledge — what the team already settled and the code cannot say.** Two or three `search_knowledge` queries on the *identifiers* in the user's sentence (screen name, endpoint, column, function, rule name) — on identifiers, not the whole sentence thrown in. Open the plausible hits with `get_knowledge`. This is the only point in the flow where you meet the **conventions, past decisions and recorded gotchas** a user tends to leave out because to them they are obvious.

**Code — where this request lands.** Only when the session is inside a codebase. Read enough to answer two things: what that area **does today**, and what the request would **touch**.

⛔ **Boundaries — this step turns into a different job very easily:**

- **Do not design the fix.** No approach, no plan, no slicing into subtasks. The task does not even exist yet.
- **Read only. Change no files.**
- **There is a floor.** A few queries, a few files. Finding the work is bigger than it looked *is itself something to put in the task* — not a reason to keep reading to the end.
- **No codebase, or no `search_knowledge` ⇒ skip that half, carry on, and tell the user you skipped it.** This is not a gate like the write tools at step 1.

What you find is used in **two places**:

1. **Step 5 asks sharper.** If the code shows two login paths, ask which one rather than something vague. And **do not ask what the knowledge base already answered** — say you already know it. Asking users about something their own team settled is bothering them with their own knowledge.
2. **The `body` at step 6** carries real scope: what this touches, and which knowledge units constrain it. Write **links** to them; **do not copy their content into the body** — a copy is a second version, and it will drift.

Finding nothing must also **be said** at step 6: "searched knowledge and code, found no constraints" is not the same as silence — silence leaves the next reader unable to tell *looked and found nothing* from *never looked*.

## 5. Ask what is missing — DO NOT SKIP THIS STEP

This is the step most often skipped, and the one that separates a task worth having from a task somebody has to rewrite.

Hold the user's sentence against what the guide asks for, **and against what step 4 turned up**. Where the user has not said, **ask** — do not infer it and write it in. Where knowledge already answered, **do not ask** — say you know it, and only raise it if it contradicts what the user said.

Ask by the kind chosen at step 3:

- **Bug** — what happens, what should happen instead, where it shows
- **Change** — what is different once it is done, and how anyone knows it is done
- **Spike** — what question needs answering, and what counts as enough to stop
- **A kind the user named themselves** — work out the equivalent questions for it. Still ask, and still do not force it back into the three above.

Batch them into one `AskUserQuestion` where you can, but **asking beats guessing**.

No `AskUserQuestion` in this session ⇒ ask in text, and fold step 3's classification into the same round. Having no tool to ask with is **not** a reason to stop asking.

`priority`: if the user has not said, **do not ask and do not set it**. The guide already says what leaving it empty means — read it there. Do not lay out a menu of levels for the sake of it.
