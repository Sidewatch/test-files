# Large files

Files at the sizes where Sidewatch changes how it opens a file, and the generator that makes them.

## The 200,000-line sources

`huge-200k.swift`, `.php`, `.js` and `.py`: 200,000 lines each of plausible code, the scale test for highlighting,
folding, the minimap, sticky scroll and bracket matching. The header comment in each says how it was made.

## The sized files

Everything in `editor/`, `large-file-view/` and `previews/` is written by `generate.py`, seeded, so a run reproduces the
committed files byte for byte. Change the script, run it, commit what it wrote; never edit a file by hand. The
set is 344 MB, about 69 MB once git compresses it, and each regeneration adds that much to the history again:
change the generator only when a check needs it.

```sh
python3 generate.py              # rewrite the committed files (about a minute)
python3 generate.py --verify     # regenerate into a temporary folder and compare, byte for byte
python3 generate.py --huge DIR   # also write the 100 MiB and 1 GiB files into DIR
```

Each file sits just under (or, once, just over) one of the limits Sidewatch draws, so opening it shows that limit's
heaviest case:

| Limit | What happens past it |
|---|---|
| 64 MiB, or one line of 1 MiB | a text file opens in the large-file view: read-only, any size, read in pieces |
| 20 MiB or 300,000 lines | the editor's plain-text cap: no highlighting, outline or folding |
| 8 MiB | the structure tree (JSON, JSON Lines, YAML, TOML, XML, plists, INI, .properties, .strings) says "Too Large to Preview" |
| 16 MiB | the CSV table, the record tables (hosts, gettext) and rendered HTML pages do too |
| 4 MiB | the `.env` table, the SQL schema and notebooks do too |
| 1 MiB | a rendered Markdown page does too |

### `editor/`

| File | Size | Shows |
|---|---|---|
| `highlighted.json` | 13 MB, 298,967 lines | the most the editor highlights: just under the cap's 300,000 lines |
| `plain-text.log` | 60 MiB, 478,348 lines | the editor's largest file: past the cap, under the large-file view; 43 lines carry `needle-` |

### `large-file-view/`

| File | Size | Shows |
|---|---|---|
| `server.log` | 70 MiB, 558,129 lines | the large-file view by size; 51 lines carry `needle-00000` to `needle-00050` for find |
| `minified.json` | 2 MiB on one line | the large-file view by line length |
| `long-line.log` | 2 MiB | one 1.5 MiB line between two 2,000-line halves: by line length, in the middle of a file |

### `previews/`

Each just under its preview's limit, and each using its format whole:

| File | Size | Holds |
|---|---|---|
| `catalog.json` | 8 MiB | 9,560 items: nested objects and arrays, nulls, escapes, Unicode |
| `events.jsonl` | 8 MiB | 28,041 events of six shapes |
| `regions.geojson` | 8 MiB | 17,786 features: points, lines, polygons and multipolygons |
| `deployments.yaml` | 8 MiB | 6,918 documents: anchors, aliases and merge keys, block scalars of every chomping and an indentation indicator, flow collections, `!!binary` and `!!str`, every scalar kind |
| `config.toml` | 8 MiB | 8,385 services: every value type (hex, octal, binary, underscores, `inf`, `nan`, all four date-times), dotted and quoted keys, inline tables, arrays of tables, all four string kinds |
| `inventory.xml` | 8 MiB | 11,548 items: namespaces, attributes, CDATA, comments, entities, mixed content, a processing instruction |
| `settings.plist` | 8 MiB | 10,868 profiles: every plist type, nested dictionaries and arrays |
| `settings.ini` | 8 MiB | 35,687 sections: both comment markers, `=` and `:`, empty and quoted values |
| `messages.properties` | 8 MiB | 143,690 entries: every separator, escapes, Unicode escapes, continuation lines |
| `Localizable.strings` | 8 MiB | 131,100 entries: escapes, both comment styles, positional placeholders |
| `orders.csv` | 16 MiB | 149,957 rows: quoted fields holding commas, quotes and line breaks |
| `orders.tsv` | 16 MiB | 148,143 rows |
| `blocklist.hosts` | 16 MiB | 360,101 entries: IPv4 and IPv6, two names on a line, inline comments |
| `messages.po` | 16 MiB | 118,705 entries: contexts, plurals, fuzzy and multi-line entries, flags |
| `dump.sql` | 4 MiB | four tables with keys and checks, an index, a view, a trigger, 19,750 rows each, an apostrophe and a semicolon inside strings |
| `analysis.ipynb` | 4 MiB | 2,203 cells: stream, HTML-table, PNG and error outputs |
| `production.env` | 4 MiB | 77,952 entries: `export`, both quotes, `${…}` expansion, inline comments, multi-line values |
| `handbook.md` | 1 MiB | 1,043 chapters: every block and inline form, tables, task lists, code fences, some math |
| `report.html` | 16 MiB | 13,608 sections: tables, `<details>`, inline SVG |
| `too-large.yaml` | 9 MiB | past the tree's 8 MiB: "Too Large to Preview" |

### Bigger than GitHub hosts

GitHub refuses a file over 100 MiB, so the biggest cases are made on your own Mac: `python3 generate.py --huge
~/Desktop/big` writes `server-100mb.log`, `server-1gb.log`, `catalog-100mb.json`, `catalog-1gb.json`,
`orders-100mb.csv` and `minified-100mb.json` there (about 2.4 GB, a few minutes). It refuses to write them inside
this repository.

## Checked

Every file was read by its format's own parser when it was made: Python's `json`, `tomllib`, `xml`, `plistlib`,
`configparser`, `csv` and `sqlite3` (the dump loads with its foreign keys on), Ruby's Psych for the YAML (aliases and
merge keys resolved), `plutil -lint`, `xmllint`, and `msgfmt --check`. `secrets scan` read the first megabyte of each
(it skips big files). Every name, host, address and key is fictional.

Sidewatch's `--selftest-corrupt-input` leaves these three folders out (three damaged copies of each would be a
gigabyte a run); `--probe-open-kinds` opens them whole.
