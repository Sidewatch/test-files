# Contributing

This repository is test data for Sidewatch. A change is welcome when it makes a check sharper or a
by-hand review easier: a construct a showcase is missing, a format the app reads with no fixture, an edge
case that once broke a preview.

## Rules

- **Fictional data only.** No real names, emails, hosts, keys or tokens — use `example.com`, `192.0.2.x`,
  `2001:db8::` and placeholders a secret scanner will not match (`example-not-a-real-key`). Run
  `secrets scan` or an equivalent before opening a pull request.
- **Name files so the detector picks them from the name alone.** `languages/<language>/sample.<ext>`, or the
  exact filename where the language is known by name (`Makefile`, `go.mod`, `.zshrc`).
- **A showcase covers its language whole** — every comment, string, number, keyword, declaration, operator and
  directive form — and is checked with the language's own tool where one is installed. Note in the pull
  request what could not be checked.
- **Plain UTF-8, LF line endings**, a trailing newline, no BOM — unless the file exists to test exactly that.
- **Hidden files are live to git in their own folder.** A `.gitignore` showcase must not ignore anything
  else in the repository, and a `.gitattributes` showcase must not change how its own folder checks out.
- **Generated files are regenerated, not edited** (`large-files/`, the generated media). Their header or the
  folder's README says how.
- **Third-party material** needs a licence that allows redistribution and an entry in `NOTICE.md`.

## Adding a language

1. Add `languages/<language>/<file>` with a complete showcase.
2. If the app reads it as structure (JSON, YAML, TOML, XML, INI…), add a fixture to `data/trees/` too:
   the structure harness fails when a name the detector claims has no fixture there.
3. Run Sidewatch's `--selftest-highlight-roles ../TestFiles` and, for structure, `--selftest-config-views
   ../TestFiles/data/trees` from the app repository.

## Licence

By contributing you agree your contribution is released under the MIT licence in `LICENSE`.
