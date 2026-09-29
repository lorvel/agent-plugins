# Prints where a customisation of one command can act, for `lorvel-customize show`: its steps and
# gates in the order they run, with the sections each takes; its rules; what the modes mean; where
# a section runs; its settings; and its two files. Load lorvel-ids.awk first; set `skill` to the
# command. The environment names the command's SKILL.md (LORVEL_SKILLMD) and the plugin's ids.md
# (LORVEL_IDSMD).
#
# None of it is a second copy of a rule. The IDs, kinds, modes and labels are read from SKILL.md;
# what a section may do at each ID is asked of ids_refusal(), the function the loader checks every
# section with; what the modes mean is quoted from ids.md; and where a section runs is ids_where(),
# which the loader prints too.

# The sections the ID declared at i takes, in the personal file when ly is 1: "before:, after:".
function takes(i, ly,    k, s) {
  s = ""
  for (k = 1; k <= 4; k++)
    if (ids_refusal(skill, i, op_name[k], ly, 0) == "") s = s (s == "" ? "" : ", ") op_name[k] ":"
  return s == "" ? "no section" : s
}

BEGIN {
  split("before after replace skip", op_name, " ")
  if (!load_ids(ENVIRON["LORVEL_SKILLMD"])) exit 2

  print "Steps and gates of " skill ", in the order they run, and the sections each takes:"
  for (i = 1; i <= ids_n; i++) {
    if (ids_kind[i] == "rule") continue
    if (ids_kind[i] == "gate") line = "- " ids_id[i] " (gate " ids_label[i] ", " ids_mode[i] ": " ids_what[i] "): "
    else line = "- " ids_id[i] " (" ids_mode[i] ": " ids_what[i] "): "
    line = line takes(i, 0)
    if (takes(i, 1) != takes(i, 0)) line = line "; in the personal file, " takes(i, 1)
    # A step or gate takes before: and after: unless something says otherwise; say what.
    for (k = 1; k <= 2; k++) {
      why = ids_refusal(skill, i, op_name[k], 0, 0)
      if (why != "") line = line "; no " op_name[k] ": — " why
    }
    print line
  }

  print "Rules of " skill " — each holds for the whole run, so no section anchors to one, and none can make one do less:"
  for (i = 1; i <= ids_n; i++)
    if (ids_kind[i] == "rule") print "- " ids_id[i] " (" ids_mode[i] "): " ids_what[i]

  print "What the modes mean, from the plugin's ids.md:"
  path = ENVIRON["LORVEL_IDSMD"]
  n = 0
  counts = 0
  while ((rc = (getline l < path)) > 0) {
    if (l ~ /^## /) { in_modes = (l == "## Modes"); continue }
    if (!in_modes) continue
    # Every mode the section defines, whatever its name, and the paragraph on what text counts as.
    if (l ~ /^- `[a-z]+` /) { print l; n++ }
    else if (l ~ /^Text counts as what it does/) { print l; counts++ }
  }
  close(path)
  # No mode, or not that paragraph exactly once: ids.md has changed under this program.
  if (rc < 0 || !n || counts != 1) exit 2

  print "Where a section runs: " ids_where()

  if (skill == "task-work") {
    print "Settings of task-work, in the frontmatter of either file; the personal file's win over the shared file's:"
    print "- review: <skill> <arguments> — the skill phase 4 calls to review the change, with those arguments, instead of the command choosing the review tooling"
    print "- defaults.plan: true — STOP-2 on without typing --plan"
    print "A file only tightens: defaults.plan: false and defaults.auto are refused. Only the person typing the command turns STOP-2 off for one run, with --no-plan, or skips STOP-3, with --auto."
  } else {
    print "Settings: " skill " has none in this version, so its files hold sections only."
  }
  print "Files: .lorvel/" skill ".md is shared — committed, the whole team gets it. .lorvel/" skill ".local.md is personal — kept out of git; where both files have a section at the same place, the shared one runs first."
}
