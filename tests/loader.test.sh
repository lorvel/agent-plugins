#!/bin/sh
# Tests for plugins/lorvel/scripts/lorvel-load, the loader that reads .lorvel/ customisations.
# Run from anywhere: sh tests/loader.test.sh
#
# Every case checks the exit status (always 0) and the exact output, and every case that refuses
# something also checks that a marker written into the file never reaches the output.

set -u
root=$(cd "$(dirname "$0")/.." && pwd) || exit 1
work=$(mktemp -d "${TMPDIR:-/tmp}/lorvel-load-test.XXXXXX") || exit 1
[ -d "$work" ] || exit 1
cleanup() { chmod -R u+rwx "$work" 2>/dev/null; rm -rf "$work"; }
trap cleanup EXIT
trap 'cleanup; exit 130' INT
trap 'cleanup; exit 143' TERM

H='Customisation from .lorvel/, checked by the lorvel plugin:'
N='No customisation from .lorvel/ for this command.'
OFF='Customisation from .lorvel/ is off for this run:'
nl='
'
pass=0
fail=0
L=$root/plugins/lorvel/scripts/lorvel-load   # the loader under test
IN=/dev/null                                 # its standard input

# run_loader <args...> — runs $L with $IN as input and sets `got` and `rc`. A loader still running
# after 10 seconds is killed with everything it started, so a change that makes it block on some
# file fails this suite instead of hanging it.
killtree() {
  for c in $(pgrep -P "$1" 2>/dev/null); do killtree "$c"; done
  kill -9 "$1" 2>/dev/null
}
run_loader() {
  "$L" "$@" < "$IN" > "$work/out" 2>&1 &
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

# check <case> <expected output> <args...> — and MARK, when set, a string that must not reach the
# output.
MARK=''
check() {
  name=$1 want=$2
  shift 2
  run_loader "$@"
  ok=1
  [ "$rc" = 0 ] || { ok=0; echo "FAIL $name: exit $rc"; }
  [ "$got" = "$want" ] || { ok=0; printf 'FAIL %s\n--- want\n%s\n--- got\n%s\n---\n' "$name" "$want" "$got"; }
  if [ -n "$MARK" ]; then
    case $got in *"$MARK"*) ok=0; echo "FAIL $name: the marker reached the output" ;; esac
  fi
  if [ "$ok" = 1 ]; then pass=$((pass + 1)); else fail=$((fail + 1)); fi
  MARK=''
}

# folder <name> — a fresh session folder with an empty .lorvel/
folder() {
  d=$work/$1
  mkdir -p "$d/.lorvel"
  printf '%s' "$d"
}

# one <case> <file content as a printf format> <expected lines after the header> [file name]
# — writes one file (task-work.md unless named) and checks what the loader says about it.
one() {
  d=$(folder "$1")
  printf -- "$2" > "$d/.lorvel/${4:-task-work.md}"
  check "$1" "$H$nl$3" task-work "$d"
}

# value <case> <review value> <expected lines after the header> — a file whose only setting is
# `review: <value>`; the value must not reach the output unless it was accepted.
value() {
  d=$(folder "$1")
  printf -- '---\nreview: %s\n---\n' "$2" > "$d/.lorvel/task-work.md"
  case $3 in *"$2"*) ;; *) MARK=$2 ;; esac
  check "$1" "$H$nl$3" task-work "$d"
}

# refused <case> <file content as a printf format> <reason> — the file is refused as a whole, and
# the marker it carries never reaches the output.
refused() {
  MARK=MARKER_REFUSED
  one "$1" "$2" "- Not applied: all of .lorvel/task-work.md — $3"
}

# --- nothing to read: one fixed line ------------------------------------------------------------
# Claude Code shows a `!` command with no output as "(Bash completed with no output)", so the
# loader never prints nothing.

