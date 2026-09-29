# lorvel-load.sh <task-work|task-create> <session folder>
#
# The checking half of lorvel-load, which is the only thing that calls it and which prints the
# header above these lines. Reads the two layers of one command's customisation,
# .lorvel/<command>.md (shared) and .lorvel/<command>.local.md (personal), and prints one line per
# thing to say, each starting with "- " — a section's text quoted under its own line — and, when a
# section applies, the "Sections:" line last. Nothing from a file reaches the output unless it
# passed every check: a file refused as a whole leaves one line naming it and the reason, never its
# text.
# May exit non-zero on something unexpected; lorvel-load turns that into "customisation is off".

set -u
set -f
LC_ALL=C
export LC_ALL

skill=$1
dir=$2/.lorvel
case $0 in */*) here=${0%/*} ;; *) here=. ;; esac
limit=65536
# The most bytes the sections of one file may take once printed. With everything else the loader
# can print, it keeps the command's rendered text, block included, under the ~20,000 characters
# Claude Code attaches again after compaction.
seccap=1536
# Through the environment, not awk -v, which would read a backslash in the path as an escape.
LORVEL_SKILLMD=$here/../skills/$skill/SKILL.md
export LORVEL_SKILLMD
nl='
'

listed() {
  [ -n "$(find "$1/." ! -name . -prune -name "$2" -print 2>/dev/null)" ]
}

if [ -L "$dir" ]; then
  printf '%s\n' "- Not applied: .lorvel/ — it is a symbolic link, and only a real folder in the session folder is read"
  exit 0
fi
if [ ! -r "$dir" ] || [ ! -x "$dir" ]; then
  printf '%s\n' "- Not applied: .lorvel/ — the folder cannot be read"
  exit 0
fi

review='' review_from='' review_over='' plan_from='' notes='' secs='' recs=''

for name in "$skill.md" "$skill.local.md"; do
  listed "$dir" "$name" || continue
  f=$dir/$name
  shown=.lorvel/$name
  refuse=''
  if [ -L "$f" ]; then
    refuse='it is a symbolic link'
  elif [ ! -f "$f" ]; then
    refuse='it is not a regular file'
  elif [ ! -r "$f" ]; then
    refuse='it cannot be read'
  else
    # Read at most one byte past the limit; od's own failure must not look like an empty file.
    hex=$(od -An -v -tx1 -N $((limit + 1)) "$f") || exit 1
    nonempty=0
    [ -s "$f" ] && nonempty=1
    verdict=$(printf '%s\n' "$hex" | awk -v limit="$limit" -v nonempty="$nonempty" -f "$here/lorvel-scan.awk") || exit 1
    case $verdict in
      OK) ;;
      'BAD '*) refuse=${verdict#BAD } ;;
      *) exit 1 ;;
    esac
  fi
  if [ -n "$refuse" ]; then
    notes="$notes- Not applied: all of $shown — $refuse$nl"
    continue
  fi

  records=$(awk -v skill="$skill" -v shown="$shown" -v limit="$limit" -v seccap="$seccap" \
    -f "$here/lorvel-token.awk" -f "$here/lorvel-ids.awk" -f "$here/lorvel-read.awk" "$f") || exit 1
  [ -n "$records" ] || exit 1
  old_ifs=$IFS
  IFS=$nl
  for r in $records; do
    case $r in
      'REVIEW '*)
        [ -n "$review" ] && review_over=$review_from
        review=${r#REVIEW }
        review_from=$shown
        ;;
      PLAN) plan_from=${plan_from:+$plan_from and }$shown ;;
      'LINE '*) notes="$notes${r#LINE }$nl" recs="${recs}NOTE ${r#LINE }$nl" ;;
      'SEC '*) secs=1 recs="$recs$r$nl" ;;
      'TXT '*) recs="$recs$r$nl" ;;
      *) exit 1 ;;
    esac
  done
  IFS=$old_ifs
done

if [ -n "$review" ]; then
  if [ -n "$review_over" ]; then
    printf '%s\n' "- review: $review — from $review_from, which replaces the one in $review_over"
  else
    printf '%s\n' "- review: $review — from $review_from"
  fi
fi
if [ -n "$plan_from" ]; then
  printf '%s\n' "- STOP-2 on by default — defaults.plan: true in $plan_from; typing --no-plan turns it off for one run"
fi
if [ -z "$secs" ]; then
  printf '%s' "$notes"
  exit 0
fi
# The sections, then the notes, then the "Sections:" line.
out=$(printf '%s' "$recs" | awk -v skill="$skill" -f "$here/lorvel-ids.awk" -f "$here/lorvel-sections.awk") || exit 1
printf '%s\n' "$out"
