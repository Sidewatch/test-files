# One sample per language

Every language the app's detector knows (`swift-code-language`, 221 languages) has a file here, named so that the
detector picks it from the NAME alone — `sample.<ext>` where the language owns an extension, the exact filename
where it is known by name (`Dockerfile`, `Makefile`, `go.mod`, `justfile`, `.zshrc`, `Localizable.strings`…).
Each shows the syntax a highlighter has to cope with: comments, strings, numbers, keywords, a definition, a call.

- 216 of the 221 detect from the name; the four that collide with another language's extension are under
  `picker-only/` (Coq, MATLAB, MySQL, T-SQL — see its README), and `sample.txt` is plain text on purpose.
- Some root-level fixtures cover a language too (`sample.php`, `sample.swift`…) and are what the harnesses read;
  the copies here exist so this one folder can be stepped through end to end (Space in Finder for Quick Look,
  or open the folder in Sidewatch).
- Quick Look note: `.dot` is a Word template type to macOS, so the Graphviz sample is `sample.gv`; `.ts` and
  `.mts` are MPEG-2 types, which the extension claims and sniffs.

Regenerate the coverage check with the detector itself: the scratch `detect` executable in the session notes, or
`Sidewatch --dump-highlight <file>` from the bundle prints the detected language on its first line.