d=$work/no-lorvel; mkdir -p "$d"
check no-lorvel-folder "$N" task-work "$d"
check no-lorvel-folder-create "$N" task-create "$d"
d=$(folder other-command-only); printf -- '---\nreview: code-review\n---\n' > "$d/.lorvel/task-create.md"
check only-another-commands-file "$N" task-work "$d"
d=$(folder lorvel-is-a-file); rmdir "$d/.lorvel"; printf 'x\n' > "$d/.lorvel"
check lorvel-is-a-file "$N" task-work "$d"
d=$(folder other-case); printf -- '---\nreview: MARKER_CASE\n---\n' > "$d/.lorvel/Task-Work.md"
MARK=MARKER_CASE; check name-must-match-exactly "$N" task-work "$d"
d=$(folder other-case-beside-exact)
printf -- '---\nreview: code-review\n---\n' > "$d/.lorvel/task-work.md"
printf -- '---\nreview: MARKER_CASE\n---\n' > "$d/.lorvel/Task-Work.local.md"
MARK=MARKER_CASE; check name-must-match-exactly-beside-exact "$H$nl- review: code-review — from .lorvel/task-work.md" task-work "$d"

# --- the two layers ----------------------------------------------------------------------------

one team-review '---\nschema: 1\nskill: task-work\nreview: code-review xhigh --fix\n---\n' \
  '- review: code-review xhigh --fix — from .lorvel/task-work.md'

d=$(folder personal-wins)
printf -- '---\nreview: code-review xhigh --fix\n---\n' > "$d/.lorvel/task-work.md"
printf -- '---\nreview: "pr-review-toolkit:review-pr all"\n---\n' > "$d/.lorvel/task-work.local.md"
check personal-wins "$H$nl- review: pr-review-toolkit:review-pr all — from .lorvel/task-work.local.md, which replaces the one in .lorvel/task-work.md" task-work "$d"

SHAPE='it must be a skill name, then plain arguments, at most 200 characters'
d=$(folder personal-bad-review-keeps-team)
printf -- '---\nreview: code-review\n---\n' > "$d/.lorvel/task-work.md"
printf -- "---\nreview: 'x; rm -rf /'\n---\n" > "$d/.lorvel/task-work.local.md"
check personal-bad-review-keeps-team "$H$nl- review: code-review — from .lorvel/task-work.md$nl- Not applied: review in .lorvel/task-work.local.md — $SHAPE" task-work "$d"

one personal-only '---\nreview: my-review\n---\n' '- review: my-review — from .lorvel/task-work.local.md' task-work.local.md

d=$(folder team-refused-personal-applies)
printf -- '---\nschema: 2\nreview: MARKER_TEAM\n---\n' > "$d/.lorvel/task-work.md"
printf -- '---\nreview: my-review\n---\n' > "$d/.lorvel/task-work.local.md"
MARK=MARKER_TEAM; check team-refused-personal-applies "$H$nl- review: my-review — from .lorvel/task-work.local.md$nl- Not applied: all of .lorvel/task-work.md — it is written for another schema; this version reads schema 1" task-work "$d"

# --- flag defaults only tighten ----------------------------------------------------------------

S2='- STOP-2 on by default — defaults.plan: true in'
S2END='; typing --no-plan turns it off for one run'
LOOSEN='a file can only turn STOP-2 on; typing --no-plan turns it off for one run'
one plan-team '---\ndefaults:\n  plan: true\n---\n' "$S2 .lorvel/task-work.md$S2END"
one plan-personal '---\ndefaults:\n    plan: True # tighten\n---\n' "$S2 .lorvel/task-work.local.md$S2END" task-work.local.md

d=$(folder plan-both)
printf -- '---\ndefaults:\n  plan: true\n---\n' > "$d/.lorvel/task-work.md"
printf -- '---\ndefaults:\n  plan: true\n---\n' > "$d/.lorvel/task-work.local.md"
check plan-both "$H$nl$S2 .lorvel/task-work.md and .lorvel/task-work.local.md$S2END" task-work "$d"

d=$(folder plan-false-kept-team)
printf -- '---\ndefaults:\n  plan: true\n---\n' > "$d/.lorvel/task-work.md"
printf -- '---\nreview: code-review\ndefaults:\n  plan: false\n---\n' > "$d/.lorvel/task-work.local.md"
check plan-false-kept-team "$H$nl- review: code-review — from .lorvel/task-work.local.md$nl$S2 .lorvel/task-work.md$S2END$nl- Not applied: defaults.plan in .lorvel/task-work.local.md — $LOOSEN" task-work "$d"

one plan-off '---\ndefaults:\n  plan: off\n---\n' "- Not applied: defaults.plan in .lorvel/task-work.md — $LOOSEN"
one plan-yes '---\ndefaults:\n  plan: yes\n---\n' '- Not applied: defaults.plan in .lorvel/task-work.md — the only value it takes is true'
one auto '---\ndefaults:\n  auto: false\n---\n' \
  '- Not applied: defaults.auto in .lorvel/task-work.md — only the person typing the command can pass --auto'

