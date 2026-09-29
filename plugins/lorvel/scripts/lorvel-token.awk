# Shared by lorvel-read.awk and lorvel-check.awk: the checks for text that looks like a token or a
# key. Loaded with -f ahead of the program that calls them.

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
