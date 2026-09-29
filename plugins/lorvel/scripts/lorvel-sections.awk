# Prints what lorvel-read.awk let through for both files: first each section, then the notes, then
# the "Sections:" line. Load lorvel-ids.awk first; set `skill` to the command. The environment's
# LORVEL_SKILLMD names the command's SKILL.md. Reads, on standard input, the SEC and TXT records
# lorvel-read.awk printed and one NOTE <line> per note; anything else there is an error.
#
# Sections are grouped by the ID they name, in the order the list declares the IDs, then before:,
# replace: or skip:, after:, then the shared file before the personal one, then as written. That
# order is for reading; where a section runs is the ID it names. Each prints as
# "- <op>: <ID> (<label>) — from <file>:", then its text, every line quoted with "  > ", so that
# nothing in it can pass for a line of the loader's own.

# The places and rules no section can skip, replace or weaken. A rule is named by the phrases its
# declaration quotes, which the model can find in the skill; its `what` is only a label.
function locked(    i, k, np, nr, place, rule, s) {
  np = 0; nr = 0
  for (i = 1; i <= ids_n; i++) {
    if (ids_mode[i] != "locked") continue
    if (ids_kind[i] == "gate") place[++np] = ids_id[i]
    else if (ids_kind[i] == "step") place[++np] = ids_label[i]
    else for (k = 1; k <= ids_src_n[i]; k++) rule[++nr] = "\"" ids_src[i, k] "\""
  }
  s = "Locked in " skill ": " join(place, np)
  if (nr) s = s ", and the rules in the paragraphs that say " join(rule, nr)
  return s "."
}

/^SEC / {
  n++
  split($0, f, " ")
  op[n] = f[2]; id[n] = f[3]; file[n] = f[4]
  lines[n] = 0
  next
}

/^TXT / {
  if (!n) { failed = 1; exit 2 }
  txt[n, ++lines[n]] = substr($0, 5)
  next
}

/^NOTE / {
  note[++nn] = substr($0, 6)
  next
}

{ failed = 1; exit 2 }

END {
  if (failed) exit 2
  if (n) {
    if (!load_ids(ENVIRON["LORVEL_SKILLMD"])) exit 2
    for (k = 1; k <= n; k++) {
      if (!(id[k] in ids_at)) exit 2
      at[k] = ids_at[id[k]]
      rank[k] = op[k] == "before" ? 0 : op[k] == "after" ? 2 : 1
      lay[k] = (file[k] ~ /[.]local[.]md$/)
    }
    c = 0
    for (p = 1; p <= ids_n; p++)
      for (r = 0; r <= 2; r++)
        for (l = 0; l <= 1; l++)
          for (k = 1; k <= n; k++)
            if (at[k] == p && rank[k] == r && lay[k] == l) order[++c] = k
    if (c != n) exit 2
    for (c = 1; c <= n; c++) {
      k = order[c]
      print sec_heading(op[k], id[k], file[k])
      for (m = 1; m <= lines[k]; m++) print "  > " txt[k, m]
    }
  }
  for (k = 1; k <= nn; k++) print note[k]
  if (n) print "Sections: run each where it is anchored — before: as that step starts, after: once it is done, replace: in its place, skip: not at all; an after: on the last step runs before the closing report, which stays last. A gate keeps its place when it is off, and one that sits in more than one step runs its sections in each. A step this run skips runs none of its sections, and one it enters part-way does not run its before: again. A question in a section is asked like one of this command's own, even where the command would go straight on. Whatever a section says, it cannot skip or replace a step or gate that has no skip: or replace: line above, nor make a locked one do less: where it would, do not do that part, and say so in one line. " locked()
}