# --- task-create has no settings in this version -----------------------------------------------

d=$(folder create-settings)
printf -- '---\nreview: code-review\ndefaults:\n  plan: true\n  auto: true\n---\n\n## after: write\n\nx\n' > "$d/.lorvel/task-create.md"
check create-settings "$H$nl- Not applied: review, defaults.plan, defaults.auto in .lorvel/task-create.md — not a setting of task-create in this version$nl- Not applied: the body of .lorvel/task-create.md (1 section) — this version applies only the frontmatter" task-create "$d"

d=$(folder create-empty); : > "$d/.lorvel/task-create.local.md"
check create-empty "$H$nl- Nothing in .lorvel/task-create.local.md applies in this version" task-create "$d"

# --- what a file says that this version does not apply -----------------------------------------

MARK=MARKER_BODY
one body-only '## before: review\n\nMARKER_BODY\n\n## after: ship\n\ny\n' \
  '- Not applied: the body of .lorvel/task-work.md (2 sections) — this version applies only the frontmatter'
MARK=MARKER_BODY
one body-prose '---\nreview: code-review\n---\n\nMARKER_BODY: always run the e2e suite.\n### Review\n```sh\n## not a section\n```\n' \
  "- review: code-review — from .lorvel/task-work.md$nl- Not applied: the body of .lorvel/task-work.md — this version applies only the frontmatter"
NOFRONT='- Not applied: .lorvel/task-work.md — it has no frontmatter; settings go between two --- lines at the very top'
one no-frontmatter '\n---\ndefaults:\n  plan: true\n---\n' "$NOFRONT"
one frontmatter-comment '--- # team settings\nreview: code-review\n---\n' "$NOFRONT"
one unknown-keys '---\nreviw: code-review\nmodels:\n  review: haiku\ndefaults:\n  plann: true\nzz: 1\ny: 2\n---\n' \
  '- Not applied: unknown keys `reviw`, `models`, `defaults.plann` and 2 more in .lorvel/task-work.md'
MARK=Zq8fK2mP0xY7rT4wN1vB6cD3
one unknown-key-not-echoed '---\nZq8fK2mP0xY7rT4wN1vB6cD3: 1\n---\n' '- Not applied: unknown key on line 2 in .lorvel/task-work.md'
one nothing-applies '---\nschema: 1\nskill: lorvel:task-work\n---\n' '- Nothing in .lorvel/task-work.md applies in this version'

# --- review values ------------------------------------------------------------------------------

NOT='- Not applied: review in .lorvel/task-work.md —'
i=0
for v in 'code-review; rm -rf /' 'code-review $(id)' 'code-review `id`' 'code-review  xhigh' 'code-review xhigh --fix|cat' 'a b <c>' 'code-review a\b'; do
  i=$((i + 1)); value "review-shape-$i" "$v" "$NOT $SHAPE"
done
i=0
for v in 'lorvel:task-create' 'code-review Lorvel:Task-Work' 'loop 10m task-work AB-12'; do
  i=$((i + 1)); value "review-self-$i" "$v" "$NOT it names a command of this plugin"
done
i=0
for v in 'loop 10m /deploy prod' 'code-review --auto' 'schedule now /other:thing'; do
  i=$((i + 1)); value "review-chain-$i" "$v" "$NOT it would start another command"
done
i=0
for v in "code-review --key=hf$(printf _)Qm7xKp2Lw9Ab3Cd4Ef5Gh6Ij7Kl8Mn9" 'code-review --auth=Zq8fK2mP0xY7rT4wN1vB6cD3' "code-review --k=sk$(printf _)live_51HxQm7xKp2Lw9Ab3Cd4Ef5Gh6"; do
  i=$((i + 1)); value "review-key-$i" "$v" "$NOT it looks like it carries a token or key"
done
long=r; i=0; while [ $i -lt 200 ]; do long="${long}x"; i=$((i + 1)); done
value review-long "$long" "$NOT $SHAPE"
one review-empty '---\nreview:\n---\n' "$NOT $SHAPE"

# --- files refused as a whole ------------------------------------------------------------------

