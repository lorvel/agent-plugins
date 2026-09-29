# Reads one .lorvel/ file that has already passed lorvel-scan.awk. Load lorvel-token.awk and
# lorvel-ids.awk first. Set `skill` to the command, `shown` to the file name to print, `limit` to
# the most bytes allowed and `seccap` to the most bytes the sections it applies may take once
# printed; the environment's LORVEL_SKILLMD names the command's SKILL.md, whose step IDs the
# sections are checked against. Prints, one per line:
#   REVIEW <value>   the review tool this file sets (task-work only)
#   PLAN             this file turns STOP-2 on by default (task-work only)
#   LINE <text>      a line to show as it is
#   SEC <op> <ID> <file>, then one TXT <text> per line of it: a section that passed every check
# A file refused as a whole prints one LINE and nothing else. No text from the file is printed
# except a review value, key names and IDs that passed their checks, and sections that did.
#
# The frontmatter is read as a deliberately small part of YAML: `key: value` lines, comments, and
# one block of keys indented alike under `defaults:`. Anything else refuses the file rather than
# being guessed at. The body is read the way CommonMark finds headings and code fences, as
# sections under `## <op>: <ID>` headings; see ids.md for what each op may do at each mode.

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

# A name from the file is echoed only when it has the shape `re` describes, is short, and looks like
# no key; anything else is named by its line, so a file cannot carry a token or a sentence into the
# output through a name.
function echoable(s, re) {
  return s ~ re && length(s) <= 32 && !randomish(s) && !tokenish(s)
}

