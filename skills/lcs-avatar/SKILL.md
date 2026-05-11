---
name: lcs-avatar
description: "Use when a teacher or student wants to create narrated lessons, walkthroughs, or presentations with a 3D talking avatar. The avatar appears as an overlay and speaks text aloud using TTS with lip-sync animation. LCS Warriors branded. Triggers: avatar, narrate, talking character, lesson narration, speak aloud, avatar say, voiceover, narrator, virtual presenter, video lesson."
---

# LCS Avatar — 3D Talking Presenter

A cartoonish 3D avatar that appears as an overlay in the viewer and speaks text aloud using TTS (text-to-speech) with lip-sync animation. Perfect for teacher-created video lessons, student presentations, and guided walkthroughs.

## Commands

All commands go through the `avatar` CLI:

```bash
# Show the avatar in the bottom-right corner
avatar show

# Make the avatar speak (triggers TTS + lip-sync)
avatar say "Welcome to today's lesson on the American Revolution"

# Hide the avatar
avatar hide

# Run a quick demo
avatar demo
```

The `avatar say` command blocks for an estimated speech duration (~150ms per word) so you can chain commands sequentially.

## Teacher Lesson Pattern

Use the avatar to create narrated lessons for any subject:

```bash
# 1. Show avatar
avatar show

# 2. Introduce the lesson
avatar say "Good morning class! Today we're going to learn about cellular respiration."

# 3. Walk through content with narration
avatar say "First, let's look at the overall equation for cellular respiration."
# ... display the equation or diagram ...

avatar say "Glucose plus oxygen produces carbon dioxide, water, and ATP energy."
# ... highlight each component ...

avatar say "Now let's break this down into three stages: glycolysis, the Krebs cycle, and the electron transport chain."
# ... show each stage ...

# 4. Wrap up
avatar say "Great job today! Review the key terms and we'll have a quiz on Friday."
avatar hide
```

## Student Presentation Pattern

Students can use the avatar for class presentations:

```bash
avatar show
avatar say "My presentation is about the water cycle and its impact on agriculture."

avatar say "The water cycle has four main stages: evaporation, condensation, precipitation, and collection."
# ... show diagram ...

avatar say "In conclusion, understanding the water cycle helps farmers plan irrigation."
avatar hide
```

## Narrated Video Recording

Combine with screen recording for shareable lesson videos:

```bash
# Start recording
adom-cli hydrogen recording start --countdown 3

# Run the narrated lesson
avatar show
avatar say "Welcome to this video lesson on quadratic equations."
# ... work through examples ...
avatar say "Thanks for watching! Practice problems are on the wiki."
avatar hide

# Stop and save
adom-cli hydrogen recording stop --output ~/project/videos/quadratics-lesson.webm
```

## TTS Details

- **Engine:** Neural TTS
- **Voice:** en-US-AndrewNeural (clear, professional)
- **Latency:** ~100-300ms per sentence
- **Audio:** Played in-browser with Web Audio API, drives lip-sync via amplitude analysis

## Avatar Appearance

The avatar is a cartoonish 3D character rendered in Three.js:
- Round head with a Warriors cap (navy #1B2A4A)
- Gold round glasses (#C5A44E)
- Big friendly smile that animates during speech
- Gold Warriors shirt
- Transparent background, positioned in bottom-right corner
- Idle bobbing animation + eye blinks

## Use Cases

| Who | Use Case |
|-----|----------|
| **Teachers** | Create narrated video lessons for flipped classroom |
| **Teachers** | Record walkthroughs of complex procedures |
| **Students** | Add narration to class presentations |
| **Students** | Create explainer videos for STRIVE Center projects |
| **IT/Admin** | Record tutorial videos for new software |

## Troubleshooting

| Symptom | Fix |
|---------|-----|
| No audio | Check TTS service is running |
| Avatar not visible | Ensure the viewer panel is open |
| Mouth not moving | Audio may be blocked by browser autoplay policy — click the viewer first |
| TTS too fast/slow | Adjust speech rate in settings |