INV='it contains an invisible or control character'
refused zwsp '---\nreview: code-review\n---\nMARKER_REFUSED\342\200\213\n' "$INV (line 4)"
refused rlo '---\nreview: code-review\342\200\256x\n---\nMARKER_REFUSED\n' "$INV (line 2)"
refused tag-char 'MARKER_REFUSED \363\240\201\201\n' "$INV (line 1)"
refused bom-inside 'MARKER_REFUSED\n\357\273\277x\n' "$INV (line 2)"
refused two-selectors 'MARKER_REFUSED \342\235\244\357\270\217\357\270\217\n' "$INV (line 1)"
refused selector-1 'MARKER_REFUSED a\357\270\200\n' "$INV (line 1)"
refused mongolian-selector 'MARKER_REFUSED a\341\240\213\n' "$INV (line 1)"
refused specials-fff0 'MARKER_REFUSED a\357\277\260\n' "$INV (line 1)"
refused shorthand-format 'MARKER_REFUSED a\360\233\262\240\n' "$INV (line 1)"
refused hangul-filler 'MARKER_REFUSED \343\205\244\n' "$INV (line 1)"
refused escape 'MARKER_REFUSED \033[31m\n' "$INV (line 1)"
refused nul 'MARKER_REFUSED \000\n' "$INV (line 1)"
refused c1 'MARKER_REFUSED \302\205\n' "$INV (line 1)"
refused bad-utf8 'MARKER_REFUSED \377\n' 'it is not valid UTF-8 text (line 1)'
refused overlong 'MARKER_REFUSED \300\257\n' 'it is not valid UTF-8 text (line 1)'
refused truncated 'MARKER_REFUSED \342\200' 'it is not valid UTF-8 text (line 1)'
refused surrogate 'MARKER_REFUSED \355\240\200\n' 'it is not valid UTF-8 text (line 1)'

# Token-shaped strings are put together at run time, so that this file holds none a secret scanner
# would stop at a push.
j() { printf '%s%s' "$1" "$2"; }
TOK='looks like a token or key'
for t in "$(j lv '_0123456789abcdefghijklmnop')" "$(j lvo '_at_0123456789abcdefghijk')" \
  "$(j gh 'p_0123456789abcdefghijklmnopqrstuvwxyz')" "$(j github '_pat_0123456789abcdefghijklmnopqrstuv')" \
  "$(j glpat '-0123456789abcdefghij')" "$(j xo 'xb-0123456789-abcdef')" "$(j sk '-ant-api03-0123456789abcdefghij')" \
  "$(j AK 'IA0123456789ABCDEF')" "$(j AI 'za0123456789abcdefghijklmnopqrstuvwxy')" \
  "$(j npm '_0123456789abcdefghijklmnopqrstuvwxyzAB')" "$(j eyJhbGciOiJIUzI1NiJ9. 'eyJzdWIiOiIxMjM0In0.abc')" \
  "$(j 'Authorization: Bear' 'er 0123456789abcdefghijklmn')" "$(j api '_key = "0123456789abcdef0123"')" \
  "$(j PASS 'WORD: correct-horse-battery-staple')"; do
  d=$(folder "token-$pass-$fail")
  printf -- '---\nreview: code-review\n---\nMARKER_REFUSED\n\nsee %s here\n' "$t" > "$d/.lorvel/task-work.md"
  MARK=$t; check "token $t" "$H$nl- Not applied: all of .lorvel/task-work.md — line 6 $TOK" task-work "$d"
done
# At the very start of a line too, where nothing stands before the prefix.
key=$(j AK 'IA0123456789ABCDEF')
for t in "$key: 1" "$key"; do
  d=$(folder "token-line-start-$pass-$fail")
  printf -- '---\n%s\n---\n' "$t" > "$d/.lorvel/task-work.md"
  MARK=$key; check "token at line start: $t" "$H$nl- Not applied: all of .lorvel/task-work.md — line 2 $TOK" task-work "$d"
done
# A short match just before a real token must not hide it.
d=$(folder token-overlap)
printf -- '---\nreview: code-review\n---\nx.eyJ0.%s\n' "$(j eyJhbGciOiJIUzI1NiJ9. 'eyJzdWIiOiIxMjM0NTY3ODkwIn0.sig')" > "$d/.lorvel/task-work.md"
check token-overlap "$H$nl- Not applied: all of .lorvel/task-work.md — line 4 $TOK" task-work "$d"
d=$(folder private-key); printf -- '%s KEY-----\nMARKER_REFUSED\n' '-----BEGIN OPENSSH PRIVATE' > "$d/.lorvel/task-work.md"
MARK=MARKER_REFUSED; check private-key "$H$nl- Not applied: all of .lorvel/task-work.md — line 1 $TOK" task-work "$d"

