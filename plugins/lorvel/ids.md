# Step IDs

`task-create` and `task-work` each declare their steps, gates and locked rules in the frontmatter of their `SKILL.md`, under `metadata.lorvel.ids`: steps and gates in the order they run, then the rules. That list is the contract a customisation of a command anchors to, and this file is the one place its fields and modes are defined.

The loader, `scripts/lorvel-load`, reads it: it checks each section of a customisation against the mode of the ID the section names, prints a step's label next to its sections, and hands the model the locked IDs along with them. The list itself costs a run nothing — Claude Code keeps `metadata` on the loaded skill but shows the model none of it, not when a command runs and not in the list of skills it can call (checked on Claude Code 2.1.283). Only what the loader prints from it for a customisation reaches the model.

The loader reads the list in the two shapes the skills write it in — a one-line flow map for a step or a gate, a block map for a rule — and `tests/ids.test.rb` checks that it reads what a YAML parser reads.

An ID stays the same when steps are renumbered. The numbered steps inside a `task-work` phase have no ID of their own.

## Fields

| Field | Meaning |
|---|---|
| `id` | What a customisation anchors to. |
| `kind` | `step` or `gate`: a place in the flow. `rule`: holds for the whole run and is not a place. |
| `in` | Gates only: the step or steps the gate sits inside. |
| `what` | A label, not the rule. A step's starts with its place in the step map, `Phase 3 —` or `Step 7 —`, and the loader prints that part next to a section anchored at the step, or at a gate inside it. |
| `source` | Rules only: phrases quoted verbatim from the skill or its reference files. The paragraphs that hold them are the rule, and the loader quotes them to the model to name it. |
| `mode` | What a customisation may do at that ID. |

What binds is always the skill's own text: for a step, its section; for a gate, its row in the stop-gate table and every sentence that names it; for a rule, its `source` paragraphs.

`schema` changes only when a change would break an older reader. A reader finds fields by name and ignores any it does not know.

## Modes

A customisation is a file under `.lorvel/`; each section of its body names one ID. At a `step` or a `gate` it may add steps before or after, whatever the mode. A gate marks its place even when it is switched off, and one that sits in more than one step — its `in` names each — takes them in each. A `rule` is no place in the flow: nothing is added before or after one.

- `locked` — a customisation cannot skip it, replace it or make it do less, wherever its text is anchored. Adding a step beside it is allowed; what that step says still counts.
- `extend` — a customisation cannot skip or replace it; its added text may change how it is done, as long as no locked ID does less.
- `replace` — as `extend`, and a customisation may also replace it.
- `optional` — as `replace`, and a customisation may also skip it.

Text counts as what it does, wherever it is anchored: text that stops an ID from running skips it, text that runs something else in its place replaces it, and text that makes it do less weakens it.

A reader can check each section's operation against the mode of the ID it names. Whether a text skips, replaces or weakens something is a judgement only the model can make, and the model never sees this file or the declarations — so whatever applies a customisation hands the model these rules along with it.

## Changing the declarations

- A new step, gate or locked rule gets its ID in the commit that adds it; a new rule also gets its `source`.
- A `source` phrase that no longer appears in the skill is a broken declaration: update it in the commit that moves the text.
- An ID is public: customisations anchor to it, and renaming one breaks every file that does. Add IDs; do not rename them.
- A skill edit never relaxes a `locked` ID, and no ID becomes `optional` until the maintainers name it.
