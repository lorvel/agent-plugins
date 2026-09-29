#!/bin/sh
# Tests for plugins/lorvel/scripts/lorvel-customize, what /lorvel:task-customize runs.
# Run from anywhere: sh tests/customize.test.sh
#
# Every case checks the exit status (always 0) and the output; the cases that write check the
# files byte for byte, and the ones that must not write check that nothing changed.

set -u
root=$(cd "$(dirname "$0")/.." && pwd) || exit 1
work=$(mktemp -d "${TMPDIR:-/tmp}/lorvel-customize-test.XXXXXX") || exit 1
[ -d "$work" ] || exit 1
cleanup() { chmod -R u+rwx "$work" 2>/dev/null; rm -rf "$work"; }
trap cleanup EXIT
trap 'cleanup; exit 130' INT
trap 'cleanup; exit 143' TERM

# Nothing from the machine running the suite: git reads no global or system configuration and no
# template, and the scratch folders the script makes go to a folder of the suite's own, which has
# to be empty at the end.
HOME=$work/home XDG_CONFIG_HOME=$work/xdg GIT_CONFIG_NOSYSTEM=1 TMPDIR=$work/tmp
export HOME XDG_CONFIG_HOME GIT_CONFIG_NOSYSTEM TMPDIR
unset GIT_CONFIG_GLOBAL GIT_TEMPLATE_DIR GIT_DIR GIT_WORK_TREE folder
mkdir -p "$HOME" "$XDG_CONFIG_HOME" "$TMPDIR"

C=$root/plugins/lorvel/scripts/lorvel-customize
L=$root/plugins/lorvel/scripts/lorvel-load
H='Customisation from .lorvel/, checked by the lorvel plugin:'
N='No customisation from .lorvel/ for this command.'
USAGE='- lorvel-customize takes show <command>, check <command> shared|personal, write <command> shared|personal new|replace, or gitignore <command> [add]; it did nothing.'
pass=0
fail=0
MARK=''
nl='
'

# run <args...> — runs the script on $work/in and sets `got` and `rc`. A run still going after 10
# seconds is killed with everything it started, so a change that makes it block fails this suite
# instead of hanging it.
killtree() {
  for c in $(pgrep -P "$1" 2>/dev/null); do killtree "$c"; done
  kill -9 "$1" 2>/dev/null
}
run() {
  "${SCRIPT:-$C}" "$@" < "$work/in" > "$work/out" 2>&1 &
  pid=$!
  (
    trap 'kill "$s" 2>/dev/null; exit 0' TERM
    sleep 10 &
    s=$!
    wait "$s" && killtree "$pid"
  ) > /dev/null 2>&1 &
  dog=$!
  wait "$pid"
  rc=$?
  kill "$dog" 2>/dev/null
  wait "$dog" 2>/dev/null
  got=$(cat "$work/out")
}

# input <line>... — the script's standard input, one argument per line.
input() {
  : > "$work/in"
  for l in "$@"; do printf '%s\n' "$l" >> "$work/in"; done
}

tally() {
  if [ "$1" = 1 ]; then pass=$((pass + 1)); else fail=$((fail + 1)); fi
}

# expect <case> <want> — the exit status is 0 and the output is exactly <want>.
expect() {
  ok=1
  [ "$rc" = 0 ] || { ok=0; echo "FAIL $1: exit $rc"; }
  [ "$got" = "$2" ] || { ok=0; printf 'FAIL %s\n--- want\n%s\n--- got\n%s\n---\n' "$1" "$2" "$got"; }
  if [ -n "$MARK" ]; then
    case $got in *"$MARK"*) ok=0; echo "FAIL $1: the marker reached the output" ;; esac
  fi
  MARK=''
  tally $ok
}

# is <case> <condition...> — one more check that has to hold.
is() {
  name=$1
  shift
  if "$@"; then tally 1; else tally 0; echo "FAIL $name"; fi
}

# has <case> <line> — the last output holds that line.
has() {
  case "$nl$got$nl" in
    *"$nl$2$nl"*) tally 1 ;;
    *) tally 0; printf 'FAIL %s: no line\n%s\n--- got\n%s\n---\n' "$1" "$2" "$got" ;;
  esac
}

# repo <name> — a fresh git repository; prints its path.
repo() {
  d=$work/$1
  mkdir -p "$d"
  git init -q "$d" > /dev/null 2>&1
  printf '%s' "$d"
}

# plain <name> — a fresh folder that is not in a git repository; prints its path.
plain() {
  d=$work/plain/$1
  mkdir -p "$d"
  printf '%s' "$d"
}

loader_of() {
  sh "$L" "$1" "$2" < /dev/null
}

# absent <path>... — none of them is there, not even as a link.
absent() {
  for f; do
    [ ! -e "$f" ] && [ ! -L "$f" ] || return 1
  done
}

