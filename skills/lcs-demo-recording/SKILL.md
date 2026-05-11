---
name: lcs-demo-recording
description: >
  Use when a student or teacher wants to record a demo, make a video, create
  a walkthrough, record their screen, or capture a demo of a project. Handles
  the full pre-production and recording workflow: writing the demo script,
  generating captions, verifying the setup, choreographing panels, and driving
  the recording. Hands off to video-post for post-production (speedup,
  voiceover, publish). Trigger words: record a video, record a demo, make a
  movie, create a walkthrough, record my screen, demo video, screen recording,
  narrate a walkthrough, capture a demo, make a demo, project showcase,
  STRIVE demo, student presentation.
---

# Demo Recording -- LCS Orchestration

Record polished demo videos of student projects, teacher walkthroughs,
STRIVE Center showcases, and school app features. This file is the
**orchestration entry point**.

## Use Cases at LCS

- **Student project showcases** -- record a walkthrough of a STRIVE Center project (3D printing, robotics, electronics)
- **Teacher walkthroughs** -- record how to use a new LCS app or study tool
- **Conrad Challenge submissions** -- polished demos for competition entries
- **Course tutorials** -- step-by-step guides for assignments or lab procedures
- **App demos** -- showcase LCS apps (flashcard trainers, quiz builders, dashboards)

## Step 1: Ask how the user wants to record

Present the user with a choice:

> **How would you like to record?**
>
> 1. **Quick recording** -- I will start recording your screen with your mic on.
>    You narrate live, stop when done. Ready to upload immediately.
> 2. **Polished recording** -- I will write a sectioned script first, then record
>    each section as its own clip, generate TTS per section, and concat them
>    into one final video. This is the canonical path for project showcases
>    and competition submissions.
> 3. **Just post-process** -- I already have a recording. (Hand off to
>    `video-post` skill)

### Quick recording

Start the recording immediately. Good for informal walkthroughs and quick project updates to post in #strive-center or #students.

### Polished recording (the canonical path)

Follow this sequence:

1. **Write the demo script** at `<repo>/demo/<name>-demo-script.md` with a row-per-scene table containing caption, narration, target length, and driver actions. Show the script to the user for approval BEFORE recording.
2. **Record one short clip per section** -- never a single long take.
3. **Per-clip TTS** via `adom-tts say` for narration (uses `en-US-AndrewMultilingualNeural` voice by default).
4. **Per-clip mux** -- TTS audio combined with the silent recording.
5. **Storyboard review with the user** -- MANDATORY gate before concat.
6. **Concat** clips into the final video.
7. **Hero image** -- extract a representative frame.
8. **Show the final video** to the user before uploading.
9. **Upload to wiki** -- `lcs-wiki asset upload <page> --asset-type video --file final.webm`

## Non-negotiable rules

1. **Per-clip storyboard review is mandatory.** Do not skip it. Per-clip review catches problems in 30 seconds; watching a full concat to find the same problem takes 20x longer.
2. **Never fake interactions you cannot drive.** If you cannot synthesize a real user action, tell the user and ask them to do that part.
3. **Every clip gets the same staging quality.** If you cannot maintain quality for 6 clips, do 4 well instead of 6 poorly.
4. **Do not silently drop clips.** If a clip fails, tell the user immediately with options.
5. **Show the final video before uploading.** The user reviews it first.
6. **End-of-demo report is honest.** Per-clip quality table, mark any compromises.

## Related skills

- `lcs-tts` -- text-to-speech for narration
- `lcs-screenshot` -- screenshot documentation
- `lcs-wiki` -- publishing to the LCS Wiki
