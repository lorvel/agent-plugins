# encoding: utf-8
# Checks the step IDs each SKILL.md declares under metadata.lorvel.ids against the skill's own text,
# how task-work and task-create run the .lorvel/ loader, and that task-plan, which takes no
# customisation yet, does not. See plugins/lorvel/ids.md.
# Run from anywhere: ruby tests/ids.test.rb

require "yaml"
require "open3"
require "tempfile"
require "tmpdir"
Encoding.default_external = Encoding::UTF_8

PLUGIN = File.expand_path("../plugins/lorvel", __dir__)
MODES = %w[locked extend replace optional]
KINDS = %w[step gate rule]
# A skill edit never relaxes a locked ID (ids.md), so the locked set only grows.
LOCKED = {
  "task-work" => %w[STOP-1 STOP-2 STOP-3 missing-tools machine-gates no-undo close-on-evidence knowledge-audit no-secrets loader-only],
  "task-create" => %w[GATE-1 GATE-2 ask recheck no-one-to-ask no-secrets loader-only],
  "task-plan" => %w[GATE-1 GATE-2 ask plan-only no-one-to-ask no-secrets],
}
REPLACE = { "task-work" => [], "task-create" => %w[classify], "task-plan" => [] }
# The commands a .lorvel/ file can customise: the loader knows these two names and no other, and
# task-customize writes for them alone. task-plan declares its IDs like them, but nothing applies a
# customisation to it yet.
CUSTOMISED = %w[task-work task-create]
# Where a command sits in the chain is the start of its description, which the menu shows beside its
# name. task-customize is no step of the chain and carries no label.
STEP_LABEL = { "task-create" => "Step 1 — ", "task-plan" => "Step 2 (optional) — ", "task-work" => "Step 3 — " }
# The one file that says how to get to a plan, as task-plan names it: ${CLAUDE_PLUGIN_ROOT} is
# replaced in the body of a SKILL.md, so that command can point there from another skill's folder.
METHOD_POINTER = "${CLAUDE_PLUGIN_ROOT}/skills/task-work/reference/plan-method.md"
PUBLISHED = { "task-plan" => %w[locate GATE-1 GATE-2 read ask write report plan-only no-one-to-ask no-secrets] }
LOADER_RULE = 'Bash("${CLAUDE_PLUGIN_ROOT}/scripts/lorvel-load" *)'
HEREDOC = "<<'LORVEL_SESSION_FOLDER'"
# The line the loader prints when there is nothing to apply; task-work and task-create quote it,
# and tell the model to say nothing about it.
NONE = File.read(File.join(PLUGIN, "scripts", "lorvel-load"))[/^none='([^']*)'$/, 1]

POINTER = {
  "task-work" => "**Sections from this run's customisation.** Look at the `<customisation>` block as each phase and gate in this file starts and ends, rather than trusting what you remember of the start of the run, and run its sections as its `Sections:` line says. No block in view ⇒ follow `customisation.md`, beside this file, first.",
  "task-create" => "**Sections from this run's customisation.** Look at the loader's output from step 1 as each step and gate in this file starts and ends, and run its sections as its `Sections:` line says. That output no longer in view ⇒ run the loader again, as `SKILL.md` says; refused ⇒ customisation is off for the rest of this run.",
}

$failures = 0
# Every ID the two customised commands declare, for the check that task-customize carries no copy
# of them.
ALL_IDS = []
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