# Token-shaped strings are put together at run time, so that this file holds none a secret scanner
# would stop at a push.
j() { printf '%s%s' "$1" "$2"; }

# --- show ------------------------------------------------------------------------------------------

d=$(plain show)
input "$d"
run show task-work
first=$(printf '%s\n' "$got" | head -n 1)
last=$(printf '%s\n' "$got" | tail -n 1)
is "show: exit 0" [ "$rc" = 0 ]
is "show: opens with the steps" [ "$first" = "Steps and gates of task-work, in the order they run, and the sections each takes:" ]
is "show: ends with what applies now" [ "$last" = "$N" ]
is "show: one line per step and gate" [ "$(printf '%s\n' "$got" | awk '/^Rules of/ { exit } /^- / { n++ } END { print n + 0 }')" = 10 ]
is "show: one line per rule" [ "$(printf '%s\n' "$got" | awk '/^What the modes mean/ { exit } r && /^- / { n++ } /^Rules of/ { r = 1 } END { print n + 0 }')" = 7 ]
# Read another way than the script reads it: every bullet of the section, and its last paragraph.
modes=$(sed -n '/^## Modes$/,/^## Changing/p' "$root/plugins/lorvel/ids.md" | grep -e '^- `' -e '^Text counts as what it does')
is "show: the modes are quoted from ids.md" [ "$(printf '%s\n' "$got" | awk '/^What the modes mean/ { m = 1; next } /^Where a section runs/ { m = 0 } m')" = "$modes" ]
is "show: where a section runs, as the loader says it" [ "$(printf '%s\n' "$got" | grep '^Where a section runs: ')" = "Where a section runs: before: as that step starts, after: once it is done, replace: in its place, skip: not at all; an after: on the last step runs before the closing report, which stays last. A gate keeps its place when it is off, and one that sits in more than one step runs its sections in each." ]
is "show: a file only tightens" [ "$(printf '%s\n' "$got" | grep -c '^A file only tightens: defaults.plan: false and defaults.auto are refused\.')" = 1 ]

input "$d"
run show task-create
is "show task-create: before: intake is not taken, and why" [ "$(printf '%s\n' "$got" | grep '^- intake ')" = "- intake (extend: Step 1 — get the guide, check the tools): after:; no before: — task-create reads this file after the checks of step 1, too late for this" ]
is "show task-create: replace: classify in the shared file only" [ "$(printf '%s\n' "$got" | grep '^- classify ')" = "- classify (replace: Step 3 — settle bug, change or spike): before:, after:, replace:; in the personal file, before:, after:" ]
is "show task-create: no settings" [ "$(printf '%s\n' "$got" | grep -c '^Settings: task-create has none in this version')" = 1 ]

# Every section the list says an ID takes, the loader applies; every one it leaves out, the loader
# refuses — in the shared and in the personal file. The list asks the loader's own function, and
# this holds it to that.
agree() {
  cmd=$1
  input "$work/plain/show"
  run show "$cmd"
  printf '%s\n' "$got" | awk '/^What the modes mean/ { exit } /^- / { print }' > "$work/points"
  while IFS= read -r line; do
    id=${line#- }
    id=${id%% *}
    ops=${line##*'): '}
    shared=${ops%%;*}
    case $ops in
      *'; in the personal file, '*) mine=${ops#*'; in the personal file, '}; mine=${mine%%;*} ;;
      *) mine=$shared ;;
    esac
    case $line in *' (locked): '*) shared='no section' mine='no section' ;; esac
    for layer in shared personal; do
      if [ $layer = shared ]; then f=$cmd.md list=$shared; else f=$cmd.local.md list=$mine; fi
      for op in before after replace skip; do
        a=$work/agree
        rm -rf "$a"
        mkdir -p "$a/.lorvel"
        if [ $op = skip ]; then printf '## skip: %s\n' "$id"; else printf '## %s: %s\n\nSome text.\n' "$op" "$id"; fi > "$a/.lorvel/$f"
        case $(loader_of "$cmd" "$a") in *"$nl- $op: $id ("*) applied=yes ;; *) applied=no ;; esac
        case ", $list," in *", $op:,"*) listed=yes ;; *) listed=no ;; esac
        if [ $applied = $listed ]; then
          tally 1
        else
          tally 0
          echo "FAIL show $cmd: $op: $id in the $layer file — listed $listed, applied $applied"
        fi
      done
    done
  done < "$work/points"
}
agree task-work
agree task-create

