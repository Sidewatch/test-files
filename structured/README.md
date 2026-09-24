# structured — the formats the structure tree shows

One full example per format the editor's tree view reads (25 Sep 2026), each exercising every construct its reader handles, plus the Linux and cross-platform config files that share a shape. Open one and flip the breadcrumb's tree glyph (XML opens on its source; the rest on their tree); double-click a key or a value to edit it in place.

| File | Format | What it exercises |
|---|---|---|
| `app.toml` | TOML | pairs, `[table]`, `[a.b]`, `[[array]]`, dotted and quoted keys, every integer base, floats, `+inf`, the four date-time forms, arrays, nested inline tables, multi-line basic and literal strings |
| `Cargo.toml`, `pyproject.toml` | TOML | real manifests: inline tables, arrays of strings, `[[bin]]`, `[tool.*]` |
| `catalog.xml` | XML | prolog, DOCTYPE, comments, attributes, namespaces, entities (predefined, numeric, DTD), CDATA, repeated children, mixed content, empty elements — opens on its SOURCE |
| `pom.xml`, `web.config` | XML | real documents: namespaces on the root, repeated `<dependency>` / `<add>` gathered into sequences |
| `Info.plist` | XML property list | string, integer, real, true/false, date, data, array, nested dict — in file order, editable |
| `sample.entitlements` | XML property list | a real entitlements file |
| `Compiled.plist`, `Compiled.strings` | binary property lists | the same documents as `plutil -convert binary1` writes them (what Xcode ships in a bundle) — view-only, keys sorted |
| `settings.ini` | INI | sections, `=` and `:`, both comment kinds, typed values, a bare key, a quoted value, a continuation line, `[remote "origin"]` |
| `inventory.service` | systemd unit | `[Unit]` / `[Service]` / `[Install]`, repeated keys |
| `inventory.desktop` | freedesktop entry | `[Desktop Entry]` and an action group |
| `.gitconfig`, `.editorconfig` | INI-shaped dotfiles | tab-indented values; glob section names |
| `tox.ini`, `setup.cfg`, `pip.conf`, `.npmrc`, `php.ini`, `my.cnf`, `smb.conf`, `pacman.conf`, `mimeapps.list` | INI family | multi-line values, bare flags, `;` comments, keys with dots and slashes |
| `gradle.properties` | Java properties | `=`, `:` and whitespace separators, `#` and `!` comments, a continuation line, `\ ` `\\` `\uXXXX` `\t` escapes, an empty value |
| `Localizable.strings` | .strings | quoted and bare keys, both comment kinds, escapes, `"key";` shorthand |
