# VS Code themes for the importer

Two fictional colour themes in VS Code's own format, for Settings > Appearance > Import VS Code Theme
(`VSCodeThemeImporter` in swift-theme-model):

- `harbour-night-color-theme.json` — dark, declared `"type": "dark"`, written as JSONC the way theme
  authors write them: comments, trailing commas, scope arrays and comma-joined scope strings, an
  8-digit `#RRGGBBAA` selection, a 3-digit `#FFF`, a rule with no scope, and all sixteen terminal ANSI
  colours.
- `paper-lantern-color-theme.json` — light, plain JSON, with NO `type` (many themes leave it to the
  extension manifest), so the importer must decide light from the background's luminance; most UI keys
  are missing, so the fallbacks show.
