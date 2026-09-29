# The last filter lorvel-load runs over what lorvel-load.sh printed, before any of it reaches the
# model. Load lorvel-token.awk first. Prints OK when every line has a shape that half prints, and
# nothing otherwise — so a missing or truncated copy of this file lets nothing through:
#   - the "- " lines, in printable ASCII plus the dash the loader uses, and the verdict on a
#     draft that lorvel-customize asks for;
#   - a section's text, each line quoted with "  > ", only right under its own
#     "- <op>: <ID> (<label>) — from <file>:" line;
#   - after any section, one "Sections:" line, last.
# No line may look like a token or a key. lorvel-load also scans the whole output for invisible
# characters, as it scans a file.

{
  line = $0
  if (tokenish(line) || randomish(line)) bad = 1
  if (substr(line, 1, 3) == "  >") {
    if (!under || (length(line) > 3 && substr(line, 4, 1) != " ")) bad = 1
    next
  }
  under = 0
  plain = line
  gsub(/\342\200\224/, "", plain)
  if (plain ~ /[^ -~]/ || closed) { bad = 1; next }
  # A string, not /.../: a slash inside brackets ends a regex literal in some awks.
  if (line ~ "^- (before|after|replace|skip): [A-Za-z0-9_-]+ [(][A-Za-z0-9 ,]+[)] \342\200\224 from [.]lorvel/[a-z.-]+[.]md:$") {
    under = 1
    sections++
    next
  }
  if (substr(line, 1, 10) == "Sections: ") {
    if (!sections || index(line, "Sections: run each where it is anchored ") != 1 || !index(line, ". Locked in ")) bad = 1
    closed = 1
    next
  }
  # What lorvel-customize asks for about a draft, and nothing else of that shape.
  if (line ~ "^- Draft [.]lorvel/[a-z.-]+[.]md: (applies|does not apply) in full$") next
  if (line !~ /^- (review: |STOP-2 on by default |Not applied: |Nothing in )/) bad = 1
}

END {
  if (sections && !closed) bad = 1
  if (!bad) print "OK"
}
