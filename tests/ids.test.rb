# encoding: utf-8
# Checks the step IDs each SKILL.md declares under metadata.lorvel.ids against the skill's own text,
# and how each command runs the .lorvel/ loader. See plugins/lorvel/ids.md.
# Run from anywhere: ruby tests/ids.test.rb

require "yaml"
require "open3"
require "tempfile"
Encoding.default_external = Encoding::UTF_8

PLUGIN = File.expand_path("../plugins/lorvel", __dir__)
MODES = %w[locked extend replace optional]
KINDS = %w[step gate rule]
# A skill edit never relaxes a locked ID (ids.md), so the locked set only grows.
LOCKED = {
  "task-work" => %w[STOP-1 STOP-2 STOP-3 missing-tools machine-gates no-undo close-on-evidence knowledge-audit no-secrets loader-only],
  "task-create" => %w[GATE-1 GATE-2 ask recheck no-one-to-ask no-secrets loader-only],
}
REPLACE = { "task-work" => [], "task-create" => %w[classify] }
LOADER_RULE = 'Bash("${CLAUDE_PLUGIN_ROOT}/scripts/lorvel-load" *)'
HEREDOC = "<<'LORVEL_SESSION_FOLDER'"
# The line the loader prints when there is nothing to apply; both skills quote it, and tell the
# model to say nothing about it.
NONE = File.read(File.join(PLUGIN, "scripts", "lorvel-load"))[/^none='([^']*)'$/, 1]

POINTER = {
  "task-work" => "**Sections from this run's customisation.** Look at the `<customisation>` block as each phase and gate in this file starts and ends, rather than trusting what you remember of the start of the run, and run its sections as its `Sections:` line says. No block in view ⇒ follow `customisation.md`, beside this file, first.",
  "task-create" => "**Sections from this run's customisation.** Look at the loader's output from step 1 as each step and gate in this file starts and ends, and run its sections as its `Sections:` line says. That output no longer in view ⇒ run the loader again, as `SKILL.md` says; refused ⇒ customisation is off for the rest of this run.",
}

$failures = 0
def fail(msg)
  $failures += 1
  puts "FAIL #{msg}"
end

# The ID list as scripts/lorvel-ids.awk reads it: [id, kind, mode, step label, gate steps, sources].
def awk_ids(skill_md)
  dump = Tempfile.new(["dump", ".awk"])
  dump.write(<<~'AWK')
    BEGIN {
      if (!load_ids(skillmd)) { print "LOAD FAILED"; exit 1 }
      for (i = 1; i <= ids_n; i++) {
        line = ids_id[i] "\t" ids_kind[i] "\t" ids_mode[i] "\t" (ids_kind[i] == "step" ? ids_label[i] : "") "\t" ids_in[i]
        for (k = 1; k <= ids_src_n[i]; k++) line = line "\t" ids_src[i, k]
        print line
      }
    }
  AWK
  dump.close
  out, status = Open3.capture2({"LC_ALL" => "C"}, "awk", "-v", "skillmd=#{skill_md}",
                               "-f", File.join(PLUGIN, "scripts", "lorvel-ids.awk"), "-f", dump.path)
  return [:failed, out] unless status.success?
  out.force_encoding("UTF-8").lines.map do |l|
    f = l.chomp.split("\t", -1)
    f[0, 5] + [f[5..] || []]
  end
ensure
  dump&.unlink
end

