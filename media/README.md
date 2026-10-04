# Media, documents and archives

One file per non-code format the app (and its Quick Look extension) previews, sorted by kind. `--selftest-kinds`
opens each through the editor's real open path and checks it lands on its surface with content.

- `images/` — `sample.icns`, `sample.ico`, `sample.avif`, `sample.bmp`, `sample.jpeg` (the four-letter spelling),
  `sample.tif`, `sample.png` (png, jpg, gif, webp, svg, tiff and heic in every awkward size are in `gallery/`).
- `audio/` — `sample.aac`, `sample.ogg` (Opus in Ogg), `sample.aif` (wav, mp3, m4a, flac and aiff are in
  `gallery/`).
- `video/` — `sample.webm`, which plays through WebKit (mp4, mov and m4v are in `gallery/`).
- `fonts/` — `sample.ttf` (JetBrains Mono Regular, OFL — `OFL-JetBrainsMono.txt`), `sample.woff`, `sample.woff2`
  (the same face wrapped by fontTools), and `sample.otf`: the same face rebuilt by fontTools with CFF (PostScript)
  outlines, so it is a real `OTTO` OpenType font rather than a renamed TrueType one.
- `documents/` — `sample.pdf` (two pages of text through cupsfilter), `image.pdf` (one image page), `page.html`
  (the web preview) and `sample-showcase.md` (every Markdown construct the preview renders: Mermaid, LaTeX,
  tables, task lists, fenced code).
- `archives/` — `sample.zip`, `sample.jar`, `sample.war`, `sample.ipa`, `sample.vsix`, `sample.whl`,
  `sample.nupkg`, `sample.crx` (all zips of the same small tree: a few sources, `META-INF/MANIFEST.MF`,
  `Payload/App.app/App`, a nested folder), `sample.tar` (the same tree as a tar), `sample.ear` (a Java enterprise
  archive: `META-INF/application.xml` and a nested `.war` and `.jar`), `sample.xpi` (a browser extension:
  `manifest.json`, scripts, an icon, a locale) and `example.zip`.
- `gallery/` — a folder of mixed media Sidewatch opens as a gallery, with every awkward size and broken file (see
  the top-level README).

Made with `sips`, `ffmpeg`, `afconvert`, `cupsfilter`, `zip`, `tar` and fontTools. The SQLite variants that used to
sit with these are in `../database/`.
