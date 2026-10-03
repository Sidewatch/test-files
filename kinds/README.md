# One file per non-code kind the app previews

Everything Sidewatch (and its Quick Look extension) shows other than source code, one per format the preview
router lists (`PreviewController`'s extension sets), where the gallery folder did not already have it:

- Images: `sample.icns`, `sample.ico`, `sample.avif`, `sample.bmp`, `sample.jpeg` (the four-letter spelling), `sample.tif`
  (the rest — png, jpg, gif, webp, svg, tiff, heic — live in `../gallery`).
- Audio: `sample.aac`, `sample.ogg` (Opus in Ogg), `sample.aif` (wav, mp3, m4a, flac, aiff are in `../gallery`).
- Video: `sample.webm` (mp4, mov, m4v are in `../gallery`).
- Fonts: `sample.ttf` (JetBrains Mono Regular, OFL — `OFL-JetBrainsMono.txt`), `sample.woff`, `sample.woff2`
  (the same face wrapped by fontTools), and `sample.otf`: the same face rebuilt by fontTools with CFF (PostScript)
  outlines, so it is a real `OTTO` OpenType font rather than a renamed TrueType one.
- PDF: `sample.pdf` (two pages of text through cupsfilter), `image.pdf` (one image page).
- Databases: `sample.sqlite`, `sample.sqlite3`, `sample.db3` (copies of `../sample.db`).
- Archives: `sample.zip`, `sample.jar`, `sample.war`, `sample.ipa`, `sample.vsix`, `sample.whl`, `sample.nupkg`,
  `sample.crx` (all zips of the same small tree: a few sources, `META-INF/MANIFEST.MF`, `Payload/App.app/App`,
  a nested folder) and `sample.tar` (the same tree as a tar). `sample.ear` (a Java enterprise archive:
  `META-INF/application.xml` and a nested `.war` and `.jar`) and `sample.xpi` (a browser extension: `manifest.json`,
  scripts, an icon, a locale) are the two zip-shaped kinds the Quick Look extension imports a type for.
- HTTP: `requests.http` — the `.http` client's format: named `###` blocks, headers, JSON and form bodies, a header
  value holding a colon, a lowercase method, an `HTTP/1.1` suffix on the request line, a relative address and a
  comments-only block (both of which offer nothing to run). Every address is under `example.com`.

Made with `sips`, `ffmpeg`, `afconvert`, `cupsfilter`, `zip`, `tar` and fontTools on 24 Sep 2026; `sample.otf`,
`sample.ear`, `sample.xpi` and `requests.http` added on 3 Oct 2026.