# The settings the list names are the ones the loader takes, for each command.
a=$work/settings
rm -rf "$a"; mkdir -p "$a/.lorvel"
printf -- '---\nreview: code-review xhigh --fix\ndefaults:\n  plan: true\n---\n' > "$a/.lorvel/task-work.md"
is "settings: task-work applies review and defaults.plan" [ "$(loader_of task-work "$a")" = "$H$nl- review: code-review xhigh --fix — from .lorvel/task-work.md$nl- STOP-2 on by default — defaults.plan: true in .lorvel/task-work.md; typing --no-plan turns it off for one run" ]
printf -- '---\nreview: code-review\ndefaults:\n  plan: true\n---\n' > "$a/.lorvel/task-create.md"
is "settings: task-create takes none" [ "$(loader_of task-create "$a")" = "$H$nl- Not applied: review, defaults.plan in .lorvel/task-create.md — not a setting of task-create in this version" ]

input "$d" "more"
run show task-work
expect "show: a line break in the folder's name" "- The name of the session folder has a line break in it, so nothing was read."

input "$d"
run show task-customize
expect "show: another command" "- lorvel-customize works on task-work and task-create only, so it did nothing."

input "$d"
run show task-work extra
expect "show: an argument it does not take" "$USAGE"

input "$work/nowhere"
run show task-work
expect "show: no such folder" "- The first line of the input names no folder, so nothing was done."

# Closed standard input, and a `folder` in the environment: still one line, and exit 0.
export folder="$d"
"$C" show task-work <&- > "$work/out" 2>&1
rc=$?
got=$(cat "$work/out")
unset folder
expect "show: no input at all" "- The first line of the input names no folder, so nothing was done."

# What applies now is the loader's own output, file lines and all.
d=$(plain show-now)
mkdir -p "$d/.lorvel"
printf -- '---\nreview: code-review xhigh --fix\n---\n' > "$d/.lorvel/task-work.md"
input "$d"
run show task-work
is "show: what applies now is the loader's output" [ "$(printf '%s\n' "$got" | awk 'n { print } /^What applies now: /{ n = 1 }')" = "$(loader_of task-work "$d")" ]

# With both files there, each one's own settings and sections, which the combined view hides where
# the personal review wins; and the comment and title lines no view prints.
d=$(plain show-both)
mkdir -p "$d/.lorvel"
printf -- '---\n# the team agreed on this one\nreview: team-review --strict\n---\n\n# Team customisation\n\n## after: review\n\nShared.\n' > "$d/.lorvel/task-work.md"
printf -- '---\nreview: my-review\n---\n' > "$d/.lorvel/task-work.local.md"
input "$d"
run show task-work
has "show: the combined view names only the review that wins" "- review: my-review — from .lorvel/task-work.local.md, which replaces the one in .lorvel/task-work.md"
has "show: the shared file on its own, heading" "What .lorvel/task-work.md applies on its own:"
has "show: the shared file on its own, its review" "- review: team-review --strict — from .lorvel/task-work.md"
has "show: the personal file on its own, heading" "What .lorvel/task-work.local.md applies on its own:"
has "show: the lines a rewrite drops, counted" "- .lorvel/task-work.md also holds 2 comment or title lines, which no view prints and a rewrite of it drops."
is "show: no count for a file without them" [ "$(printf '%s\n' "$got" | grep -c 'task-work.local.md also holds')" = 0 ]

# --- check ----------------------------------------------------------------------------------------

DRAFT='---
schema: 1
review: code-review xhigh --fix
---

## after: review

Run the linter with its fix option.'

d=$(plain check)
input "$d" "$DRAFT"
run check task-work shared
mkdir -p "$work/same/.lorvel"
printf '%s\n' "$DRAFT" > "$work/same/.lorvel/task-work.md"
expect "check: a clean draft" "- Checked: the loader applies all of the draft for .lorvel/task-work.md. With it in place, a run of task-work starts with these lines.$nl$(loader_of task-work "$work/same")"
is "check: writes nothing" absent "$d/.lorvel"