NU='its frontmatter is not understood'
refused list '---\nreview:\n  - code-review\n---\nMARKER_REFUSED\n' "$NU (line 3)"
refused flow-map '---\ndefaults: {plan: true}\n---\nMARKER_REFUSED\n' "$NU (line 2)"
refused tab-indent '---\ndefaults:\n\tplan: true\n---\nMARKER_REFUSED\n' "$NU (line 3)"
refused mixed-indent '---\ndefaults:\n  plan: true\n    auto: true\n---\nMARKER_REFUSED\n' "$NU (line 4)"
refused mapping-in-value '---\nreview: code-review: xhigh\n---\nMARKER_REFUSED\n' "$NU (line 2)"
refused repeated-key '---\nreview: a\nreview: b\n---\nMARKER_REFUSED\n' "$NU (line 3)"
refused open-quote '---\nreview: "code-review\n---\nMARKER_REFUSED\n' "$NU (line 2)"
refused no-colon-space '---\nreview:code-review\n---\nMARKER_REFUSED\n' "$NU (line 2)"
refused anchor '---\nreview: &a code-review\n---\nMARKER_REFUSED\n' "$NU (line 2)"
refused defaults-scalar '---\ndefaults: true\n---\nMARKER_REFUSED\n' "$NU (line 2)"
refused empty-skill '---\nskill:\nreview: code-review\n---\nMARKER_REFUSED\n' "$NU (line 2)"
refused unclosed '---\nreview: code-review\nMARKER_REFUSED\n' 'its frontmatter has no closing --- line'
refused other-skill '---\nskill: task-create\nreview: code-review\n---\nMARKER_REFUSED\n' 'its skill: line names another command'
refused other-schema '---\nschema: 2\nreview: code-review\n---\nMARKER_REFUSED\n' 'it is written for another schema; this version reads schema 1'
refused other-schema-new-syntax '---\nschema: 2\nreview:\n  - code-review\n---\nMARKER_REFUSED\n' 'it is written for another schema; this version reads schema 1'

d=$(folder big)
i=0; : > "$d/.lorvel/task-work.md"
while [ $i -lt 1100 ]; do printf 'MARKER_REFUSED %s\n' 0123456789012345678901234567890123456789012345 >> "$d/.lorvel/task-work.md"; i=$((i + 1)); done
MARK=MARKER_REFUSED; check big "$H$nl- Not applied: all of .lorvel/task-work.md — it is larger than 64 KiB" task-work "$d"
# The size comes from the bytes read, not from `ls`, whose size column GNU ls rescales on request.
BLOCK_SIZE=1K; LS_BLOCK_SIZE=1K; export BLOCK_SIZE LS_BLOCK_SIZE
MARK=MARKER_REFUSED; check big-with-block-size "$H$nl- Not applied: all of .lorvel/task-work.md — it is larger than 64 KiB" task-work "$d"
unset BLOCK_SIZE LS_BLOCK_SIZE

d=$(folder file-link); printf 'MARKER_REFUSED\n' > "$work/elsewhere.md"; ln -s "$work/elsewhere.md" "$d/.lorvel/task-work.md"
MARK=MARKER_REFUSED; check file-link "$H$nl- Not applied: all of .lorvel/task-work.md — it is a symbolic link" task-work "$d"
d=$(folder dangling-link); ln -s "$work/nowhere.md" "$d/.lorvel/task-work.md"
check dangling-link "$H$nl- Not applied: all of .lorvel/task-work.md — it is a symbolic link" task-work "$d"
d=$work/folder-link; mkdir -p "$d" "$work/shared/.lorvel-target"; printf 'MARKER_REFUSED\n' > "$work/shared/.lorvel-target/task-work.md"
ln -s "$work/shared/.lorvel-target" "$d/.lorvel"
MARK=MARKER_REFUSED; check folder-link "$H$nl- Not applied: .lorvel/ — it is a symbolic link, and only a real folder in the session folder is read" task-work "$d"
d=$(folder directory); mkdir "$d/.lorvel/task-work.md"
check directory "$H$nl- Not applied: all of .lorvel/task-work.md — it is not a regular file" task-work "$d"
if command -v mkfifo >/dev/null 2>&1; then
  d=$(folder fifo); mkfifo "$d/.lorvel/task-work.md"
  check fifo "$H$nl- Not applied: all of .lorvel/task-work.md — it is not a regular file" task-work "$d"
