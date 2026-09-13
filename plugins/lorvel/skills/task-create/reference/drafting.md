# Steps 3–5 — classify, gather context, ask

Read this before step 3. This file is the detail for the three steps between the duplicate check and the write.

## 3. Classify the work — settle it yourself, do not ask

Read the user's description and settle on one of three:

- **Bug** — something that runs is wrong
- **Change** — deliberately add or alter behaviour
- **Spike** — not enough is known yet, find out first

This kind is **not a Lorvel field** and never becomes one. It lives in exactly two places: it is named aloud in step 5's round and picks which questions that round asks, and it is named again in the step-7 provenance entry.

What it does not get is a **round**: one moment where the command stops and cannot go on until the user answers. Rounds are the unit the user actually pays in, and this command has few enough to count. A round spent here buys a kind that step 5 already puts in front of them twice in the same breath — once as a sentence they can contradict, and again as the questions themselves, since *what happens, and what should happen instead* is what being read as a bug looks like from the outside. Guess right, which is most of the time, and it costs nobody anything; guess wrong and it costs one short follow-up there. That trade is why this step infers.

Step 5 is also the last place it gets caught **before the task is written** — there is no approval round at step 6 to show the draft again — so state it there in a form that invites a correction, and do not read this licence to infer as covering anything else: everything that goes *into* the task still follows step 5's rule of asking rather than assuming.

A kind the user named themselves — in their description, or in reply at step 5 — is taken as given. Do not push it back into the three above.

**Genuinely cannot tell?** Then the sentence is too thin to infer from, and inferring anyway is the wrong move: make the kind **one of the questions in step 5's round**. A sentence that thin is often a spike, so do not quietly fall back on the bug questions while you wait — ask the kind beside *what would have to be true for this to be finished*, the one question worth asking of all three, and leave that kind's own questions until the answer names it. The kind question itself rides in a round that is happening regardless; what it can cost on top is one short round at step 5, once the answer says which questions were the right ones to ask.

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
2. **The `body` you write** carries real scope: what this touches, and which knowledge units constrain it. Write **links** to them; **do not copy their content into the body** — a copy is a second version, and it will drift.

Finding nothing must also **be written into the `body`**: "searched knowledge and code, found no constraints" is not the same as silence — silence leaves the next reader unable to tell *looked and found nothing* from *never looked*. The body is where it has to go, not the chat: no draft is shown for review before this task is created, and chat scrolls away while the task does not.

## 5. Ask what is missing — DO NOT SKIP THIS STEP

This is the step most often skipped, and the one that separates a task worth having from a task somebody has to rewrite.

Hold the user's sentence against what the guide asks for, **and against what step 4 turned up**. Where the user has not said, **ask** — do not infer it and write it in. Where knowledge already answered, **do not ask** — say you know it, and only raise it if it contradicts what the user said.

**Open the round by naming the kind you settled on at step 3, in a form they can push back on** — *"I am treating this as a bug; say so if it is not"*. Put it in the text of the round itself, not in prose beside it that they may never read. Translate the sentence like everything else you put in front of them; it is reference wording, not a string to paste. Then ask that kind's questions:

- **Bug** — what happens, what should happen instead, where it shows
- **Change** — what is different once it is done, and how anyone knows it is done
- **Spike** — what question needs answering, and what counts as enough to stop
- **A kind the user named themselves** — work out the equivalent questions for it. Still ask, and still do not force it back into the three above.

Step 3 could not tell ⇒ the kind becomes **one of the questions in this round** rather than a statement to push back on. Ask it beside *what would have to be true for this to be finished* — which maps onto one question in each of the three sets above — and leave the rest of that kind's questions until the answer names it. **Once it does, ask them.** That is a second round and it is the right one: this branch exists for sentences too thin to guess from, and a draft built on a single answer is the thin task step 5 is here to prevent.

**They push back and name a different kind** ⇒ size what is missing against the **new** kind's questions, not against how much they already typed. How much survives depends entirely on the direction: a bug read as a change keeps most of it, a bug read as a spike keeps almost none of it — *what happens* answers nothing that *what question needs answering* is asking. Put the genuine gap to them, say that is what you are doing, and accept that this is a second round. It is the bill a wrong guess pays, and it is why step 3 guesses only where there is something to guess from.

**They hand the decision back** — *"up to you"*, *"whatever works"* — ⇒ **that is not an answer.** It is the easiest thing in this command to read as a green light, and the point where a task quietly becomes something the user never asked for. Put a specific proposal in front of them and ask them to confirm *that proposal*. Yes, it is a second round; it is the round that stops a decision they never made being written into indexed text nobody reviews.

Batch them into one `AskUserQuestion` where you can, but **asking beats guessing**.

No `AskUserQuestion` in this session ⇒ **ask in text**. Only the widget is missing, and one round in text is still one round: the kind rides inside it exactly as it would in the widget — stated, or asked when step 3 could not tell. Having no tool to ask with is **not** a reason to stop asking.

`priority`: if the user has not said, **do not ask and do not set it**. The guide already says what leaving it empty means — read it there. Do not lay out a menu of levels for the sake of it.