%w[task-work task-create].each do |skill|
  text = File.read(File.join(PLUGIN, "skills", skill, "SKILL.md"))
  m = text.match(/\A---\n(.*?)\n---\n/m) or (fail("#{skill}: no frontmatter"); next)
  front = YAML.safe_load(m[1])
  body = m.post_match
  refs = Dir[File.join(PLUGIN, "skills", skill, "reference", "*.md")].sort.map { |f| File.read(f) }
  lorvel = (front["metadata"] || {})["lorvel"] || {}
  fail("#{skill}: schema #{lorvel["schema"].inspect}") unless lorvel["schema"] == 1
  rows = lorvel["ids"]
  (fail("#{skill}: ids is not a list"); next) unless rows.is_a?(Array) && !rows.empty?

  ids = rows.map { |r| r["id"] }
  dup = ids.select { |i| ids.count(i) > 1 }.uniq
  fail("#{skill}: duplicate IDs #{dup}") unless dup.empty?
  steps = rows.select { |r| r["kind"] == "step" }.map { |r| r["id"] }
  rows.each do |r|
    miss = %w[id kind mode what] - r.keys
    fail("#{skill}: #{r["id"]} lacks #{miss}") unless miss.empty?
    fail("#{skill}: #{r["id"]} mode #{r["mode"]}") unless MODES.include?(r["mode"])
    fail("#{skill}: #{r["id"]} kind #{r["kind"]}") unless KINDS.include?(r["kind"])
    if r["kind"] == "gate"
      ins = r["in"]
      fail("#{skill}: gate #{r["id"]} has no `in`") unless ins.is_a?(Array) && !ins.empty?
      Array(ins).each { |s| fail("#{skill}: gate #{r["id"]} in unknown step #{s}") unless steps.include?(s) }
    elsif r.key?("in")
      fail("#{skill}: #{r["id"]} is not a gate but has `in`")
    end
    if r["kind"] == "rule"
      src = r["source"]
      if !src.is_a?(Array) || src.empty?
        fail("#{skill}: rule #{r["id"]} has no `source`")
      else
        src.each do |phrase|
          fail("#{skill}: rule #{r["id"]} source not in the skill: #{phrase.inspect}") unless ([body] + refs).any? { |t| t.include?(phrase) }
        end
      end
    elsif r.key?("source")
      fail("#{skill}: #{r["id"]} is not a rule but has `source`")
    end
  end

  word = skill == "task-work" ? "Phase" : "Step"
  numbers = rows.select { |r| r["kind"] == "step" }.map { |r| r["what"][/\A#{word} (\d) —/, 1] }
  fail("#{skill}: a step does not name its #{word.downcase}") if numbers.include?(nil)
  mapped = body.scan(/^\| \*\*(\d)\*\* /).flatten
  mapped.unshift("0") if skill == "task-work" && body.include?("## Phase 0 — Locate")
  fail("#{skill}: step map #{mapped} vs step IDs #{numbers}") unless numbers == mapped
  gates = body.scan(/^\| \*\*((?:STOP|GATE)-\d)\*\*/).flatten.sort
  gate_ids = rows.select { |r| r["kind"] == "gate" }.map { |r| r["id"] }.sort
  fail("#{skill}: gate table #{gates} vs gate IDs #{gate_ids}") unless gates == gate_ids

  locked = rows.select { |r| r["mode"] == "locked" }.map { |r| r["id"] }
  fail("#{skill}: no longer locked: #{LOCKED[skill] - locked}") unless (LOCKED[skill] - locked).empty?
  replace = rows.select { |r| r["mode"] == "replace" }.map { |r| r["id"] }
  fail("#{skill}: replace #{replace} vs #{REPLACE[skill]}") unless replace.sort == REPLACE[skill].sort
  optional = rows.select { |r| r["mode"] == "optional" }.map { |r| r["id"] }
  fail("#{skill}: optional before the maintainers name it: #{optional}") unless optional.empty?

  # The loader: task-work runs it before the model reads the skill, so its allowed-tools must cover
  # exactly that command; task-create lets the model run it, so it declares no allowed-tools at all,
  # which would put every model call of it behind the Skill tool's permission check.
  loads = body.include?(%("${CLAUDE_PLUGIN_ROOT}/scripts/lorvel-load" #{skill} #{HEREDOC}))
  fail("#{skill}: does not run the loader with the folder in a quoted heredoc") unless loads
  fail("#{skill}: does not quote the loader's no-customisation line") unless NONE && body.include?("`#{NONE}`")
  fail("#{skill}: lists the whole .lorvel/ folder") if body.include?("ls -a")
  # The loader-only rule has to be in view on every run, not only in the fallback file.
  rule = skill == "task-work" ? "Never open a file in `.lorvel/` yourself" : "Never open those files any other way"
  fail("#{skill}: the loader-only rule is not in SKILL.md itself") unless body.include?(rule)
  # Claude Code runs every ```! block and every !`…` before the model reads the skill; a failing
  # one cancels the whole command. Indented ones count too.
  bang_blocks = body.scan(/^[ \t]*```!/).size
  inline_bangs = body.scan(/(?:^|\s)!`[^`]+`/).size
  if skill == "task-work"
    fail("task-work: allowed-tools is #{front["allowed-tools"].inspect}") unless front["allowed-tools"] == LOADER_RULE
    fail("task-work: the loader is not in a ```! block") unless body.include?("```!\n\"${CLAUDE_PLUGIN_ROOT}/scripts/lorvel-load\" task-work <<")
    fail("task-work: #{bang_blocks} ```! blocks and #{inline_bangs} inline !` commands; only the loader may run") unless bang_blocks == 1 && inline_bangs.zero?
    %w[planning.md building.md].each do |ref|
      fail("task-work: reference/#{ref} does not point to customisation.md") unless File.read(File.join(PLUGIN, "skills", skill, "reference", ref)).include?("`customisation.md`")
    end
    custom = File.join(PLUGIN, "skills", skill, "reference", "customisation.md")
    text = File.exist?(custom) ? File.read(custom) : ""
    fail("task-work: customisation.md lacks the heredoc call") unless text.include?(%("<plugin folder>/scripts/lorvel-load" task-work #{HEREDOC}))
    fail("task-work: customisation.md lacks the loader-only rule") unless text.include?("Never open a file in `.lorvel/` yourself")
    fail("task-work: customisation.md lists the whole .lorvel/ folder") if text.include?("ls -a")
  else
    fail("task-create: declares allowed-tools") if front.key?("allowed-tools")
    fail("task-create: runs a command before the model reads it") unless bang_blocks.zero? && inline_bangs.zero?
  end
  fail("#{skill}: body has $ARGUMENTS inside the loader command") if body =~ /lorvel-load[^\n]*\$ARGUMENTS/
  # Sections apply where they are anchored, so every step file sends the model back to them, in the
  # same words: the rules themselves are in the loader's Sections: line, stated once.
  fail("#{skill}: SKILL.md does not point to the Sections: line") unless body.include?("`Sections:` line")
  Dir[File.join(PLUGIN, "skills", skill, "reference", "*.md")].sort.each do |f|
    next if File.basename(f) == "customisation.md"
    fail("#{skill}: reference/#{File.basename(f)} lacks the sections pointer") unless File.read(f).include?(POINTER[skill])
  end
  # The loader prints labels and quoted source phrases on its Sections line, which its last filter
  # takes only in printable ASCII (and its dash).
  rows.each do |r|
    printed = r["kind"] == "rule" ? Array(r["source"]) : (r["kind"] == "step" ? [r["what"].split(" — ").first] : [])
    printed.each { |t| fail("#{skill}: #{r["id"]} prints #{t.inspect}, which is not printable ASCII") unless t.delete("—").match?(/\A[ -~]*\z/) }
  end

  # The loader reads the same list with awk (scripts/lorvel-ids.awk), in the two shapes the skill
  # writes it in; it has to see exactly what a YAML parser sees.
  want = rows.map do |r|
    label = r["kind"] == "step" ? r["what"].split(" — ").first : ""
    [r["id"], r["kind"], r["mode"], label, Array(r["in"]).join(" "), Array(r["source"])]
  end
  got = awk_ids(File.join(PLUGIN, "skills", skill, "SKILL.md"))
  fail("#{skill}: lorvel-ids.awk reads #{got.inspect}\n  YAML reads #{want.inspect}") unless got == want
  puts "#{skill}: #{rows.size} IDs, #{steps.size} steps, #{gate_ids.size} gates, #{locked.size} locked"
end

# POSIX awk refuses a function parameter named like a function, and gawk --posix enforces it; the
# loader runs these files together.
PROGRAMS = [%w[lorvel-token.awk lorvel-ids.awk lorvel-read.awk], %w[lorvel-ids.awk lorvel-sections.awk], %w[lorvel-token.awk lorvel-check.awk]]
PROGRAMS.each do |files|
  srcs = files.map { |f| File.read(File.join(PLUGIN, "scripts", f)) }
  funcs = srcs.flat_map { |t| t.scan(/^function\s+(\w+)\s*\(/).flatten }
  srcs.each_with_index do |t, i|
    t.scan(/^function\s+(\w+)\s*\(([^)]*)\)/).each do |name, params|
      clash = params.split(",").map(&:strip).reject(&:empty?) & funcs
      fail("#{files[i]}: #{name}() has a parameter named like a function: #{clash}") unless clash.empty?
    end
  end
end

ids_md = File.read(File.join(PLUGIN, "ids.md"))
["- `locked` —", "- `extend` —", "- `replace` —", "- `optional` —", "`metadata.lorvel.ids`", "| `source` |"].each do |s|
  fail("ids.md lacks #{s}") unless ids_md.include?(s)
end
fail("scripts/lorvel-load is not executable") unless File.executable?(File.join(PLUGIN, "scripts", "lorvel-load"))
fail("scripts/lorvel-load has no none= line") unless NONE
# What an install gets is the mode git records, not this checkout's.
repo = File.expand_path("..", __dir__)
if system("git", "-C", repo, "rev-parse", "--git-dir", out: File::NULL, err: File::NULL)
  mode = `git -C "#{repo}" ls-files -s plugins/lorvel/scripts/lorvel-load`[/\A\d+/]
  fail("git records scripts/lorvel-load as #{mode.inspect}, not 100755") unless mode == "100755"
end
# The README states the cap on a file's sections; it has to be the one the loader applies.
seccap = File.read(File.join(PLUGIN, "scripts", "lorvel-load.sh"))[/^seccap=(\d+)$/, 1]
readme = File.read(File.join(repo, "README.md"))
fail("lorvel-load.sh has no seccap= line") unless seccap
fail("README does not give the cap on sections, #{seccap} bytes") unless seccap && readme.include?("#{seccap.to_i.to_s.reverse.scan(/\d{1,3}/).join(",").reverse} bytes")
attrs = File.exist?(File.join(repo, ".gitattributes")) ? File.read(File.join(repo, ".gitattributes")) : ""
["/plugins/lorvel/scripts/* text eol=lf", "/plugins/lorvel/**/*.md text eol=lf"].each do |line|
  fail(".gitattributes lacks #{line}") unless attrs.include?(line)
end

puts "ids tests: #{$failures.zero? ? "passed" : "#{$failures} failed"}"
exit($failures.zero? ? 0 : 1)