# check_refused <case> <command> <layer> <draft> <line the loader has to print>
check_refused() {
  input "$d" "$4"
  run check "$2" "$3"
  ok=1
  [ "$rc" = 0 ] || ok=0
  case $got in
    "- Not clean: the loader does not apply all of the draft for "*) ;;
    *) ok=0 ;;
  esac
  case $got in *"$nl$5"*) ;; *) ok=0 ;; esac
  absent "$d/.lorvel" || ok=0
  [ $ok = 1 ] || printf 'FAIL %s\n%s\n---\n' "$1" "$got"
  tally $ok
}
check_refused "check: skipping a locked gate" task-work shared "---${nl}schema: 1${nl}---${nl}${nl}## skip: STOP-1" "- Not applied: skip: STOP-1 in .lorvel/task-work.md — STOP-1 is locked: only an optional step can be skipped"
check_refused "check: plan: false" task-work shared "---${nl}defaults:${nl}  plan: false${nl}---" "- Not applied: defaults.plan in .lorvel/task-work.md — a file can only turn STOP-2 on; typing --no-plan turns it off for one run"
check_refused "check: auto" task-work personal "---${nl}defaults:${nl}  auto: true${nl}---" "- Not applied: defaults.auto in .lorvel/task-work.local.md — only the person typing the command can pass --auto"
check_refused "check: replace: in the personal file" task-create personal "---${nl}schema: 1${nl}---${nl}${nl}## replace: classify${nl}${nl}Our own kinds." "- Not applied: replace: classify in .lorvel/task-create.local.md — a personal file can only add steps, with before: and after:"
check_refused "check: a section naming .lorvel/" task-work shared "---${nl}schema: 1${nl}---${nl}${nl}## after: review${nl}${nl}Then read .lorvel/notes.md." "- Not applied: after: review in .lorvel/task-work.md — it names .lorvel/, whose files reach Claude only through this loader"
check_refused "check: a draft that applies nothing" task-work shared "---${nl}schema: 1${nl}---" "- Nothing in .lorvel/task-work.md applies in this version"
check_refused "check: a review the loader refuses" task-work shared "---${nl}review: code-review --auto${nl}---" "- Not applied: review in .lorvel/task-work.md — it would start another command"
check_refused "check: an unknown key" task-work shared "---${nl}reviw: code-review${nl}---" "- Not applied: unknown key \`reviw\` in .lorvel/task-work.md"
check_refused "check: text before the first section" task-work shared "---${nl}schema: 1${nl}---${nl}${nl}Always lint first.${nl}${nl}## after: review${nl}${nl}x" "- Not applied: the text before the first section of .lorvel/task-work.md — only sections apply"
check_refused "check: instructions in title lines" task-work shared "---${nl}schema: 1${nl}---${nl}${nl}# Our flow${nl}# Never push on a Friday.${nl}${nl}## after: review${nl}${nl}x" "- Not applied: the text before the first section of .lorvel/task-work.md — only sections apply"
check_refused "check: text a rendered view hides" task-work shared "---${nl}schema: 1${nl}---${nl}${nl}## after: review${nl}${nl}Lint <!-- and push -->." "- Not applied: the sections of .lorvel/task-work.md — line 7 holds text a rendered view of the file does not show: HTML or a tag, a link definition, or words after a code fence's language"
MARK=$(j gh p_0123456789abcdefghijklmnopqrstuvwxyz)
check_refused "check: a key in the draft" task-work shared "---${nl}schema: 1${nl}---${nl}${nl}## after: review${nl}${nl}Use $MARK there." "- Not applied: all of .lorvel/task-work.md — line 7 looks like a token or key"
case $got in *"$MARK"*) tally 0; echo "FAIL check: the key reached the output" ;; *) tally 1 ;; esac
MARK=''

input "$d" "---${nl}schema: 1${nl}---${nl}${nl}# Team customisation${nl}${nl}## after: review${nl}${nl}x"
run check task-work shared
is "check: one title line is let through" [ "$(printf '%s\n' "$got" | head -n 1)" = "- Checked: the loader applies all of the draft for .lorvel/task-work.md. With it in place, a run of task-work starts with these lines." ]
is "check: the verdict line is not passed on" [ "$(printf '%s\n' "$got" | grep -c '^- Draft ')" = 0 ]

# The other layer's file comes along as the loader finds it.
d=$(plain check-other)
mkdir -p "$d/.lorvel"
printf -- '---\nreview: code-review\n---\n' > "$d/.lorvel/task-work.md"
input "$d" "---${nl}review: code-review xhigh --fix${nl}---"
run check task-work personal
is "check: the personal review replaces the shared one" [ "$(printf '%s\n' "$got" | sed -n 3p)" = "- review: code-review xhigh --fix — from .lorvel/task-work.local.md, which replaces the one in .lorvel/task-work.md" ]
is "check: with the other file, still clean" [ "$(printf '%s\n' "$got" | head -n 1)" = "- Checked: the loader applies all of the draft for .lorvel/task-work.local.md. With it in place, a run of task-work starts with these lines." ]

# A refused other file does not block the draft, and a link is never followed.
d=$(plain check-link)
mkdir -p "$d/.lorvel"
MARK=MARKER-behind-the-link
printf -- '---\nschema: 1\n---\n\n## after: review\n\n%s\n' "$MARK" > "$work/target.md"
ln -s "$work/target.md" "$d/.lorvel/task-work.md"
input "$d" "---${nl}schema: 1${nl}---${nl}${nl}## after: review${nl}${nl}Mine."
run check task-work personal
expect "check: the other file is a link" "- Checked: the loader applies all of the draft for .lorvel/task-work.local.md. With it in place, a run of task-work starts with these lines.
$H
- after: review (Phase 4) — from .lorvel/task-work.local.md:
  > Mine.
