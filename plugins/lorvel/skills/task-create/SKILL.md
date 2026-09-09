---
name: task-create
description: Step 1 — create a Lorvel task from a description
argument-hint: [what needs doing]
disable-model-invocation: true
---

Create a task on Lorvel from this description: **$ARGUMENTS**

No description given ⇒ ask the user before doing anything else.

This file carries **sequence only**. **The shape of a task is not in here** — it comes from `task_authoring_guide` at runtime. Do not write a task out of what you remember about Lorvel.

## Language

**Write the task in the language the user wrote to you in.** This file is in English because its readers are the people installing the plugin; the task's readers are the user's own team. A description in Vietnamese gets a Vietnamese `title` and `body`; one in Japanese gets Japanese. Answering in English because this file is in English is the wrong instinct — the file is instructions to you, not a sample of the output.

**Never translate identifiers.** File paths, function and column names, command names, UI labels, error strings, and anything the user quoted stay **verbatim**. Translating them invents a second vocabulary that matches neither the code nor any later search.

If the tasks that come back at step 2 are consistently in a different language from the user's, that difference is the project's working language, not a mistake — say so and ask which to use. Do not switch on your own. Mixing languages inside one project costs more than it looks: `title` and `body` are the indexed text, so a split vocabulary weakens every duplicate check that follows.

## 1. Get the guide, and check the tools before spending the user's time

Call `task_authoring_guide`. Keep the `token` **and read the whole guide it returns**.

The guide is the only source for: which fields a task has and what belongs in each, this project's status vocabulary, link syntax, and the rule for each field. If you catch yourself about to *recall* one of those instead of reading it — stop and read.

Cannot call this tool ⇒ **stop here and say plainly that it is missing.** Do not draft anyway: no guide means no shape, and a task that is well-formed but wrongly shaped is worse than no task.

⛔ Reporting a missing tool means **reporting that it is missing** — nothing more. Do not go digging through MCP config files to diagnose it on the user's behalf, and **never print a token, bearer or key** — not truncated, not "so you can compare it against yours". Users can open their own files; printing it pushes their secret into a chat window they may copy elsewhere.

Then check the rest: are `check_similar_tasks`, `create_task`, `log_progress` present? A missing **write** tool, or a read-only credential ⇒ **say so now**. The five steps below are mostly spent waiting on a human; discovering at the last one that you cannot write means the user answered everything for nothing.

`search_knowledge` is different: it is a **read** tool, used at step 4. Missing it **does not block** — note it and carry on.

## 2. Check for duplicates

Draft a `title` from the user's description — no need to know the kind of work yet, no need for full detail — and call `check_similar_tasks`.

⚠️ **Read the matches; do not filter on `verdict`.** A real near-duplicate can come back as `verdict: distinct` with low similarity, because your draft is one sentence long while the existing task already has a thick body — the two vectors sit apart for a reason that has nothing to do with whether they are the same work. The better developed a task is, the lower it tends to score here.

Any match that **could** be the same work:

1. **Show it to the user** — ref, link, and both the verdict and the similarity the tool returned.
2. Ask: extend that task, or is this genuinely different work?
3. Until they answer, **create nothing**.

This step comes first because it is cheap and it can cut every step after it: work that already has a task should not cost the user a single question.

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

Finishing item 3 is **the end of the command**. Do not carry on into planning or implementing the task you just made — that is different work, and the user will ask for it when they want it.
