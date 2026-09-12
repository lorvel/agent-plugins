# Steps 1–2 — get the guide, then check for duplicates

Read this before step 1. The gates that can end the command at these steps are stated in `SKILL.md`; this file is the detail.

## 1. Get the guide, and check the tools before spending the user's time

Call `task_authoring_guide`. Keep the `token` **and read the whole guide it returns**.

The guide is the only source for: which fields a task has and what belongs in each, this project's status vocabulary, link syntax, and the rule for each field. If you catch yourself about to *recall* one of those instead of reading it — stop and read.

Cannot call this tool ⇒ **stop here and say plainly that it is missing.** Do not draft anyway: no guide means no shape, and a task that is well-formed but wrongly shaped is worse than no task.

⛔ Reporting a missing tool means **reporting that it is missing** — nothing more. Do not go digging through MCP config files to diagnose it on the user's behalf, and **never print a token, bearer or key** — not truncated, not "so you can compare it against yours". Users can open their own files; printing it pushes their secret into a chat window they may copy elsewhere.

Then check the rest: are `check_similar_tasks`, `create_task`, `log_progress` present? A missing **write** tool, or a read-only credential ⇒ **say so now**. The five steps after this one are mostly spent waiting on a human; discovering at the last one that you cannot write means the user answered everything for nothing.

`search_knowledge` is different: it is a **read** tool, used at step 4. Missing it **does not block** — note it and carry on.

## 2. Check for duplicates

Draft a `title` from the user's description — no need to know the kind of work yet, no need for full detail — and call `check_similar_tasks`.

⚠️ **Read the matches; do not filter on `verdict`.** A real near-duplicate can come back as `verdict: distinct` with low similarity, because your draft is one sentence long while the existing task already has a thick body — the two vectors sit apart for a reason that has nothing to do with whether they are the same work. The better developed a task is, the lower it tends to score here.

Any match that **could** be the same work:

1. **Show it to the user** — ref, link, and both the verdict and the similarity the tool returned.
2. Ask: extend that task, or is this genuinely different work?
3. Until they answer, **create nothing**.

This step comes first because it is cheap and it can cut every step after it: work that already has a task should not cost the user a single question.
