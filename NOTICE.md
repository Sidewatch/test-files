# Notices

Everything in this repository is covered by the MIT licence in `LICENSE`, except the files below.

## JetBrains Mono — SIL Open Font License 1.1

`kinds/sample.ttf` is JetBrains Mono Regular; `kinds/sample.woff` and `kinds/sample.woff2` are the same face
wrapped by fontTools, and `kinds/sample.otf` is the same face rebuilt by fontTools with CFF outlines. Copyright 2020 The JetBrains Mono Project Authors
(https://github.com/JetBrains/JetBrainsMono). The licence text is in `kinds/OFL-JetBrainsMono.txt`.

## Agent transcripts — MIT, Alexander Malakhov

`sessions/gemini/chats/session-v040.jsonl` and everything under `sessions/grok/` are sanitized captures of real
Gemini CLI 0.40 and Grok Build CLI runs from [jazzyalex/agent-sessions](https://github.com/jazzyalex/agent-sessions)
at commit `a93b22b`, the same fixtures swift-agent-kit's adapter tests use. MIT License, Copyright (c) 2026
Alexander Malakhov: <https://github.com/jazzyalex/agent-sessions/blob/main/LICENSE>.

## Recorded audio — included for testing only

These are real instrument recordings, not generated tones. They are here so the gallery and waveform
previews meet real-world audio, and they are NOT licensed under MIT: do not reuse them outside testing
Sidewatch.

- `gallery/DAWNING.wav`
- `gallery/Pad_Space.wav`
- `gallery/Pad_Forgotten_Path.mp3`
- `gallery/Pad_Spring.mp3`
- `gallery/Piano_Vortex.mp3`
- `gallery/Pluck_Sweetest.mp3`
- `gallery/nested/Pad_Truck.mp3`
- `gallery/nested/deeper/Pad_Wide_Loop.mp3`

Every other image, sound and video in `gallery/` and `kinds/` was generated for this repository (CoreGraphics,
ffmpeg, `afconvert`, `sips`, `cupsfilter`).

## Example data

Names, addresses, keys and passwords in the fixtures are fictional placeholders (`example.com`, `192.0.2.x`,
`example-not-a-real-key`, `s3cret`). None of them is a working credential.