fi
if [ "$(id -u)" != 0 ]; then
  d=$(folder unreadable); printf 'MARKER_REFUSED\n' > "$d/.lorvel/task-work.md"; chmod 000 "$d/.lorvel/task-work.md"
  MARK=MARKER_REFUSED; check unreadable "$H$nl- Not applied: all of .lorvel/task-work.md — it cannot be read" task-work "$d"
  for mode in 000 600; do
    d=$(folder "unreadable-folder-$mode"); printf 'MARKER_REFUSED\n' > "$d/.lorvel/task-work.md"; chmod "$mode" "$d/.lorvel"
    MARK=MARKER_REFUSED; check "unreadable-folder-$mode" "$H$nl- Not applied: .lorvel/ — the folder cannot be read" task-work "$d"
  done
fi

# --- what is allowed through -----------------------------------------------------------------

one allowed '\357\273\277---\r\nreview: code-review\r\n---\r\nN\303\272t L\306\260u \342\235\244\357\270\217 non\302\240breaking, task-create-something-long, sk-learn, the token: short\r\n' \
  "- review: code-review — from .lorvel/task-work.md$nl- Not applied: the body of .lorvel/task-work.md — this version applies only the frontmatter"

# --- only the session folder, never its parent or a child --------------------------------------

d=$work/parent-proj; mkdir -p "$d/.lorvel" "$d/sub"; printf -- '---\nreview: MARKER_PARENT\n---\n' > "$d/.lorvel/task-work.md"
MARK=MARKER_PARENT; check parent-not-read "$N" task-work "$d/sub"
d=$work/child-proj; mkdir -p "$d/sub/.lorvel"; printf -- '---\nreview: MARKER_CHILD\n---\n' > "$d/sub/.lorvel/task-work.md"
MARK=MARKER_CHILD; check child-not-read "$N" task-work "$d"
# With a file of its own in the session folder too, so the loader gets past its first check.
d=$work/both; mkdir -p "$d/.lorvel" "$d/proj/.lorvel" "$d/proj/sub/.lorvel"
printf -- '---\nreview: MARKER_PARENT\ndefaults:\n  plan: true\n---\n' > "$d/.lorvel/task-work.md"
printf -- '---\nreview: MARKER_CHILD\n---\n' > "$d/proj/sub/.lorvel/task-work.local.md"
printf -- '---\nreview: own-review\n---\n' > "$d/proj/.lorvel/task-work.md"
MARK=MARKER_; check parent-and-child-beside-own "$H$nl- review: own-review — from .lorvel/task-work.md" task-work "$d/proj"

# --- how the folder arrives ----------------------------------------------------------------------

d=$(folder stdin); printf -- '---\nreview: code-review\n---\n' > "$d/.lorvel/task-work.md"
printf '%s\n' "$d" > "$work/in"
IN=$work/in; check folder-on-stdin "$H$nl- review: code-review — from .lorvel/task-work.md" task-work; IN=/dev/null
printf '%s\n%s\n' "$work/stdin" "sub" > "$work/in"
IN=$work/in; check folder-with-line-break "$OFF the name of the folder this session was opened in has a line break in it, so nothing in .lorvel/ was read." task-work; IN=/dev/null
d=$work/"with space and it's \$HOME \`x\`"; mkdir -p "$d/.lorvel"; printf -- '---\nreview: code-review\n---\n' > "$d/.lorvel/task-work.md"
check odd-folder-name "$H$nl- review: code-review — from .lorvel/task-work.md" task-work "$d"
check no-folder "$OFF the loader was not told which folder this session was opened in, so nothing in .lorvel/ was read." task-work
check unknown-command "$OFF the loader was called for a command it does not know, so nothing in .lorvel/ was read." task-custom "$d"

# --- a broken loader never breaks the command ------------------------------------------------

