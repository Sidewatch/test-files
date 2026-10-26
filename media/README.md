# Media, documents and archives

One file per non-code format the app (and its Quick Look extension) previews, sorted by kind. `--selftest-kinds`
opens each through the editor's real open path and checks it lands on its surface with content.

- `images/` — `sample.icns`, `sample.ico`, `sample.avif`, `sample.bmp`, `sample.jpeg` (the four-letter spelling),
  `sample.tif`, `sample.png` (png, jpg, gif, webp, svg, tiff and heic in every awkward size are in `gallery/`), and
  the textures games ship, all one 128 × 128 picture (a hue sweep, a soft white disc, a half-transparent band):
  `sample.dds` (BC1, the legacy header), `sample-bc7.dds` (BC7 with the DX10 header, which keeps the band's alpha),
  `sample.ktx` (RGBA8) and `sample.hdr` (Radiance RGBE, a spot eight times brighter than white), from a small
  encoder; and `sample.ktx2`, `sample.astc`, `sample.tga`, `sample.exr`, `sample.psd` and `sample.pvr`, written by
  ImageIO. Each decodes back to the picture (BC1 and Radiance without the band's alpha, which they cannot hold).
  ImageIO's KTX writer is not used: it stores 8-bit values under a half-float type, which decodes to nothing
  visible. Its ASTC writer stores rows bottom-up while readers, ImageIO's own included, take the first row as the
  top, so `sample.astc` was written from the picture turned over.
- `audio/` — `sample.aac`, `sample.ogg` (Opus in Ogg), `sample.opus` (the same bytes under Opus's own extension),
  `sample-vorbis.ogg` (Vorbis, what game engines ship), `sample.caf` (Core Audio Format) and `sample.aif` (wav, mp3,
  m4a, flac and aiff are in `gallery/`).
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
- `models/` — 3D models: one toy rocket as USDZ, USDA, USDC, OBJ, STL, PLY, Alembic, Collada, SceneKit, glTF and
  GLB, plus an animated copy, a Z-up copy in centimetres and a dense mesh (its own README). `--selftest-models`
  opens each in a tab and the gallery (the folder also holds the OBJ's MTL, the glTF's buffer, the texture and the
  generator, which `--selftest-kinds` would not know, so that harness leaves it alone).
- `gallery/` — a folder of mixed media Sidewatch opens as a gallery, with every awkward size and broken file (see
  the top-level README).

Made with `sips`, `ffmpeg`, `afconvert`, `cupsfilter`, `zip`, `tar` and fontTools; the models with the generator in
`models/` and Apple's USD tools. The SQLite variants that used to
sit with these are in `../database/`.
