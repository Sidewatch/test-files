# structured — every file the structure tree reads

One fixture for **every extension and every exact filename** the language table maps to a format the
editor's tree view shows (25 Sep 2026). `--selftest-config-views ../TestFiles/structured` checks both
directions: every file here routes to a format and reads to a non-empty tree, and every name the
detector claims has a file here — so a name the table gains without a fixture fails the gate.

Open one and flip the breadcrumb's tree glyph. XML opens on its **source** (markup is read as written,
the tree is one click away); every other format opens on its tree. Double-click a key or a value to
edit it in place: the format's finder names the one token, its encoder keeps the kind, one undo step.

## JSON — `.json .avsc .geojson .har .ipynb .topojson .webmanifest` and the config files that are JSON

`package.json`, `schema.avsc` (Avro), `warehouses.geojson`, `session.har`, `analysis.ipynb`,
`regions.topojson`, `app.webmanifest`, `.arcconfig`, `.babelrc`, `.jshintrc`,
`.phpunit.result.cache`, `.prettierrc`, `.stylelintrc`, `.swcrc`, `composer.lock`, `deno.lock`,
`flake.lock`, `Package.resolved`, `Pipfile.lock`

## YAML — `.yaml .yml` and the config files that are YAML

`config.yaml` (typed scalars, a flow sequence, a block scalar), `docker-compose.yml`,
`.clang-format`, `.clang-tidy`, `.condarc`, `.gemrc`, `glide.lock`

## TOML — `.toml` and the manifests and locks that are TOML

`app.toml` — every construct: pairs, `[table]`, `[a.b]`, `[[array]]`, dotted and quoted keys, all four
integer bases, floats, `+inf`, the four date-time forms, arrays, nested inline tables, multi-line basic
and literal strings — plus `Cargo.toml`, `pyproject.toml`, `Pipfile`, `Cargo.lock`, `poetry.lock`,
`uv.lock`, `pdm.lock`

## XML — `.xml .atom .rss .csproj .fsproj .vbproj .props .targets .iml .pom .resx .storyboard .xib .wsdl .xaml .xsd .xsl .xslt .nuspec .opml .gpx .kml` and `web.config`

`catalog.xml` — prolog, DOCTYPE, comments, attributes, namespaces, entities (predefined, numeric and a
DTD's own), CDATA, repeated children gathered into one sequence, mixed content, empty elements — plus
`feed.atom`, `feed.rss`, `Inventory.csproj`, `Inventory.fsproj`, `Inventory.vbproj`,
`Directory.Build.props`, `Directory.Build.targets`, `inventory.iml`, `inventory-1.4.0.pom`, `pom.xml`,
`Resources.resx`, `Main.storyboard`, `Panel.xib`, `orders.wsdl`, `MainWindow.xaml`, `orders.xsd`,
`catalog.xsl`, `catalog.xslt`, `Inventory.nuspec`, `subscriptions.opml`, `track.gpx`, `sites.kml`,
`web.config`

## Property lists — `.plist .entitlements .stringsdict`, text and compiled

`Info.plist` (string, integer, real, true/false, date, data, array, nested dict — in file order,
editable), `sample.entitlements`, `Localizable.stringsdict`, and `Compiled.plist` /
`Compiled.strings` — the same documents as `plutil -convert binary1` writes them, which is what Xcode
ships in a bundle. A binary one is **view-only**: its tree is read from the bytes, keys sorted, no
toggle, and an edit changes nothing.

## INI and its family — `.ini .cfg .cnf .reg .desktop`, systemd units, and the dotfiles

`settings.ini` covers the shape whole: sections, `=` and `:`, both comment kinds, typed values, a bare
key, a quoted value, an indented continuation line, `[remote "origin"]`.

- **systemd** (`.service .socket .timer .mount .automount .path .slice .scope .swap .target .device`):
  `inventory.service`, `inventory.socket`, `inventory-backup.timer`, `srv-inventory.mount`,
  `srv-inventory.automount`, `inventory-uploads.path`, `inventory.slice`, `inventory.scope`,
  `swapfile.swap`, `inventory.target`, `dev-sdb.device`
- **Linux and cross-platform config**: `inventory.desktop`, `my.cnf`, `php.ini`, `smb.conf`,
  `pacman.conf`, `sysctl.conf`, `mimeapps.list`, `.kdeglobals`, `pip.conf`, `.pypirc`, `.npmrc`,
  `.hgrc`, `.wgetrc`, `Doxyfile`, `settings.reg`
- **Project config**: `.gitconfig`, `work.gitconfig`, `.gitmodules`, `.editorconfig`,
  `.editorconfig-legacy`, `tox.ini`, `setup.cfg`, `.flake8`, `.pylintrc`, `.coveragerc`

## Java properties — `.properties`

`gradle.properties` — `=`, `:` and whitespace separators, `#` and `!` comments, a continuation line,
`\ ` `\\` `\uXXXX` `\t` escapes, an empty value

## Strings — `.strings`

`Localizable.strings` — quoted and bare keys, both comment kinds, escapes, the `"key";` shorthand

## Deliberately NOT a tree

`yarn.lock` (a yarn v1 lockfile only looks like YAML) opens on its source and offers no preview at all.
An `.svg` is an image and a `.ips` crash report is two JSON documents, so neither gets a tree either;
they live elsewhere in the corpus.
