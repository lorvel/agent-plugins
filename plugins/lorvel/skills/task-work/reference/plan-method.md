# Planning method

How to get to a plan for a Lorvel task. Every command of this plugin that plans a task reads this file, so they all plan the same way.

**What a plan holds, and which parts of it are always there, is not in this file.** That is the "Writing a plan" section of `task_authoring_guide`. This file adds how to get to a plan like that, and a few finer rules for writing its steps. No plan can be written without that section: when a plan is to be written and the tool is not in this session, or its answer has no such section, stop now — before the reading below — and say so. A plan written without it is written from memory.

## Read before you write

All of it, in this order:

1. **The task**: its `title`, `body`, the `plan` it already has, and its log.
2. **Its parent, when the task is a subtask** — `get_task` on the parent, for its `body` and `plan`. What was decided there binds this task too, and it may say what this task waits on.
3. **The knowledge.** The units the task links, then `search_knowledge`, two or three queries on the *identifiers* in the task — endpoint, column, function, rule name — then `get_knowledge` on the plausible hits. **Do not guess a project convention.** This is the step that keeps the plugin portable: the procedure lives here, the project's truth lives in Lorvel and is read at runtime.
4. **What the project has settled about plans** — one more `search_knowledge`, for its conventions on writing a plan. What it finds applies on top of the guide and wins over the finer rules of this file; if it finds nothing, the guide and those rules are the whole measure.
5. **The code** the task is about. Read the repo's agent instructions file (`CLAUDE.md`, `AGENTS.md`) before the code — a rule stated there outranks your reading of the code.

## Ask before you write

- **Look up what can be looked up, and ask what cannot.** A decision is the user's to make; so is a fact that no file and no unit holds.
- **The guide says which questions cannot wait for the plan.** Ask those before writing — all of them together rather than one at a time, each with **the answer you would recommend**, so the user can settle it in a word. An answer that opens a new question ⇒ ask again.
- **Work that holds two or more outcomes that could ship on their own** raises one of those questions: split it, or keep it as one? Splitting the work is the user's call. Split ⇒ the steps of the plan are the slices, in the order they depend on one another, and planning creates no subtask. The finer rules for the steps then belong to each slice's own plan, not to that map.
- Any other open point can wait: it goes into the plan, where the guide puts what is undecided — unless the command you are running asks about it at a gate of its own. A command may ask more than this file requires; it never asks less.
- **Nobody who can answer will read the questions** ⇒ end with them, and write no plan.

## How much to write

The length of a plan follows the size of the work. Where step 4 of the reading found that the project has settled how long a plan may be, that binds.

## Finer rules for the steps

- **A test or a document sits in the step that owes it**, not in a step of its own at the end.
- **A premise nobody has checked ⇒ the first step checks it**, before anything is built on it.
- **An unknown that a step will settle is that step**, not an open point.
- **A file is named in the step that touches it, as a pointer** — its path, a function name — with no line number and no pasted code. A snippet is there only when it is itself the decision: an exact wording, a signature, a schema.
- **The last step before the task closes is a knowledge audit** — a sweep for what the work made wrong or left unsaid in the knowledge base, not the place for a document that some step owes.

## Check the draft once

Before the plan is shown to anyone or saved, one pass over the draft, fixing in place:

- Hold it against the guide's section, sentence by sentence, then against what the project has settled about plans and this file's finer rules for the steps — which a plan that maps slices is not held to.
- Read the body's definition of done once more. A line that no step would bring about means a step is missing: add the step.
- It is as long as the work calls for, and no longer.
