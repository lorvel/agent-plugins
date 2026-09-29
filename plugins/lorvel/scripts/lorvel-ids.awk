# Reads the step IDs a SKILL.md declares under metadata.lorvel.ids (see ids.md), for the programs
# loaded after it, and holds what they share: join() and sec_heading(). Every name here that could
# meet a function of those programs starts with ids_ — POSIX awk refuses a parameter that shares a
# function's name. load_ids(path) returns 1 and fills, for i = 1..ids_n in the order declared:
#   ids_id[i] ids_kind[i] ids_mode[i] ids_what[i]   the fields, as strings
#   ids_in[i]           a gate's steps, space-separated
#   ids_src_n[i], ids_src[i, k]   a rule's source phrases
#   ids_label[i]        a step's "Phase 3" or "Step 7" (the part of `what` before " — "); a gate's
#                       "in " and its steps' labels
#   ids_at[id] = i
# or returns 0 when the list is not there or not in the two shapes the plugin writes it in: a
# one-line flow map per step or gate, and a block map per rule. Anything else is refused rather
# than guessed at, and tests/ids.test.rb checks this reading against a real YAML parser.

# "a", "a and b", "a, b and c".
function join(a, n,    s, k) {
  s = ""
  for (k = 1; k <= n; k++) s = s (k == 1 ? "" : k == n ? " and " : ", ") a[k]
  return s
}

# The line a section is printed under — and counted by, against the cap on printed sections.
function sec_heading(op, id, file) {
  return "- " op ": " id " (" ids_label[ids_at[id]] ") \342\200\224 from " file ":"
}

function ids_trim(s) {
  sub(/^[ \t]+/, "", s)
  sub(/[ \t]+$/, "", s)
  return s
}

# Splits s at the commas outside double quotes and brackets into parts[1..n], and returns n, or -1
# when a quote or a bracket is left open.
function ids_split(s, parts,    n, i, c, q, d, cur) {
  n = 0; q = 0; d = 0; cur = ""
  for (i = 1; i <= length(s); i++) {
    c = substr(s, i, 1)
    if (q) {
      if (c == "\"") q = 0
      cur = cur c
      continue
    }
    if (c == "\"") q = 1
    else if (c == "[" || c == "{") d++
    else if (c == "]" || c == "}") d--
    else if (c == "," && d == 0) {
      parts[++n] = ids_trim(cur)
      cur = ""
      continue
    }
    cur = cur c
  }
  if (q || d) return -1
  parts[++n] = ids_trim(cur)
  return n
}

# A bare word, or a double-quoted string without escapes.
function ids_scalar(v) {
  v = ids_trim(v)
  if (substr(v, 1, 1) == "\"") {
    if (v !~ /^"[^"\\]*"$/) { ids_bad = 1; return "" }
    return substr(v, 2, length(v) - 2)
  }
  if (v !~ /^[A-Za-z0-9][A-Za-z0-9_-]*$/) ids_bad = 1
  return v
}

function ids_pair(i, pair,    p, key, val, n, parts, k) {
  p = index(pair, ":")
  if (!p) { ids_bad = 1; return }
  key = ids_trim(substr(pair, 1, p - 1))
  val = ids_trim(substr(pair, p + 1))
  if (key == "in" || key == "source") {
    if (val !~ /^\[.*\]$/) { ids_bad = 1; return }
    n = ids_split(substr(val, 2, length(val) - 2), parts)
    if (n < 1) { ids_bad = 1; return }
    for (k = 1; k <= n; k++) {
      if (key == "in") ids_in[i] = ids_in[i] (k > 1 ? " " : "") ids_scalar(parts[k])
      else ids_src[i, k] = ids_scalar(parts[k])
    }
    if (key == "source") ids_src_n[i] = n
  }
  else if (key == "id") ids_id[i] = ids_scalar(val)
  else if (key == "kind") ids_kind[i] = ids_scalar(val)
  else if (key == "mode") ids_mode[i] = ids_scalar(val)
  else if (key == "what") ids_what[i] = ids_scalar(val)
  # A field this reader does not know is skipped, as ids.md says a reader does.
}