(CUSTOMISED + %w[task-plan]).each do |skill|
  path = File.join(PLUGIN, "skills", skill, "SKILL.md")
  (fail("#{skill}: no SKILL.md"); next) unless File.exist?(path)
  text = File.read(path)
  m = text.match(/\A---\n(.*?)\n---\n/m) or (fail("#{skill}: no frontmatter"); next)
  front = YAML.safe_load(m[1])
  body = m.post_match
  fail("#{skill}: description does not start with #{STEP_LABEL[skill].inspect}") unless front["description"].to_s.start_with?(STEP_LABEL[skill])
  refs = Dir[File.join(PLUGIN, "skills", skill, "reference", "*.md")].sort.map { |f| File.read(f) }
  lorvel = (front["metadata"] || {})["lorvel"] || {}
  fail("#{skill}: schema #{lorvel["schema"].inspect}") unless lorvel["schema"] == 1
  rows = lorvel["ids"]
  (fail("#{skill}: ids is not a list"); next) unless rows.is_a?(Array) && !rows.empty?

  ids = rows.map { |r| r["id"] }
  ALL_IDS.concat(ids) if CUSTOMISED.include?(skill)
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

  # Claude Code runs every ```! block and every !`…` before the model reads the skill; a failing
  # one cancels the whole command. Indented ones count too.
  bang_blocks = body.scan(/^[ \t]*```!/).size
  inline_bangs = body.scan(/(?:^|\s)!`[^`]+`/).size
  if CUSTOMISED.include?(skill)
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
    # Two files hold no step of the flow and carry no pointer: the fallback for a lost block, and the
    # planning method, which is written for any command that plans and not for this one's flow.
    Dir[File.join(PLUGIN, "skills", skill, "reference", "*.md")].sort.each do |f|
      next if %w[customisation.md plan-method.md].include?(File.basename(f))
      fail("#{skill}: reference/#{File.basename(f)} lacks the sections pointer") unless File.read(f).include?(POINTER[skill])
    end
  else
    # Nothing applies a customisation to task-plan yet. Neither what the model's list of skills shows
    # of it nor its body runs the loader, and both scripts refuse its name. A file in .lorvel/ is
    # repository text no script has checked for this command, so the body says not to open one, as
    # the other two commands do.
    shown = [front["description"], front["when_to_use"], body].join("\n")
    fail("#{skill}: calls the loader") if shown.include?("lorvel-load")
    fail("#{skill}: lacks the rule against opening a file in .lorvel/") unless body.include?("Open no file in a `.lorvel/` folder")
    # That rule is the one place the folder is named: any other mention would be telling the model
    # that something in there is for this command.
    fail("#{skill}: names .lorvel/ #{shown.scan(".lorvel/").size} times, not once, in the rule against opening its files") unless shown.scan(".lorvel/").size == 1
    # Run through sh, as a missing execute bit is reported further down, not here.
    load_out, = Open3.capture2e("sh", File.join(PLUGIN, "scripts", "lorvel-load"), skill, Dir.tmpdir)
    fail("#{skill}: the loader does not refuse its name: #{load_out[0, 90].inspect}") unless load_out.include?("a command it does not know")
    show_out, = Open3.capture2e("sh", File.join(PLUGIN, "scripts", "lorvel-customize"), "show", skill, stdin_data: "#{Dir.tmpdir}\n")
    fail("#{skill}: lorvel-customize does not refuse its name: #{show_out[0, 90].inspect}") unless show_out.include?("works on task-work and task-create only")
    # The model may call this command, and so may a subagent, so it carries neither
    # disable-model-invocation nor allowed-tools, which would put a model's call of it behind the
    # Skill tool's permission check; what tells the model when to call it has both of its sides.
    fail("#{skill}: declares allowed-tools") if front.key?("allowed-tools")
    fail("#{skill}: sets disable-model-invocation") if front["disable-model-invocation"] == true
    when_to_use = front["when_to_use"].to_s
    fail("#{skill}: when_to_use lacks one of its two sides") unless when_to_use.include?("Use when") && when_to_use.include?("Do NOT use it")
    fail("#{skill}: runs a command before the model reads it") unless bang_blocks.zero? && inline_bangs.zero?
    # An ID is public from the commit that declares it: these ten are the ones this command was
    # published with, and none of them may go. The question about a plan the task already has is
    # asked in step 1, before the reading.
    gone = PUBLISHED[skill] - ids
    fail("#{skill}: IDs gone: #{gone}") unless gone.empty?
    gate_2 = rows.find { |r| r["id"] == "GATE-2" } || {}
    fail("#{skill}: GATE-2 sits in #{gate_2["in"].inspect}, not in step 1") unless gate_2["in"] == %w[locate]
    # It holds no planning method of its own: it names the one file, and the section of the guide
    # that says what a plan holds.
    fail("#{skill}: does not point to the planning method") unless body.include?("`#{METHOD_POINTER}`")
    fail("#{skill}: the planning method it points to is missing") unless File.exist?(METHOD_POINTER.sub("${CLAUDE_PLUGIN_ROOT}", PLUGIN))
    fail("#{skill}: does not name the guide's section") unless body.include?('the "Writing a plan" section of `task_authoring_guide`')
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

# task-customize writes the files task-work and task-create read, through scripts/lorvel-customize,
# and is customised by nothing, so it declares no IDs. It runs only when typed, and the script is the
# only command it pre-approves.
CUSTOMIZE_RULE = 'Bash("${CLAUDE_PLUGIN_ROOT}/scripts/lorvel-customize" *)'
CUSTOMIZE_CALL = %("${CLAUDE_PLUGIN_ROOT}/scripts/lorvel-customize" <verb> <command> … <<'LORVEL_INPUT'\n    ${CLAUDE_PROJECT_DIR}\n    LORVEL_INPUT\n)
cdir = File.join(PLUGIN, "skills", "task-customize")
ctext = File.exist?(File.join(cdir, "SKILL.md")) ? File.read(File.join(cdir, "SKILL.md")) : ""
if (m = ctext.match(/\A---\n(.*?)\n---\n/m))
  front = YAML.safe_load(m[1])
  body = m.post_match
  fail("task-customize: disable-model-invocation is #{front["disable-model-invocation"].inspect}") unless front["disable-model-invocation"] == true
  fail("task-customize: allowed-tools is #{front["allowed-tools"].inspect}") unless front["allowed-tools"] == CUSTOMIZE_RULE
  fail("task-customize: declares metadata") if front.key?("metadata")
  fail("task-customize: its description carries a step label") if front["description"].to_s =~ /\AStep\b/
  fail("task-customize: runs a command before the model reads it") unless body.scan(/^[ \t]*```!/).empty? && body.scan(/(?:^|\s)!`[^`]+`/).empty?
  fail("task-customize: does not give the script the folder in a quoted heredoc") unless body.include?(CUSTOMIZE_CALL)
  fail("task-customize: lacks the never-open rule") unless body.include?("Never open a file in `.lorvel/` yourself")
  fail("task-customize: body has $ARGUMENTS inside the script's command") if body =~ /lorvel-customize[^\n]*\$ARGUMENTS/

  # One source: the steps, gates, rules and modes come from `show` at run time, so no text of this
  # skill may hold a copy of them — no gate name, no ID written as code or after an operation, no
  # line of the declarations or of what `show` prints. The script's own verbs are the exception:
  # `write` is also a step of task-create.
  verbs = %w[show check write gitignore]
  shown_lines = CUSTOMISED.flat_map do |cmd|
    out, status = Open3.capture2({"LC_ALL" => "C", "LORVEL_SKILLMD" => File.join(PLUGIN, "skills", cmd, "SKILL.md"),
                                  "LORVEL_IDSMD" => File.join(PLUGIN, "ids.md")},
                                 "awk", "-v", "skill=#{cmd}", "-f", File.join(PLUGIN, "scripts", "lorvel-ids.awk"),
                                 "-f", File.join(PLUGIN, "scripts", "lorvel-points.awk"), stdin_data: "")
    fail("lorvel-points.awk failed for #{cmd}") unless status.success?
    out.force_encoding("UTF-8").lines.map { |l| l.chomp.sub(/\A- /, "") }.select { |l| l.length >= 30 }
  end.uniq
  ids = ALL_IDS.uniq
  id_re = ids.map { |i| Regexp.escape(i) }.join("|")
  ([["SKILL.md", body]] + Dir[File.join(cdir, "reference", "*.md")].sort.map { |f| [File.basename(f), File.read(f)] }).each do |name, t|
    t.scan(/`([^`\n]+)`/).flatten.each do |code|
      fail("task-customize/#{name}: names the ID #{code} as code") if ids.include?(code) && !verbs.include?(code)
    end
    t.scan(/\b(?:before|after|replace|skip):[ \t]*(#{id_re})\b/).flatten.uniq.each { |id| fail("task-customize/#{name}: anchors a section at #{id}") }
    t.scan(/\b(?:STOP|GATE)-\d+\b/).uniq.each { |g| fail("task-customize/#{name}: names #{g}") }
    fail("task-customize/#{name}: holds a line of the declarations") if t =~ /\{\s*id:|\b(?:kind|mode):[ \t]*(?:step|gate|rule|locked|extend|replace|optional)\b/
    t.scan(/^[ \t]*- (#{id_re}) \(/).flatten.uniq.each { |id| fail("task-customize/#{name}: holds the line show prints for #{id}") }
    # Nor any line `show` prints for either command — steps, rules, the modes it quotes from ids.md,
    # the settings — copied whole, or its part after a leading "- ".
    shown_lines.each do |line|
      fail("task-customize/#{name}: holds a line show prints: #{line[0, 60].inspect}") if t.include?(line)
    end
  end
  puts "task-customize: no copy of the #{ids.size} IDs or of the #{shown_lines.size} lines show prints"
else
  fail("task-customize: no SKILL.md with frontmatter")
end

# POSIX awk refuses a function parameter named like a function, and gawk --posix enforces it; the
# loader runs these files together.
PROGRAMS = [%w[lorvel-token.awk lorvel-ids.awk lorvel-read.awk], %w[lorvel-ids.awk lorvel-sections.awk], %w[lorvel-token.awk lorvel-check.awk],
            %w[lorvel-ids.awk lorvel-points.awk]]
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

# How to get to a plan is in one file, reference/plan-method.md of task-work. It sits beside
# planning.md so that one permission to read that folder covers both, and planning.md points to it
# as a file beside it: ${CLAUDE_PLUGIN_ROOT} is not replaced in a file the model reads with Read.
# task-plan points to the same file from the body of its SKILL.md, where that variable is replaced;
# the loop above checks that pointer.
# The method file names the section of task_authoring_guide that says what a plan holds, and it is
# no step file of task-work: it carries neither the sections pointer nor the customisation block.
# This checks the pointers, and that one heading of the list the command used to carry, "Changes
# by file", has not come back under skills/. That no file restates the guide is for a reader to
# check, not for this test.
method = File.join(PLUGIN, "skills", "task-work", "reference", "plan-method.md")
if File.exist?(method)
  mtext = File.read(method)
  fail("plan-method.md does not name the guide's section") unless mtext.include?('the "Writing a plan" section of `task_authoring_guide`')
  fail("plan-method.md speaks of the customisation of one command") if mtext.include?("<customisation>") || mtext.include?(POINTER["task-work"])
else
  fail("task-work: reference/plan-method.md is missing")
end
planning = File.read(File.join(PLUGIN, "skills", "task-work", "reference", "planning.md"))
fail("task-work: reference/planning.md does not point to plan-method.md beside it") unless planning.include?("`plan-method.md`, beside this file")
Dir[File.join(PLUGIN, "skills", "**", "*.md")].sort.each do |f|
  fail("#{f.delete_prefix(PLUGIN + "/")}: carries the old list of plan headings") if File.read(f).include?("Changes by file")
end
puts "plan method: skills/task-work/reference/plan-method.md, named by planning.md beside it"

ids_md = File.read(File.join(PLUGIN, "ids.md"))
["- `locked` —", "- `extend` —", "- `replace` —", "- `optional` —", "`metadata.lorvel.ids`", "| `source` |"].each do |s|
  fail("ids.md lacks #{s}") unless ids_md.include?(s)
end
%w[lorvel-load lorvel-customize].each do |script|
  fail("scripts/#{script} is not executable") unless File.executable?(File.join(PLUGIN, "scripts", script))
end
fail("scripts/lorvel-load has no none= line") unless NONE
# What an install gets is the mode git records, not this checkout's.
repo = File.expand_path("..", __dir__)
if system("git", "-C", repo, "rev-parse", "--git-dir", out: File::NULL, err: File::NULL)
  %w[lorvel-load lorvel-customize].each do |script|
    mode = `git -C "#{repo}" ls-files -s plugins/lorvel/scripts/#{script}`[/\A\d+/]
    fail("git records scripts/#{script} as #{mode.inspect}, not 100755") unless mode == "100755"
  end
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
