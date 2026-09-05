# Sidewatch Test Files

The corpus Sidewatch's headless harnesses and by-hand checks run against. Nothing here is
built or shipped; every file exists to exercise one part of the app at a known size.

- `sample.<ext>` — one small, representative file per language for syntax highlighting
  (`Sidewatch --dump-captures ../TestFiles/sample.swift` prints the winning role per token).
  Also the hover/completion built-ins, the outline, and the language-detection tables.
- `huge-200k.swift` / `.php` / `.js` / `.py` — 200,000 lines each of plausible code: the
  scale test for highlighting, folding, the minimap, sticky scroll and bracket matching.
  Generated (see the header comment in each); never hand-edit, regenerate.
- `sample-showcase.md` — every markdown construct the preview renders.
- `sessions/<agent>/*.jsonl` — anonymised agent transcripts, one per adapter, for
  `Sidewatch --dump-session` and the Terminals rail's status derivation.
- `gutter-check.swift`, `scrolltest.swift` — the editor gutter and scroll harnesses.
- `people.csv`, `sample.db`, `sample.json`, `sample.png`, `example.zip`, `page.html` — the
  preview surfaces (table, database browser, JSON tree, image, archive, web).

Clone it next to the app (`~/Developer/Swift/Sidewatch/TestFiles`); the app's docs refer to
it as `../TestFiles`.