FAILED="$OFF the loader failed, so nothing in .lorvel/ was applied."
broken=$work/broken-plugin
reset_broken() { rm -rf "$broken"; mkdir -p "$broken"; cp "$root"/plugins/lorvel/scripts/* "$broken"/; }
d=$(folder broken); printf -- '---\nreview: MARKER_BROKEN\n---\n' > "$d/.lorvel/task-work.md"
d2=$work/broken-no-lorvel; mkdir -p "$d2"
L=$broken/lorvel-load
reset_broken; printf 'exit 3\n' > "$broken/lorvel-load.sh"
MARK=MARKER_BROKEN; check core-exits-3 "$FAILED" task-work "$d"
check broken-but-no-lorvel "$N" task-work "$d2"
reset_broken; printf 'echo MARKER_BROKEN; if then\n' > "$broken/lorvel-load.sh"
MARK=MARKER_BROKEN; check core-syntax-error "$FAILED" task-work "$d"
reset_broken; rm -f "$broken/lorvel-load.sh"
MARK=MARKER_BROKEN; check core-missing "$FAILED" task-work "$d"
reset_broken; : > "$broken/lorvel-load.sh"
MARK=MARKER_BROKEN; check core-empty "$FAILED" task-work "$d"
reset_broken; printf 'BEGIN { print "MARKER_BROKEN" }\n' > "$broken/lorvel-read.awk"
MARK=MARKER_BROKEN; check reader-prints-junk "$FAILED" task-work "$d"
reset_broken; : > "$broken/lorvel-read.awk"
MARK=MARKER_BROKEN; check reader-empty "$FAILED" task-work "$d"
reset_broken; printf 'echo "- review: fine"\ncat "$2/.lorvel/task-work.md"\n' > "$broken/lorvel-load.sh"
MARK=MARKER_BROKEN; check core-leaks-the-file "$FAILED" task-work "$d"
# No od on PATH: the scan must fail closed, not read an empty dump as a clean file.
reset_broken; mkdir "$broken/bin"
tools=yes
for t in sh awk find dirname cat; do
  p=$(command -v "$t") || p=
  case $p in /*) ln -s "$p" "$broken/bin/$t" ;; *) tools=no ;; esac
done
d=$(folder no-od); printf -- '---\nreview: code-review\n---\nMARKER_BROKEN \342\200\256\n' > "$d/.lorvel/task-work.md"
# busybox sh runs its own od applet even when no od is on PATH, which makes this case impossible.
if [ "$tools" = yes ] && PATH=$broken/bin "$broken/bin/sh" -c 'command -v od' > /dev/null 2>&1; then
  tools=no
fi
if [ "$tools" = yes ]; then
  saved_path=$PATH; PATH=$broken/bin
  MARK=MARKER_BROKEN; check no-od-on-path "$FAILED" task-work "$d"
  PATH=$saved_path
else
  echo "skipped no-od-on-path: od cannot be taken away here (busybox applets)"
fi
L=$root/plugins/lorvel/scripts/lorvel-load

# --- the largest block the loader can print ------------------------------------------------------

d=$(folder largest)
v=code-review; i=0; while [ ${#v} -lt 190 ]; do v="$v --a$i"; i=$((i + 1)); done
while [ ${#v} -lt 199 ]; do v="${v}x"; done
for f in task-work.md task-work.local.md; do
  pl=true; rv=$v; [ $f = task-work.local.md ] && pl=false && rv=x$v
  printf -- '---\nreview: %s\ndefaults:\n  plan: %s\n  auto: true\naaaaaaaaaaaaaaaaaaaaaaaaaaaaaa: 1\nbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb: 1\ncccccccccccccccccccccccccccccc: 1\nd: 1\n---\n## a\n## b\n' "$rv" "$pl" > "$d/.lorvel/$f"
done
run_loader task-work "$d"
size=$(printf '%s\n' "$got" | wc -c | tr -d ' ')
echo "largest block: $size bytes, $(printf '%s\n' "$got" | wc -l | tr -d ' ') lines"
if [ "$rc" = 0 ] && [ "$size" -le 3000 ] && [ "$(printf '%s\n' "$got" | head -n 1)" = "$H" ]; then
  pass=$((pass + 1))
else
  fail=$((fail + 1)); echo "FAIL largest block: exit $rc, $size bytes"
fi

echo "loader tests: $pass passed, $fail failed"
[ "$fail" = 0 ]