function load_ids(path,    ids_line, ids_rc, ids_nr, ids_state, ids_ind, ids_top, ids_lvl, ids_item, ids_rest, n, parts, k, i, w, p, m, labels) {
  ids_n = 0; ids_bad = 0; ids_nr = 0; ids_item = -1
  while ((ids_rc = (getline ids_line < path)) > 0) {
    ids_nr++
    sub(/\r$/, "", ids_line)
    if (ids_nr == 1) {
      if (ids_line !~ /^---[ \t]*$/) break
      ids_state = "front"
      continue
    }
    if (ids_line ~ /^---[ \t]*$/) break
    if (ids_line ~ /^[ \t]*$/ || ids_line ~ /^[ \t]*#/) continue
    match(ids_line, /^ */)
    ids_ind = RLENGTH
    if (ids_state == "front") {
      if (ids_line ~ /^metadata:[ \t]*$/) ids_state = "metadata"
      continue
    }
    if (ids_state == "metadata") {
      if (ids_ind == 0) { ids_state = "front"; continue }
      if (ids_line ~ /^ +lorvel:[ \t]*$/) { ids_state = "lorvel"; ids_lvl = ids_ind }
      continue
    }
    if (ids_state == "lorvel") {
      if (ids_ind <= ids_lvl) { ids_state = ids_ind ? "metadata" : "front"; continue }
      if (ids_line ~ /^ +ids:[ \t]*$/) { ids_state = "ids"; ids_top = ids_ind }
      continue
    }
    if (ids_state == "ids") {
      if (ids_ind <= ids_top) { ids_state = "done"; continue }
      ids_rest = substr(ids_line, ids_ind + 1)
      if (ids_item < 0) ids_item = ids_ind
      if (ids_ind == ids_item && substr(ids_rest, 1, 2) == "- ") {
        i = ++ids_n
        ids_rest = ids_trim(substr(ids_rest, 3))
        if (ids_rest ~ /^\{.*\}$/) {
          n = ids_split(substr(ids_rest, 2, length(ids_rest) - 2), parts)
          if (n < 1) ids_bad = 1
          for (k = 1; k <= n; k++) ids_pair(i, parts[k])
        } else {
          ids_pair(i, ids_rest)
        }
      } else if (ids_ind > ids_item && ids_n > 0) {
        ids_pair(ids_n, ids_trim(ids_rest))
      } else {
        ids_bad = 1
      }
    }
  }
  close(path)
  if (ids_rc < 0 || ids_bad || !ids_n) return 0
  for (i = 1; i <= ids_n; i++) {
    if (ids_id[i] == "" || (ids_id[i] in ids_at)) return 0
    ids_at[ids_id[i]] = i
    if (ids_mode[i] !~ /^(locked|extend|replace|optional)$/) return 0
    if (ids_kind[i] == "step") {
      w = ids_what[i]
      p = index(w, " \342\200\224 ")
      if (p < 2) return 0
      ids_label[i] = substr(w, 1, p - 1)
    } else if (ids_kind[i] == "rule") {
      if (ids_src_n[i] < 1) return 0
    } else if (ids_kind[i] != "gate") {
      return 0
    }
  }
  # A gate is labelled by the steps it sits in, which the list declares before it.
  for (i = 1; i <= ids_n; i++) {
    if (ids_kind[i] != "gate") continue
    n = split(ids_in[i], parts, " ")
    if (n < 1) return 0
    for (k = 1; k <= n; k++) {
      if (!(parts[k] in ids_at)) return 0
      m = ids_at[parts[k]]
      if (ids_kind[m] != "step") return 0
      labels[k] = ids_label[m]
    }
    ids_label[i] = "in " join(labels, n)
  }
  return 1
}
