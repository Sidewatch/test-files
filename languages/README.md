# One complete showcase per language

Every language the app's detector knows (`swift-code-kit`'s CodeLanguage, 222 languages) has a folder here holding
ONE file that exercises everything its syntax has: every comment form (line, block, nested, doc, pragmas), every
string form (escapes, raw, multi-line, heredocs, interpolation), every number form, every keyword group, every
declaration kind, operator family, directive, annotation and embedded language. Open a folder in Sidewatch, or step
through them in Finder with Space for Quick Look, and every highlighting role should show somewhere in each file.

- The file is named so the detector picks the language from the NAME alone: `sample.<ext>` where the language owns an
  extension, the exact filename where it is known by name (`makefile/Makefile`, `go/…`, `gomod/go.mod`,
  `zsh/.zshrc`, `strings/Localizable.strings`).
- `picker-only/` holds Coq, MATLAB, MySQL and T-SQL, whose extensions belong to another language (see its README).
- `plaintext/sample.txt` is plain text on purpose; there is no SQLite folder (a database is binary, see `kinds/`).
- A showcase aims at the HIGHLIGHTER, not at a compiler: where one language's constructs cannot all live in one
  valid program (several shader stages, several SPARQL query forms, Svelte 4 and 5 syntax), the file holds them all.
  Where a toolchain was installed the file was syntax-checked with it (`swiftc -parse`, `python3 -m py_compile`,
  `node --check`, `php -l`, `perl -c`, `clang -fsyntax-only`, `xmllint`, `plutil -lint`, `jq`, `flex`, `cmake`,
  `msgfmt -c`, `dot`, `xcrun metal`…).
- Hidden-name samples are live to git inside their own folder only: `gitignore/.gitignore` ignores nothing in it, and
  `gitattributes/.gitattributes` applies nothing to itself.

`Sidewatch --selftest-highlight-roles ../TestFiles` (a gate entry) renders every showcase through the editor's three
highlighting tiers with One Dark worn in memory: each must paint at least three colours, and the log ranks every
language by how much of its text is painted, thinnest first. `Sidewatch --dump-captures <file>` prints the winning
role per token for one file.
