# Notices

Everything in this repository is covered by the MIT licence in `LICENSE`, except the files below.

## JetBrains Mono — SIL Open Font License 1.1

`media/fonts/sample.ttf` is JetBrains Mono Regular; `media/fonts/sample.woff` and `media/fonts/sample.woff2` are the same face
wrapped by fontTools, and `media/fonts/sample.otf` is the same face rebuilt by fontTools with CFF outlines. Copyright 2020 The JetBrains Mono Project Authors
(https://github.com/JetBrains/JetBrainsMono). The licence text is in `media/fonts/OFL-JetBrainsMono.txt`.

## Agent transcripts — MIT, Alexander Malakhov

`sessions/gemini/chats/session-v040.jsonl` and everything under `sessions/grok/` are sanitized captures of real
Gemini CLI 0.40 and Grok Build CLI runs from [jazzyalex/agent-sessions](https://github.com/jazzyalex/agent-sessions)
at commit `a93b22b`, the same fixtures swift-agent-kit's adapter tests use. MIT License, Copyright (c) 2026
Alexander Malakhov: <https://github.com/jazzyalex/agent-sessions/blob/main/LICENSE>.

## Recorded audio — included for testing only

These are real instrument recordings, not generated tones. They are here so the gallery and waveform
previews meet real-world audio, and they are NOT licensed under MIT: do not reuse them outside testing
Sidewatch.

- `media/gallery/DAWNING.wav`
- `media/gallery/Pad_Space.wav`
- `media/gallery/Pad_Forgotten_Path.mp3`
- `media/gallery/Pad_Spring.mp3`
- `media/gallery/Piano_Vortex.mp3`
- `media/gallery/Pluck_Sweetest.mp3`
- `media/gallery/nested/Pad_Truck.mp3`
- `media/gallery/nested/deeper/Pad_Wide_Loop.mp3`

Every other image, sound and video in `media/` was generated for this repository (CoreGraphics,
ffmpeg, `afconvert`, `sips`, `cupsfilter`).

## Example data

Names, addresses, keys and passwords in the fixtures are fictional placeholders (`example.com`, `192.0.2.x`,
`example-not-a-real-key`, `s3cret`). None of them is a working credential.
