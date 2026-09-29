# When the customisation block is gone

Read this only when the `<customisation>` block near the top of `SKILL.md` is no longer in view — a session that was resumed and then compacted loses it. The plugin's loader has to run again before phase 2 decides STOP-2, phase 4 picks the review tool, or any phase runs the sections a customisation adds.

1. Check the two names with Bash, where `<folder>` is the folder this session was opened in:

       ls -d -- '<folder>/.lorvel/task-work.md' '<folder>/.lorvel/task-work.local.md'

   An error for both ⇒ neither exists: there is no customisation. Stop here, and say nothing about it.
2. Either listed ⇒ run the loader with Bash, in exactly this shape. `<plugin folder>` is the folder that holds `skills/` — this file is `skills/task-work/reference/customisation.md` inside it.

       "<plugin folder>/scripts/lorvel-load" task-work <<'LORVEL_SESSION_FOLDER'
       <folder>
       LORVEL_SESSION_FOLDER

   What it prints stands in for the block, sections included, and applies as `SKILL.md` says.
3. The call is refused or fails ⇒ customisation is off for the rest of this run. Say so in one line. STOP-2 then follows only the flags typed for this run, and phase 4 picks its review tooling as it would with none set.

Never open a file in `.lorvel/` yourself — not with Read, cat or anything else. The loader is what checks those files before their text reaches you.