- Not applied: all of .lorvel/task-work.md — it is a symbolic link
$(loader_of task-work "$work/same" | tail -n 1)"

d=$(plain check-dir)
mkdir -p "$d/.lorvel/task-work.md"
input "$d" "---${nl}review: code-review${nl}---"
run check task-work personal
is "check: the other file is a folder" [ "$(printf '%s\n' "$got" | grep -c '^- Not applied: all of .lorvel/task-work.md — it is not a regular file$')" = 1 ]

# .lorvel/ itself, as the loader sees it: a link, a file, a folder it cannot read.
d=$(plain check-linked-folder)
mkdir -p "$work/linked-folder"
printf -- '---\nschema: 1\n---\n\n## after: review\n\nMARKER-behind-the-folder-link\n' > "$work/linked-folder/task-work.md"
ln -s "$work/linked-folder" "$d/.lorvel"
MARK=MARKER-behind-the-folder-link
input "$d" "---${nl}schema: 1${nl}---${nl}${nl}## after: review${nl}${nl}Mine."
run check task-work personal
expect "check: .lorvel is a link" "- Not checked: .lorvel/ in the session folder — it is a symbolic link, and only a real folder in the session folder is read. That is the user's to fix first."
d=$(plain check-folder-file)
printf 'x\n' > "$d/.lorvel"
input "$d" "$DRAFT"
run check task-work shared
expect "check: .lorvel is a file" "- Not checked: .lorvel/ in the session folder — it is not a folder. That is the user's to fix first."
if [ "$(id -u)" != 0 ]; then
  d=$(plain check-unreadable)
  mkdir -p "$d/.lorvel"
  chmod 0300 "$d/.lorvel"
  input "$d" "$DRAFT"
  run check task-work shared
  expect "check: .lorvel cannot be read" "- Not checked: .lorvel/ in the session folder — the folder cannot be read. That is the user's to fix first."
  input "$d" "$DRAFT"
  run write task-work shared new
  expect "write: .lorvel cannot be read" "- Not written: .lorvel/ in the session folder — the folder cannot be read. That is the user's to fix first."
  chmod 0700 "$d/.lorvel"
  is "write: nothing written into a folder the loader cannot read" [ -z "$(ls -A "$d/.lorvel")" ]
fi

# On a disk that ignores case, a file named like the draft's but for case is not the loader's file.
mkdir -p "$work/case" && : > "$work/case/probe"
if [ -e "$work/case/PROBE" ]; then
  d=$(plain case)
  mkdir -p "$d/.lorvel"
  printf -- '---\nschema: 1\n---\n\n## after: review\n\nMARKER-in-the-miscased-file\n' > "$d/.lorvel/Task-Work.md"
  cp "$d/.lorvel/Task-Work.md" "$work/miscased-before"
  MARK=MARKER-in-the-miscased-file
  input "$d" "$DRAFT"
  run write task-work shared replace
  expect "write: a file named but for case" "- Not written: .lorvel/ holds a file named like task-work.md but for upper and lower case, which the loader never reads; renaming or removing it is the user's to do first."
  is "write: the miscased file is left as it was" cmp -s "$work/miscased-before" "$d/.lorvel/Task-Work.md"
  MARK=MARKER-in-the-miscased-file
  input "$d" "---${nl}schema: 1${nl}---${nl}${nl}## after: review${nl}${nl}Mine."
  run check task-work personal
  is "check: a miscased other file is not taken for it" [ "$(printf '%s\n' "$got" | head -n 1)" = "- Checked: the loader applies all of the draft for .lorvel/task-work.local.md. With it in place, a run of task-work starts with these lines." ]
  case $got in *MARKER-in-the-miscased-file*) tally 0; echo "FAIL check: the miscased file reached the output" ;; *) tally 1 ;; esac
  MARK=''
fi

# No verdict from the loader — here, a broken copy of it — is never read as a clean draft.
mkdir -p "$work/broken"
cp -R "$root/plugins/lorvel/." "$work/broken"
printf 'exit 1\n' > "$work/broken/scripts/lorvel-load.sh"
d=$(plain check-broken)
input "$d" "$DRAFT"
# Set and cleared around the call: an assignment in front of a function call outlives it in dash.
SCRIPT=$work/broken/scripts/lorvel-customize
run write task-work shared new
SCRIPT=''
is "write: no verdict, nothing written" [ "$(printf '%s\n' "$got" | head -n 1)" = "- Not written: the loader gave no verdict on the draft for .lorvel/task-work.md, so it cannot be written; what it printed follows." ]
is "write: no verdict, no file" absent "$d/.lorvel"

