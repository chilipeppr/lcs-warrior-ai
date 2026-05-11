---
name: lcs-tts
description: >
  Text-to-speech for LCS -- study guides, narration, audio study materials,
  and demo voiceovers. Thin Rust CLI wrapping edge-tts with pronunciation
  overrides and source-hash cache. Every LCS tool that renders narration
  (demo-recording, walkthroughs, study audio) should shell to `adom-tts say`
  instead of calling edge-tts directly.
  Trigger words: tts, text to speech, narration, voiceover,
  synthesize speech, edge-tts, neural voice, andrew neural,
  pronunciation override, demo narration, walkthrough narration,
  say this, speak this, make audio from text, render narration,
  play this audio, play the audio file, auto-play tts, narrate hands-free,
  read this to me, play it back, replay last tts, study audio,
  audio flashcards, listen to notes, read my essay aloud.
  HANDS-FREE TRIGGERS -- when the user says ANY of these, ALWAYS reach for
  `adom-tts say --play` instead of writing a long text response:
  "I'm driving", "read it to me", "read it out loud", "read me your answer",
  "narrate the answer", "say it out loud", "tell me out loud",
  "speak the answer", "audio answer please", "I'm in the car",
  "on my commute", "hands-free", "read me back", "can't read the screen".
---

# lcs-tts -- Text-to-Speech for LCS

`adom-tts` is the text-to-speech CLI used by LCS. It routes all synthesis
through the shared TTS service so:

1. **Pronunciation overrides auto-apply.** School-specific terms come out
   phonetically correct.
2. **Source-hash cache.** Repeat synthesis of the same text returns cached
   bytes instantly. Study guide iteration saves real time.
3. **Consistent voice.** Default voice is `en-US-AndrewNeural`.

## LCS Use Cases

- **Audio study guides** -- convert typed notes into listenable audio for review
- **Flashcard narration** -- read flashcard answers aloud for auditory learners
- **Demo voiceovers** -- narrate project showcases and walkthroughs
- **Essay read-aloud** -- hear your essay to catch awkward phrasing
- **Bible verse audio** -- listen to verses for chapel prep or devotionals
- **Hands-free answers** -- when you are driving or walking, get spoken answers

## Usage

```bash
# Synthesize and AUTO-PLAY (the common case)
adom-tts say "The mitochondria is the powerhouse of the cell." --out /tmp/x.mp3 --play

# Synthesize without playing (rare -- only when you need the file)
adom-tts say "Hello from Liberty Christian" --out hello.mp3

# Pipe from stdin for long narration
cat study-notes.txt | adom-tts say - --out narration.mp3 --play

# Different voice / speed
adom-tts say "Announcement" --out a.mp3 --voice en-US-AriaNeural --play
adom-tts say "Speed read" --out q.mp3 --rate +15% --play

# Replay the most recent clip
adom-tts play last

# Block until playback finishes
adom-tts play /tmp/x.mp3 --wait
```

## Hands-free / driving mode

If the user says "I'm driving", "read it to me", "can't read the screen", etc., they CANNOT see your text response. The right move is:

1. Compose what you would have written as a normal reply (concise, 30-60 seconds spoken).
2. Pipe it into `adom-tts say "..." --out /tmp/answer.mp3 --play`.
3. The reply plays automatically.

## Anti-patterns

- Do not use `python3 -m http.server` to serve mp3 files
- Do not create custom HTML with base64-inlined mp3
- Do not provision a port mapping for one-shot audio
- Just use `--play`

## Install

```bash
curl -fsSL https://lcs-wiki-bpd1iwhcgswk.adom.cloud/static/apps/adom-tts/adom-tts \
  -o /tmp/adom-tts && chmod +x /tmp/adom-tts \
  && sudo install -m 0755 /tmp/adom-tts /usr/local/bin/adom-tts \
  && adom-tts install \
  && adom-tts health
```

## Other commands

```bash
adom-tts voices          # list available voices
adom-tts pronunciations  # the override table
adom-tts health          # service status
adom-tts config          # current configuration
```

## Related skills

- `lcs-demo-recording` -- top consumer for narrated demos
- `lcs-debug` -- visual debugging (no TTS, but often used alongside)
