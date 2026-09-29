# Reads one .lorvel/ file that has already passed lorvel-scan.awk. Set `skill` to the command,
# `shown` to the file name to print and `limit` to the most bytes allowed. Prints, one per line:
#   REVIEW <value>   the review tool this file sets (task-work only)
#   PLAN             this file turns STOP-2 on by default (task-work only)
#   LINE <text>      a line to show as it is
# A file refused as a whole prints one LINE and nothing else. No text from the file is printed
# except a review value and key names that passed their checks.
#
# The frontmatter is read as a deliberately small part of YAML: `key: value` lines, comments, and
# one block of keys indented alike under `defaults:`. Anything else refuses the file rather than
# being guessed at.

function hit(s, re, n,    t) {
  t = s
  while (match(t, re)) {
    if (RLENGTH >= n) return 1
    t = substr(t, RSTART + 1)
  }
  return 0
}

# A known token or key prefix counts only at the start of a word: `sk-` also sits inside
# `task-create-anything`. The line gets a leading space, so every prefix has exactly one character
# before it, and the lengths below include that character.
function tokenish(s,    b, l, m) {
  s = " " s
  b = "[^A-Za-z0-9_-]"
  if (s ~ /-----BEGIN [A-Z ]*PRIVATE K[E]Y-----/) return 1    # [E]: so this line is no key header itself
  if (hit(s, b "lv_[A-Za-z0-9_-]+", 20)) return 1
  if (hit(s, b "lvo_[a-z]+_[A-Za-z0-9_-]+", 21)) return 1
  if (hit(s, b "gh[pousr]_[A-Za-z0-9]+", 25)) return 1
  if (hit(s, b "github_pat_[A-Za-z0-9_]+", 31)) return 1
  if (hit(s, b "glpat-[A-Za-z0-9_-]+", 21)) return 1
  if (hit(s, b "xox[abprs]-[A-Za-z0-9-]+", 16)) return 1
  if (hit(s, b "sk-[A-Za-z0-9_-]+", 25)) return 1
  if (hit(s, b "AKIA[A-Z0-9]+", 21)) return 1
  if (hit(s, b "AIza[A-Za-z0-9_-]+", 36)) return 1
  if (hit(s, b "npm_[A-Za-z0-9]+", 37)) return 1
  if (hit(s, b "eyJ[A-Za-z0-9_-]+[.]eyJ[A-Za-z0-9_-]+[.]", 31)) return 1
  if (hit(s, b "[Bb]earer[ \t]+[A-Za-z0-9._~+/=-]+", 28)) return 1
  l = tolower(s)
  while (match(l, "(api[_-]?key|secret|token|passwd|password|access[_-]?key|private[_-]?key)[\"']?[ \t]*[:=][ \t]*[\"']?[a-z0-9._~+/=-]+")) {
    m = substr(l, RSTART, RLENGTH)
    l = substr(l, RSTART + 1)
    sub(/^[^:=]*[:=][ \t]*["']?/, "", m)
    if (length(m) >= 16) return 1
  }
  return 0
}

# Twenty or more letters and digits in a row, with both kinds in the run, read as a key or a token
# whatever their prefix. A review value or key name holding such a run is never printed.
function randomish(s,    t, r) {
  t = s
  while (match(t, "[A-Za-z0-9]+")) {
    r = substr(t, RSTART, RLENGTH)
    if (RLENGTH >= 20 && r ~ /[A-Za-z]/ && r ~ /[0-9]/) return 1
    t = substr(t, RSTART + RLENGTH)
  }
  return 0
}

# A value as YAML would read it, for the forms accepted here; sets `bad` for any other form.
function scalar(v,    q, rest, p, inner) {
  bad = 0
  sub(/^[ \t]+/, "", v)
  sub(/[ \t]+$/, "", v)
  if (v == "" || v ~ /^#/) return ""
  q = substr(v, 1, 1)
  if (q == "\"" || q == "'") {
    rest = substr(v, 2)
    p = index(rest, q)
    if (!p) { bad = 1; return "" }
    inner = substr(rest, 1, p - 1)
    if (substr(rest, p + 1) !~ /^([ \t]+#.*)?$/) { bad = 1; return "" }
    if (q == "\"" && index(inner, "\\")) { bad = 1; return "" }
    return inner
  }
  sub(/[ \t]+#.*$/, "", v)
  if (v !~ /^[A-Za-z0-9]/ || index(v, ": ") || v ~ /:$/) { bad = 1; return "" }
  return v
}

# Unknown key names are echoed only when they look like a setting's name; any other key is named by
# its line, so a key cannot carry a token or a sentence into the output.
function unknown(k) {
  n_unknown++
  if (n_unknown > 3) return
  if (k ~ /^[a-z][a-z0-9_-]*([.][a-z][a-z0-9_-]*)?$/ && length(k) <= 32 && !randomish(k) && !tokenish(k)) unknown_item[n_unknown] = "`" k "`"
  else unknown_item[n_unknown] = "on line " NR
}

function notfor(k) {
  n_notfor++
  notfor_names = notfor_names (n_notfor > 1 ? ", " : "") k
}

function top(key, val) {
  if (key == "review") {
    if (skill != "task-work") { notfor("review"); return }
    review_seen = 1
    review_val = val
    return
  }
  if (key == "defaults") { fm_err = NR; return }
  unknown(key)
}

function child(parent, key, val) {
  if (parent != "defaults") return
  if (skill != "task-work") { notfor("defaults." key); return }
  if (key == "plan") {
    if (val ~ /^(true|True|TRUE)$/) plan_on = 1
    else if (val ~ /^(false|False|FALSE|no|No|NO|off|Off|OFF)$/) plan_off = 1
    else plan_bad = 1
    return
  }
  if (key == "auto") { auto_seen = 1; return }
  unknown("defaults." key)
}

function front(line,    key, val, ind) {
  if (line ~ /^[ \t]*$/ || line ~ /^[ \t]*#/) return
  if (line ~ /^[A-Za-z0-9_-]+:([ \t]|$)/) {
    key = line
    sub(/:.*/, "", key)
    val = line
    sub(/^[^:]*:/, "", val)
    val = scalar(val)
    if (bad || (key in seen)) { fm_err = NR; return }
    seen[key] = 1
    parent = ""
    if (key == "skill" || key == "schema") {
      if (val == "") fm_err = NR
      return
    }
    if (val == "" && key != "review") {
      parent = key
      indent = 0
      if (key != "defaults") unknown(key)
      return
    }
    top(key, val)
    return
  }
  if (line ~ /^ +[A-Za-z0-9_-]+:([ \t]|$)/) {
    if (parent == "") { fm_err = NR; return }
    match(line, /^ +/)
    ind = RLENGTH
    if (!indent) indent = ind
    if (ind != indent) { fm_err = NR; return }
    key = line
    sub(/^ +/, "", key)
    sub(/:.*/, "", key)
    val = line
    sub(/^ +[^:]*:/, "", val)
    val = scalar(val)
    if (bad || val == "" || ((parent "." key) in seen)) { fm_err = NR; return }
    seen[parent "." key] = 1
    child(parent, key, val)
    return
  }
  fm_err = NR
}

# Why a review value is refused, or "" when it is a skill name followed by plain arguments: single
# spaces, at most 200 characters, and nothing that names this plugin's commands, starts another
# command or carries a key.
function review_problem(v,    n, i, w, lw) {
  if (length(v) > 200 || v !~ "^[A-Za-z0-9][A-Za-z0-9._:-]*( [A-Za-z0-9._:/@=+,-]+)*$")
    return "it must be a skill name, then plain arguments, at most 200 characters"
  n = split(v, w, " ")
  for (i = 1; i <= n; i++) {
    lw = tolower(w[i])
    if (index(lw, "lorvel:") || lw ~ /(^|[^a-z0-9])task-(work|create|customi[sz]e)([^a-z0-9]|$)/)
      return "it names a command of this plugin"
    if (index(w[i], "/") == 1 || w[i] ~ /^--auto/)
      return "it would start another command"
  }
  if (randomish(v)) return "it looks like it carries a token or key"
  return ""
}

function refuse(why) {
  print "LINE - Not applied: all of " shown " — " why
  refused = 1
}

BEGIN { state = "start" }

{
  total += length($0) + 1
  if (total > limit + 1) { refuse("it is larger than 64 KiB"); exit }
  line = $0
  sub(/\r$/, "", line)
  if (NR == 1) sub(/^\357\273\277/, "", line)
  if (!tok_line && tokenish(line)) tok_line = NR
  if (state == "start") {
    if (line ~ /^---[ \t]*$/) { state = "front"; had_front = 1; next }
    state = "body"
  }
  if (state == "front") {
    if (line ~ /^---[ \t]*$/) { state = "body"; next }
    if (line ~ /^schema:/) { schema_line = line; sub(/^schema:[ \t]*/, "", schema_line); sub(/[ \t]+#.*$/, "", schema_line); gsub(/["' \t]/, "", schema_line); if (schema_line != "" && schema_line != "1") wrong_schema = 1 }
    if (line ~ /^skill:/) { skill_line = line; sub(/^skill:[ \t]*/, "", skill_line); sub(/[ \t]+#.*$/, "", skill_line); gsub(/["' \t]/, "", skill_line); if (skill_line != "" && skill_line != skill && skill_line != "lorvel:" skill) wrong_skill = 1 }
    if (!fm_err) front(line)
    next
  }
  if (line ~ /^[ \t]*(```|~~~)/) fence = !fence
  if (line !~ /^[ \t]*$/) body_lines++
  if (!had_front && line ~ /^(---|[A-Za-z0-9_-]+:([ \t]|$))/) keyish = 1
  if (!fence && line ~ /^##[ \t]/) sections++
}

END {
  if (refused) exit
  if (tok_line) refuse("line " tok_line " looks like a token or key")
  else if (wrong_schema) refuse("it is written for another schema; this version reads schema 1")
  else if (wrong_skill) refuse("its skill: line names another command")
  else if (state == "front") refuse("its frontmatter has no closing --- line")
  else if (fm_err) refuse("its frontmatter is not understood (line " fm_err ")")
  if (refused) exit

  if (review_seen) {
    why = review_problem(review_val)
    if (why == "") print "REVIEW " review_val
    else print "LINE - Not applied: review in " shown " — " why
    said = 1
  }
  if (plan_on) { print "PLAN"; said = 1 }
  if (plan_off) {
    print "LINE - Not applied: defaults.plan in " shown " — a file can only turn STOP-2 on; typing --no-plan turns it off for one run"
    said = 1
  }
  if (plan_bad) {
    print "LINE - Not applied: defaults.plan in " shown " — the only value it takes is true"
    said = 1
  }
  if (auto_seen) {
    print "LINE - Not applied: defaults.auto in " shown " — only the person typing the command can pass --auto"
    said = 1
  }
  if (n_notfor) {
    print "LINE - Not applied: " notfor_names " in " shown " — not a setting of " skill " in this version"
    said = 1
  }
  if (n_unknown) {
    names = ""
    for (i = 1; i <= n_unknown && i <= 3; i++)
      names = names (i > 1 ? ", " : "") (n_unknown > 1 && unknown_item[i] ~ /^on / ? "one " : "") unknown_item[i]
    print "LINE - Not applied: unknown key" (n_unknown > 1 ? "s " : " ") names (n_unknown > 3 ? " and " (n_unknown - 3) " more" : "") " in " shown
    said = 1
  }
  if (!had_front && keyish) {
    print "LINE - Not applied: " shown " — it has no frontmatter; settings go between two --- lines at the very top"
    said = 1
  } else if (body_lines) {
    print "LINE - Not applied: the body of " shown (sections ? " (" sections " section" (sections > 1 ? "s" : "") ")" : "") " — this version applies only the frontmatter"
    said = 1
  }
  if (!said) print "LINE - Nothing in " shown " applies in this version"
}
