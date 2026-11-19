# Slicing method

How to cut work into slices, and how to write the map of them. The planning method, `plan-method.md`, beside this file, sends here every plan that maps slices, so every command of this plugin that cuts work cuts it the same way.

**The project's own conventions come first.** Before cutting, `search_knowledge` for what the project has settled about splitting work: how it cuts, how slices are named, and any slice every batch of work ends with — such a slice goes where the convention puts it, and does not count as an outcome when deciding whether to split. What the search finds wins over the rules below; where it finds nothing, these rules are the whole measure.

## When to split

**A split needs two or more outcomes, each of which can be checked and shipped without the others.** The user chose to split work that holds one outcome, however many places it touches, or the cut comes out as one slice ⇒ say the work is better kept as one, and ask again before writing anything.

**The work is already split into subtasks** ⇒ they are the slices as they stand. Map them — a waits-on line for each, an owner for every line of the definition of done — and change none of them. A cut this file would not have made is said in the map, not undone.

## How to cut

- **One slice, one outcome**, with a definition of done of its own. A slice runs through every layer its outcome needs. A boundary between layers or repositories is a cut only where it is also a boundary of what ships.
- **A slice that cannot be checked on its own is not a slice**: fold it into the slice whose outcome it serves. The slice that owns a line met only once every slice is in is the exception: it is never folded.
- **Work done first in a temporary form and wired up later is two slices.**
- **A slice fits one run of `/lorvel:task-work`.** Many slices ⇒ look again for slices that belong together. How many is too many is the project's to say, not this file's.

## Order, and what waits on what

- **The slices are ordered as they depend on one another.** A slice that checks a premise nobody has checked yet comes before every slice that rests on it.
- **Each slice has one line saying what it waits on**: the slice or slices it cannot start before, or `none`. Write `none` rather than leaving the line out: without it, a slice that waits on nothing looks the same as one whose line was forgotten, and nobody can tell which slices could be worked side by side.
- **No slice comes before a slice it waits on, and nothing waits in a circle.** Lorvel keeps the order of a task's subtasks and no other link between them; the waits-on lines are what that order must agree with.

## The parent's definition of done

- **Every line of the parent's definition of done has exactly one owner**: the slice that proves it, or the parent. A line that makes two claims counts as two lines here, each with its own owner.
- **The parent keeps only a line that holds by itself once every slice is closed** — one the slices' own evidence already shows, such as a limit every slice keeps, and that needs no new work, measurement or decision by then. The map says which lines the parent keeps. Once the last slice is closed, nothing should be left on the parent but closing it: work left on the parent is work nobody does.
- **A line of the definition of done that can only be met once every slice is in** — an end-to-end check, a measurement across the slices — **is owned by a slice of its own**, which waits on every other slice, save one the project's conventions place after it: where they end every batch with a particular slice, this one comes right before that slice and is not folded into it. It does not count as an outcome when deciding whether to split. No such line in the definition of done ⇒ no such slice.
- **Work that joins the slices up is a slice**, not a line the parent keeps.
- **Work the parent's body asks for that no line of its definition of done covers** — a question still open, a change the body asks for in a place no line names (a document, a message to the people affected), a step the body names in passing — is named in the map, piece by piece, with the slice that takes it, or as taken by no slice and why. A slice that takes such a piece says so in what it delivers. An open question may stay where the guide puts what is undecided, as long as the map says which slice settles it, or that none does. Context that only explains why the work exists is not such a piece. The map adds no line to the parent's definition of done: that is the user's to do.
- **Work already split into subtasks**, with a line the parent would keep although it needs work ⇒ the map names that line, with a slice proposed to take it.
- **A slice states the lines it proves, and no others.** A rule that binds several slices is written once, on the parent or in the knowledge base, and each slice points to it instead of carrying a copy.

## What each slice says

In the map, and in the task a slice becomes:

- its name, saying what it is;
- what it delivers;
- what it waits on;
- which lines of the parent's definition of done it proves;
- how it is checked on its own;
- what it does not cover, where that could be mistaken.

**A slice's name carries no ordering prefix** — `A —`, `1.`, `Slice 2 —` — unless the project's conventions ask for one. The order is already kept; a prefix only repeats it, and goes wrong the first time a slice is moved or one is inserted.

How a slice is worked — its own steps — is written by that slice's own run, not in the map.

## Check the map once

This pass comes after the planning method's check of the draft, and on the definition of done it is the one that rules: a line the parent keeps counts as owned, as long as it holds by itself once every slice is closed. One pass over the map, fixing in place:

- Every slice says the first five things above, and the last where it applies; its waits-on line is there even when it is `none`.
- Every line of the parent's definition of done has one owner, and only one.
- The parent keeps no line that needs work once the slices are in; a line that can only be met once every slice is in is owned by a slice of its own, after every other slice and before one the project's conventions end the batch with.
- Every piece of work the parent's body asks for that no line of its definition of done covers is named, with the slice that takes it or as taken by none.
- No slice comes before a slice it waits on.
- No slice name carries an ordering prefix the project did not ask for.