d=$(plain check-bad)
input "$d" "not the frontmatter"
run check task-work shared
expect "check: no --- line after the folder" "- Not checked: the draft must start with the --- line that opens its frontmatter, on the line after the session folder."
input "$d" "rest of a folder name" "---"
run check task-work shared
expect "check: a line break in the folder's name" "- Not checked: the draft must start with the --- line that opens its frontmatter, on the line after the session folder."
input "$d"
run check task-work shared
expect "check: no draft" "- Not checked: the draft must start with the --- line that opens its frontmatter, on the line after the session folder."
input "$d" "$DRAFT"
run check task-work team
expect "check: a layer it does not know" "$USAGE"

# --- write ----------------------------------------------------------------------------------------

d=$(plain "write dir's")
input "$d" "$DRAFT"
run write task-work shared new
expect "write: new, in a folder with a space and a quote" "- Written: .lorvel/task-work.md. A run of task-work in this folder now starts with these lines.$nl$(loader_of task-work "$d")"
printf '%s\n' "$DRAFT" > "$work/draft.md"
is "write: the file is the draft, byte for byte" cmp -s "$work/draft.md" "$d/.lorvel/task-work.md"
is "write: nothing else in .lorvel/" [ "$(ls -A "$d/.lorvel")" = task-work.md ]

cp "$d/.lorvel/task-work.md" "$work/before.md"
input "$d" "---${nl}schema: 1${nl}review: other${nl}---"
run write task-work shared new
expect "write: new over a file" "- Not written: .lorvel/task-work.md already exists. Rewriting it is replace, once the user has agreed to what a rewrite drops."
is "write: new over a file leaves it" cmp -s "$work/before.md" "$d/.lorvel/task-work.md"

input "$d" "---${nl}schema: 1${nl}---${nl}${nl}## skip: STOP-3"
run write task-work shared replace
is "write: a draft the loader refuses is not written" [ "$(printf '%s\n' "$got" | head -n 1)" = "- Not written: the loader does not apply all of the draft for .lorvel/task-work.md, so it cannot be written as it is. With it in place, a run of task-work would start with these lines." ]
is "write: the refused draft leaves the file" cmp -s "$work/before.md" "$d/.lorvel/task-work.md"

input "$d" "---${nl}schema: 1${nl}review: other${nl}---"
run write task-work shared replace
is "write: replace" [ "$(printf '%s\n' "$got" | head -n 1)" = "- Written: .lorvel/task-work.md. A run of task-work in this folder now starts with these lines." ]
printf -- '---\nschema: 1\nreview: other\n---\n' > "$work/draft2.md"
is "write: replace writes the new draft" cmp -s "$work/draft2.md" "$d/.lorvel/task-work.md"
is "write: replace leaves nothing else in .lorvel/" [ "$(ls -A "$d/.lorvel")" = task-work.md ]

input "$d" "$DRAFT"
run write task-work personal replace
expect "write: replace, with no file" "- Not written: .lorvel/task-work.local.md does not exist yet, so it is new."
is "write: replace with no file creates none" absent "$d/.lorvel/task-work.local.md"

input "$d" "$DRAFT"
run write task-work shared
expect "write: no new or replace" "$USAGE"

d=$(plain write-link-dir)
mkdir -p "$work/elsewhere"
ln -s "$work/elsewhere" "$d/.lorvel"
input "$d" "$DRAFT"
run write task-work shared new
expect "write: .lorvel is a link" "- Not written: .lorvel/ in the session folder — it is a symbolic link, and only a real folder in the session folder is read. That is the user's to fix first."
is "write: nothing written through the link" [ -z "$(ls -A "$work/elsewhere")" ]

d=$(plain write-link-file)
mkdir -p "$d/.lorvel"
printf 'keep\n' > "$work/kept.md"
ln -s "$work/kept.md" "$d/.lorvel/task-work.md"
input "$d" "$DRAFT"
run write task-work shared replace
expect "write: the file is a link" "- Not written: .lorvel/task-work.md is a symbolic link or not a regular file, which the loader refuses; it is not replaced from here — removing it is the user's to do."
is "write: the link's target is untouched" [ "$(cat "$work/kept.md")" = keep ]

d=$(plain write-not-dir)
printf 'x\n' > "$d/.lorvel"
input "$d" "$DRAFT"
run write task-work shared new
expect "write: .lorvel is a file" "- Not written: .lorvel/ in the session folder — it is not a folder. That is the user's to fix first."

# --- gitignore ------------------------------------------------------------------------------------

