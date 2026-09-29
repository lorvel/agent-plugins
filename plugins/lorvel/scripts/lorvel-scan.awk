# Reads the output of `od -An -v -tx1 -N <limit + 1> <file>` for one .lorvel/ file, with `limit`
# (the most bytes allowed) and `nonempty` (1 when the file has any bytes) set, and prints one line:
# OK, or BAD <reason>. Working on the byte dump keeps the check the same whatever locale and awk a
# machine has. It refuses what a reader cannot see but a model still reads: text that is not
# UTF-8, control characters, and the zero-width, bidirectional, filler, tag and variation-selector
# characters used to hide instructions in plain sight.

function bad(why) {
  print "BAD " why " (line " line ")"
  done = 1
  exit
}

function check(cp, first) {
  inv = "it contains an invisible or control character"
  if (cp < 32 && cp != 9 && cp != 10 && cp != 13) bad(inv)
  if (cp >= 127 && cp <= 159) bad(inv)
  if (cp == 173 || cp == 847 || cp == 1564 || cp == 4447 || cp == 4448) bad(inv)
  if (cp == 6068 || cp == 6069 || cp == 10240 || cp == 12644 || cp == 65440) bad(inv)
  if (cp >= 6155 && cp <= 6159) bad(inv)
  if (cp >= 8203 && cp <= 8207) bad(inv)
  if (cp >= 8232 && cp <= 8238) bad(inv)
  if (cp >= 8288 && cp <= 8303) bad(inv)
  if (cp >= 65520 && cp <= 65531) bad(inv)
  if (cp == 65279 && !first) bad(inv)
  if (cp >= 65024 && cp <= 65037) bad(inv)
  if ((cp == 65038 || cp == 65039) && prev_vs) bad(inv)
  if (cp >= 113824 && cp <= 113827) bad(inv)
  if (cp >= 119155 && cp <= 119162) bad(inv)
  if (cp >= 917504 && cp <= 921599) bad(inv)
  prev_vs = (cp >= 65024 && cp <= 65039)
}

BEGIN {
  for (i = 0; i < 256; i++) hex[sprintf("%02x", i)] = i
  line = 1
  utf = "it is not valid UTF-8 text"
}

{
  for (i = 1; i <= NF; i++) {
    if (!($i in hex)) bad(utf)
    b = hex[$i]
    pos++
    if (pos > limit) continue
    if (need > 0) {
      if (b < 128 || b > 191) bad(utf)
      cp = cp * 64 + b - 128
      need--
      if (need == 0) {
        if (cp < min || (cp >= 55296 && cp <= 57343) || cp > 1114111) bad(utf)
        check(cp, start == 1)
      }
      continue
    }
    start = pos
    if (b < 128) {
      if (b >= 32 && b != 127) {
        prev_vs = 0
        continue
      }
      check(b, 0)
      if (b == 10) line++
      continue
    }
    if (b >= 194 && b <= 223) { cp = b - 192; need = 1; min = 128 }
    else if (b >= 224 && b <= 239) { cp = b - 224; need = 2; min = 2048 }
    else if (b >= 240 && b <= 244) { cp = b - 240; need = 3; min = 65536 }
    else bad(utf)
  }
}

END {
  if (done) exit
  if (pos > limit) { print "BAD it is larger than 64 KiB"; exit }
  if (nonempty && pos == 0) { print "BAD it cannot be read"; exit }
  if (need > 0) { print "BAD " utf " (line " line ")"; exit }
  print "OK"
}
