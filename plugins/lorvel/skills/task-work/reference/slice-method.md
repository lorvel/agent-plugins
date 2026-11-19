# Slicing method

How to cut work into slices, and how to write the map of them. The planning method, `plan-method.md`, beside this file, sends here every plan that maps slices, so every command of this plugin that cuts work cuts it the same way.

**The project's own conventions come first.** Before cutting, `search_knowledge` for what the project has settled about splitting work: how it cuts, how slices are named, and any slice every batch of work ends with — such a slice goes where the convention puts it, and does not count as an outcome when deciding whether to split. What the search finds wins over the rules below; where it finds nothing, these rules are the whole measure.

## When to split

**A split needs two or more outcomes, each of which can be checked and shipped without the others.** The user chose to split work that holds one outcome, however many places it touches, or the cut comes out as one slice ⇒ say the work is better kept as one, and ask again before writing anything.

**The work is already split into subtasks** ⇒ they are the slices as they stand. Map them — a waits-on line for each, an owner for every line of the definition of done — and change none of them. A cut this file would not have made is said in the map, not undone.

## How to cut

- **One slice, one outcome**, with a definition of done of its own. A slice runs through every layer its outcome needs. A boundary between layers or repositories is a cut only where it is also a boundary of what ships.
- **A slice that cannot be checked on its own is not a slice**: fold it into the slice whose outcome it serves.
- **Work done first in a temporary form and wired up later is two slices.**
- **A slice fits one run of `/lorvel:task-work`.** Many slices ⇒ look again for slices that belong together. How many is too many is the project's to say, not this file's.

## Order, and what waits on what

- **The slices are ordered as they depend on one another.** A slice that checks a premise nobody has checked yet comes before every slice that rests on it.
- **Each slice has one line saying what it waits on**: the slice or slices it cannot start before, or `none`. Write `none` rather than leaving the line out: without it, a slice that waits on nothing looks the same as one whose line was forgotten, and nobody can tell which slices could be worked side by side.
- **No slice comes before a slice it waits on, and nothing waits in a circle.** Lorvel keeps the order of a task's subtasks and no other link between them; the waits-on lines are what that order must agree with.

## The parent's definition of done

- **Every line of the parent's definition of done has exactly one owner**: the slice that proves it, or the parent, for a line no single slice can prove — such as a check made once every slice is in. The map says which lines the parent keeps. Work that joins the slices up is not such a line: it is a slice. A line that makes two claims counts as two lines here, each with its own owner.
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

This pass comes after the planning method's check of the draft, and on the definition of done it is the one that rules: a line the parent keeps counts as owned. One pass over the map, fixing in place:

- Every slice says the first five things above, and the last where it applies; its waits-on line is there even when it is `none`.
- Every line of the parent's definition of done has one owner, and only one.
- No slice comes before a slice it waits on.
- No slice name carries an ordering prefix the project did not ask for.