if command -v git > /dev/null 2>&1; then
  d=$(plain gi)
  input "$d"
  run gitignore task-work
  expect "gitignore: not in a repository" "- The session folder is not in a git repository: there is nothing to keep out of commits, and nothing to ask."

  # Any other failure of git is not 'no repository': nothing was checked, and that is said.
  mkdir -p "$work/fakegit"
  printf '#!/bin/sh\necho "fatal: detected dubious ownership in repository" >&2\nexit 128\n' > "$work/fakegit/git"
  chmod +x "$work/fakegit/git"
  d=$(repo gi-dubious)
  input "$d"
  oldpath=$PATH
  PATH=$work/fakegit:$PATH
  run gitignore task-work
  PATH=$oldpath
  expect "gitignore: git cannot read the repository" "- git could not read the repository the session folder is in. Not checked: nothing tells whether .lorvel/task-work.local.md would be committed, so it could end up in a commit; say so."

  d=$(repo gi-root)
  input "$d"
  run gitignore task-work
  expect "gitignore: neither" "- git does not ignore .lorvel/task-work.local.md: committing the folder would commit it.
- .worktreeinclude does not list it, so a new worktree of this repository starts without it."
  is "gitignore: reporting changes nothing" absent "$d/.gitignore" "$d/.worktreeinclude"
  input "$d"
  run gitignore task-work add
  expect "gitignore: add both" "- Added .lorvel/*.local.md to .gitignore in the session folder.
