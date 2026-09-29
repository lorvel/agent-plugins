# Step IDs

`task-create` and `task-work` each declare their steps, gates and locked rules in the frontmatter of their `SKILL.md`, under `metadata.lorvel.ids`: steps and gates in the order they run, then the rules. That list is the contract a customisation of a command anchors to, and this file is the one place its fields and modes are defined.

Nothing reads it yet. This version applies only a customisation's frontmatter — the review tool and the STOP-2 default, read by `scripts/lorvel-load` — and nothing anchored to an ID. The list costs a run nothing either — Claude Code keeps `metadata` on the loaded skill but shows the model none of it, not when a command runs and not in the list of skills it can call (checked on Claude Code 2.1.283).

An ID stays the same when steps are renumbered. The numbered steps inside a `task-work` phase have no ID of their own.

## Fields

| Field | Meaning |
|---|---|
| `id` | What a customisation anchors to. |
| `kind` | `step` or `gate`: a place in the flow. `rule`: holds for the whole run and is not a place. |
| `in` | Gates only: the step or steps the gate sits inside. |
| `what` | A label, not the rule. |
| `source` | Rules only: phrases quoted verbatim from the skill or its reference files. The paragraphs that hold them are the rule. |
| `mode` | What a customisation may do at that ID. |

What binds is always the skill's own text: for a step, its section; for a gate, its row in the stop-gate table and every sentence that names it; for a rule, its `source` paragraphs.

`schema` changes only when a change would break an older reader. A reader finds fields by name and ignores any it does not know.

## Modes

A customisation is a file under `.lorvel/`. At a `step` or a `gate` it may add steps before or after, whatever the mode; a gate marks its place even when it is switched off.

- `locked` — a customisation cannot skip it, replace it or make it do less, wherever its text is anchored. Adding a step beside it is allowed; what that step says still counts.
- `extend` — a customisation cannot skip or replace it; its added text may change how it is done, as long as no locked ID does less.
- `replace` — as `extend`, and a customisation may also replace it.
- `optional` — as `replace`, and a customisation may also skip it.

Text counts as what it does, wherever it is anchored: text that stops an ID from running skips it, text that runs something else in its place replaces it, and text that makes it do less weakens it.

A reader can check each section's operation against the mode of the ID it names. Whether a text skips, replaces or weakens something is a judgement only the model can make, and the model never sees this file or the declarations — so whatever applies a customisation hands the model these rules along with it.

## Changing the declarations

- A new step, gate or locked rule gets its ID in the commit that adds it; a new rule also gets its `source`.
- A `source` phrase that no longer appears in the skill is a broken declaration: update it in the commit that moves the text.
- Once customisations are read, an ID is public: renaming one breaks every file anchored to it. Add IDs; do not rename them.
- A skill edit never relaxes a `locked` ID, and no ID becomes `optional` until the maintainers name it.