function unknown(k) {
  n_unknown++
  if (n_unknown > 3) return
  if (echoable(k, "^[a-z][a-z0-9_-]*([.][a-z][a-z0-9_-]*)?$")) unknown_item[n_unknown] = "`" k "`"
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
  if (skill != "task-work") { notfor(echoable(key, "^[a-z][a-z0-9_-]*$") ? "defaults." key : "a key on line " NR); return }
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

# --- the body ------------------------------------------------------------------------------------
# Headings and code fences are found the way CommonMark finds them, so the sections the loader
# applies are the ones a reviewer sees in the rendered file: a line starts a block only when it is
# indented by three spaces or fewer, and a fence ends only on a line of the same character, at
# least as long, with nothing after it.

# The line with up to three leading spaces set aside; `lead` is how many spaces it had.
function block_start(l) {
  match(l, /^ */)
  lead = RLENGTH
  return substr(l, lead + 1)
}

# The run of ` or ~ that opens a code fence at the start of `rest`, or "" when it opens none.
function fence_opener(rest,    c) {
  c = substr(rest, 1, 1)
  if (c != "`" && c != "~") return ""
  match(rest, c == "`" ? "^`+" : "^~+")
  if (RLENGTH < 3) return ""
  if (c == "`" && index(substr(rest, RLENGTH + 1), "`")) return ""
  return substr(rest, 1, RLENGTH)
}

# A line of the fence's own character, at least as long, closes it; nothing may follow.
function fence_closes(rest) {
  match(rest, fence_ch == "`" ? "^`+" : "^~+")
  return RLENGTH >= fence_len && substr(rest, RLENGTH + 1) ~ /^[ \t]*$/
}

# Text a rendered view of the file does not show, though a model reads it: outside code, HTML and
# anything else shaped like a tag, an image (its alt text), a link's title, and link reference
# definitions such as `[//]: # (...)`.
function hides(l, rest,    t) {
  if (lead <= 3 && rest ~ /^\[[^]]*\]:/) return 1
  t = l
  gsub(/`+[^`]*`+/, "", t)
  return t ~ /<[^ \t0-9=<>()-]/ || index(t, "![") || t ~ /\]\([^)]*[ \t]["'(]/
}

function body_line(l) {
  if (ns) {
    sec_line[ns, ++sec_n[ns]] = l
    return
  }
  # Text before the first section; blank lines and a `# Title` line are let through.
  if (l ~ /^[ \t]*$/ || l ~ /^#[ \t]/) return
  pre_lines++
  if (!had_front && l ~ /^(---|[A-Za-z0-9_-]+:([ \t]|$))/) keyish = 1
}

# One line for a section that is not applied; after the first three, only a count.
function sec_refuse(s, op, id, why) {
  said = 1
  if (++n_secref > 3) return
  if (op != "" && echoable(id, "^[A-Za-z0-9][A-Za-z0-9_-]*$")) print "LINE - Not applied: " op ": " id " in " shown " — " why
  else print "LINE - Not applied: the section on line " sec_nr[s] " of " shown " — " why
}

function section(s,    h, op, id, i, mode, first, last, m, l, lv, key) {
  h = sec_head[s]
  sub(/[ \t]+$/, "", h)
  if (h !~ /^##[ \t]+(before|after|replace|skip):[ \t]*[^ \t]+$/) {
    sec_refuse(s, "", "", "a section heading is ## before:, ## after:, ## replace: or ## skip:, then an ID")
    return
  }
  op = h
  sub(/^##[ \t]+/, "", op)
  sub(/:.*/, "", op)
  id = h
  sub(/^##[ \t]+[a-z]+:[ \t]*/, "", id)
  if (!(id in ids_at)) {
    if (echoable(id, "^[A-Za-z0-9][A-Za-z0-9_-]*$")) sec_refuse(s, op, id, skill " has no step or gate called " id)
    else sec_refuse(s, "", "", "its ID is not one of " skill "'s steps or gates")
    return
  }
  i = ids_at[id]
  mode = ids_mode[i]
  first = 0; last = 0
  for (m = 1; m <= sec_n[s]; m++) {
    if (sec_line[s, m] ~ /^[ \t]*$/) continue
    if (!first) first = m
    last = m
  }
  if (layer && (op == "replace" || op == "skip")) {
    sec_refuse(s, op, id, "a personal file can only add steps, with before: and after:")
    return
  }
  if (op == "replace" && !first) {
    # An empty replace takes the step away: a skip, allowed only where a skip is.
    if (mode != "optional") {
      sec_refuse(s, op, id, "it has no text, which would skip " id ", and " id " is " mode ": only an optional step can be skipped")
      return
    }
    op = "skip"
  }
  if (op == "skip" && mode != "optional") {
    sec_refuse(s, op, id, id " is " mode ": only an optional step can be skipped")
    return
  }
  if (op == "replace" && mode != "replace" && mode != "optional") {
    sec_refuse(s, op, id, id " is " mode ": only a step marked replace can be replaced")
    return
  }
  if (ids_kind[i] == "rule") {
    sec_refuse(s, op, id, id " is a rule: it holds for the whole run, so it is no step to add to, replace or skip")
    return
  }
  if (skill == "task-create" && op == "before" && (id == "intake" || id == "GATE-1")) {
    sec_refuse(s, op, id, "task-create reads this file after the checks of step 1, too late for this")
    return
  }
  if (!first && op != "skip") {
    sec_refuse(s, op, id, "it has no text")
    return
  }
  for (m = first; first && m <= last; m++) {
    l = tolower(sec_line[s, m])
    if (l ~ /(^|[^a-z0-9_.-])[.]lorvel([^a-z0-9_-]|$)/) lv = 1
    if (randomish(sec_line[s, m])) key = 1
  }
  if (lv) {
    sec_refuse(s, op, id, "it names .lorvel/, whose files reach Claude only through this loader")
    return
  }
  if (key) {
    sec_refuse(s, op, id, "it looks like it carries a token or key")
    return
  }
  # A fence left open swallows every heading after it, so it can only be in the last section.
  if (s == ns && fence_len) {
    sec_refuse(s, op, id, "a code fence in it is never closed")
    return
  }
  if ((op == "replace" || op == "skip") && (id in replaced)) {
    sec_refuse(s, op, id, "a file replaces or skips a step only once")
    return
  }
  if (op == "replace" || op == "skip") replaced[id] = 1
  # Kept until every section is read: the cap is on all of them together, as printed.
  n_acc++
  acc[n_acc] = s
  acc_op[n_acc] = op
  acc_id[n_acc] = id
  acc_first[n_acc] = first
  acc_last[n_acc] = last
  printed += length(sec_heading(op, id, shown)) + 1
  for (m = first; first && m <= last; m++) printed += 4 + length(sec_line[s, m]) + 1
}

BEGIN {
  state = "start"
  layer = (shown ~ /[.]local[.]md$/)
}

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
  rest = block_start(line)
  if (fence_len) {
    if (lead <= 3 && fence_closes(rest)) fence_len = 0
    body_line(line)
    next
  }
  if (lead <= 3 && rest ~ /^##([ \t]|$)/) {
    ns++
    sec_nr[ns] = NR
    sec_head[ns] = rest
    sec_n[ns] = 0
    next
  }
  run = lead <= 3 ? fence_opener(rest) : ""
  if (run != "") {
    fence_ch = substr(run, 1, 1)
    fence_len = length(run)
    # Words after a fence's language are dropped when the file is rendered.
    info = substr(rest, fence_len + 1)
    sub(/^[ \t]+/, "", info)
    sub(/[ \t]+$/, "", info)
    if (info ~ /[ \t]/ && !hidden_nr) hidden_nr = NR
  } else if (!hidden_nr && hides(line, rest)) {
    hidden_nr = NR
  }
  body_line(line)
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
  if (pre_lines) {
    nofront = !had_front && keyish ? "; settings go between two --- lines at the very top" : ""
    if (ns) print "LINE - Not applied: the text before the first section of " shown " — only sections apply" nofront
    else if (nofront != "") print "LINE - Not applied: " shown " — it has no frontmatter" nofront
    else print "LINE - Not applied: the body of " shown " — it has no sections; a section starts with ## before:, ## after:, ## replace: or ## skip:, then an ID"
    said = 1
  }
  if (!ns) {
    if (!said) print "LINE - Nothing in " shown " applies in this version"
    exit
  }
  said = 1
  if (hidden_nr) {
    print "LINE - Not applied: the sections of " shown " — line " hidden_nr " holds text a rendered view of the file does not show: HTML or a tag, a link definition, or words after a code fence's language"
    exit
  }
  if (!load_ids(ENVIRON["LORVEL_SKILLMD"])) exit 2
  for (s = 1; s <= ns; s++) section(s)
  if (n_secref > 3) print "LINE - Not applied: " (n_secref - 3) " more section" (n_secref > 4 ? "s" : "") " in " shown
  if (n_acc && printed > seccap) {
    print "LINE - Not applied: the sections of " shown " that would apply — together they take more than " seccap " bytes; shorten them, or point to a file in the repository"
    exit
  }
  for (k = 1; k <= n_acc; k++) {
    print "SEC " acc_op[k] " " acc_id[k] " " shown
    for (m = acc_first[k]; acc_first[k] && m <= acc_last[k]; m++) print "TXT " sec_line[acc[k], m]
  }
}