- Added .lorvel/*.local.md to .worktreeinclude at the root of the repository.
- git ignores .lorvel/task-work.local.md.
- .worktreeinclude lists it, so a new worktree of this repository gets a copy."
  is "gitignore: .gitignore holds the line" [ "$(cat "$d/.gitignore")" = '.lorvel/*.local.md' ]
  is "gitignore: .worktreeinclude holds the line" [ "$(cat "$d/.worktreeinclude")" = '.lorvel/*.local.md' ]
  input "$d"
  run gitignore task-create add
  expect "gitignore: add again adds nothing" "- git ignores .lorvel/task-create.local.md.
- .worktreeinclude lists it, so a new worktree of this repository gets a copy."
  is "gitignore: still one line each" [ "$(cat "$d/.gitignore" "$d/.worktreeinclude" | wc -l | tr -d ' ')" = 2 ]

  d=$(repo gi-ignored)
  printf 'node_modules/\n*.local.md' > "$d/.gitignore"
  cp "$d/.gitignore" "$work/gi-before"
  input "$d"
  run gitignore task-work add
  expect "gitignore: ignored already, only .worktreeinclude" "- Added .lorvel/*.local.md to .worktreeinclude at the root of the repository.
- git ignores .lorvel/task-work.local.md.
- .worktreeinclude lists it, so a new worktree of this repository gets a copy."
  is "gitignore: an ignoring .gitignore is left as it was" cmp -s "$work/gi-before" "$d/.gitignore"

  d=$(repo gi-newline)
  printf 'dist' > "$d/.gitignore"
  printf '*.local.md' > "$d/.worktreeinclude"
  input "$d"
  run gitignore task-work add
  expect "gitignore: a broader .worktreeinclude pattern counts" "- Added .lorvel/*.local.md to .gitignore in the session folder.
- git ignores .lorvel/task-work.local.md.
- .worktreeinclude lists it, so a new worktree of this repository gets a copy."
  is "gitignore: the last line is ended before adding" [ "$(cat "$d/.gitignore")" = "dist$nl.lorvel/*.local.md" ]
  is "gitignore: a covering .worktreeinclude is left as it was" [ "$(cat "$d/.worktreeinclude")" = '*.local.md' ]

  # Claude Code copies into a new worktree only the files git ignores.
  d=$(repo gi-listed-not-ignored)
  printf '*.local.md\n' > "$d/.worktreeinclude"
  input "$d"
  run gitignore task-work
  expect "gitignore: listed but not ignored" "- git does not ignore .lorvel/task-work.local.md: committing the folder would commit it.
- .worktreeinclude lists it, but a new worktree gets only files git ignores, so while git does not ignore it, a new worktree starts without it."

  d=$(repo gi-sub)
  mkdir -p "$d/packages/app"
  input "$d/packages/app"
  run gitignore task-work add
  expect "gitignore: a session folder inside the repository" "- Added .lorvel/*.local.md to .gitignore in the session folder.
- Added packages/app/.lorvel/*.local.md to .worktreeinclude at the root of the repository.
- git ignores .lorvel/task-work.local.md.
- .worktreeinclude lists it, so a new worktree of this repository gets a copy."
  is "gitignore: .gitignore in the session folder" [ "$(cat "$d/packages/app/.gitignore")" = '.lorvel/*.local.md' ]
  is "gitignore: none at the root" absent "$d/.gitignore"
  is "gitignore: .worktreeinclude at the root" [ "$(cat "$d/.worktreeinclude")" = 'packages/app/.lorvel/*.local.md' ]

  d=$(repo gi-space)
  mkdir -p "$d/my app"
  input "$d/my app"
  run gitignore task-work add
  expect "gitignore: a path a pattern would have to escape" "- Added .lorvel/*.local.md to .gitignore in the session folder.
- .worktreeinclude was not changed: the session folder's path in the repository has characters a pattern would have to escape, so the line for its .lorvel/*.local.md is for the user to add by hand.
- git ignores .lorvel/task-work.local.md.
- .worktreeinclude does not list it, so a new worktree of this repository starts without it."
  is "gitignore: no .worktreeinclude made" absent "$d/.worktreeinclude"

  # A path git would read as pathspec magic, twice: one line, and the right answer.
  d=$(repo gi-colon)
  mkdir -p "$d/:app"
  input "$d/:app"
  run gitignore task-work add
  has "gitignore: a path starting with a colon is checked as a path" "- git ignores .lorvel/task-work.local.md."
  input "$d/:app"
  run gitignore task-work add
  is "gitignore: a path starting with a colon gets one line" [ "$(cat "$d/:app/.gitignore")" = '.lorvel/*.local.md' ]

  # The scratch repository that reads .worktreeinclude takes no template, whatever git would use.
  d=$(repo gi-template)
  printf '.env\n' > "$d/.worktreeinclude"
  printf '.lorvel/*.local.md\n' > "$d/.gitignore"
  mkdir -p "$work/template/info"
  printf '*.md\n' > "$work/template/info/exclude"
  export GIT_TEMPLATE_DIR="$work/template"
  input "$d"
  run gitignore task-work
  unset GIT_TEMPLATE_DIR
  has "gitignore: no template decides for .worktreeinclude" "- .worktreeinclude does not list it, so a new worktree of this repository starts without it."

  # A linked worktree: Claude Code copies from the main one, so .worktreeinclude is left alone.
  d=$(repo gi-main)
  git -C "$d" -c user.email=t@example.com -c user.name=t commit -q --allow-empty -m init > /dev/null 2>&1
  git -C "$d" worktree add -q "$d/wt" -b wt > /dev/null 2>&1
  input "$d/wt"
  run gitignore task-work add
  expect "gitignore: a linked worktree" "- Added .lorvel/*.local.md to .gitignore in the session folder.
- git ignores .lorvel/task-work.local.md.
- The session folder is in a linked worktree. Claude Code copies files into a new worktree from the main one, not from here, so this file reaches no new worktree; .worktreeinclude is not changed from here."
  is "gitignore: a linked worktree, no .worktreeinclude anywhere" absent "$d/wt/.worktreeinclude" "$d/.worktreeinclude"

  d=$(repo gi-tracked)
  mkdir -p "$d/.lorvel"
  printf -- '---\nschema: 1\n---\n' > "$d/.lorvel/task-work.local.md"
  git -C "$d" add .lorvel/task-work.local.md
  input "$d"
  run gitignore task-work add
  expect "gitignore: tracked already" "- .lorvel/task-work.local.md is tracked by git, so no ignore rule keeps it out of commits, and every worktree gets it from the commit; untracking it (git rm --cached) is the user's call."
  is "gitignore: tracked, nothing added" absent "$d/.gitignore" "$d/.worktreeinclude"

  d=$(repo gi-link)
  printf 'x\n' > "$work/gi-target"
  ln -s "$work/gi-target" "$d/.gitignore"
  input "$d"
  run gitignore task-work add
  is "gitignore: a linked .gitignore is not written through" [ "$(cat "$work/gi-target")" = x ]
  is "gitignore: and says so" [ "$(printf '%s\n' "$got" | head -n 1)" = "- .gitignore was not changed: in the session folder it is a symbolic link, which git does not read. A real .gitignore there, holding the line .lorvel/*.local.md, is for the user to make." ]

  # A shared file git ignores never reaches the team through a commit: write says so.
  d=$(repo gi-shared-ignored)
  printf '.lorvel/\n' > "$d/.gitignore"
  input "$d" "$DRAFT"
  run write task-work shared new
  is "write: a shared file git ignores is said to be" [ "$(printf '%s\n' "$got" | tail -n 1)" = "- git ignores .lorvel/task-work.md here, so a commit leaves it out, and the team does not get it while that rule stands." ]
  d=$(repo gi-shared-kept)
  input "$d" "$DRAFT"
  run write task-work shared new
  is "write: a shared file git keeps gets no such line" [ "$(printf '%s\n' "$got" | grep -c '^- git ignores')" = 0 ]
else
  echo "git is not installed: the gitignore cases were skipped"
fi

# Every scratch folder the script made is gone.
is "no scratch folder is left behind" [ -z "$(ls -A "$TMPDIR")" ]

echo "customize tests: $pass passed, $fail failed"
[ "$fail" = 0 ]
