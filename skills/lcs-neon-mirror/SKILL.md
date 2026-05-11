---
name: lcs-neon-mirror
description: Use when a student or teacher wants to mirror an Android device for OpenBot robotics, interact with an Android phone/tablet screen, view Android logcat, record touch macros, control display settings (DPI, resolution), or manage screen state. Designed for STRIVE Center robotics projects. Requires a USB-connected Android device on the service container.
user-invocable: true
---

# LCS NeonMirror — Android Device Mirroring for STRIVE Center Robotics

Mirror a USB-connected Android device in a webview with touch/keyboard interaction, logcat streaming, macro recording, and display settings control. Used by students for OpenBot robotics projects in the STRIVE Center.

## What the user asked

$ARGUMENTS

## Step 1: Display NeonMirror in a Webview

Open the NeonMirror interface in a Hydrogen webview tab so the student can interact with their Android device directly from their Chromebook.

```text
Open a webview tab pointing to the NeonMirror service URL.
```

## Step 2: Guide the Student

- **Start Mirror** — Click "Start Mirror" to begin screen mirroring
- **Touch/Click** — Click on the mirrored screen to tap, drag to swipe
- **Keyboard** — Focus the mirror canvas and type to send keystrokes
- **Logcat** — Switch to the Logcat tab, enter a package name (e.g., `org.openbot.robot`), and click Start to view app logs
- **Macros** — Switch to the Macros tab, name a macro, and click Record. Perform touch actions, then click Stop. Great for repeatable robot test sequences.
- **Display Settings** — Change DPI, resolution, or toggle screen on/off from the Settings tab
- **Console** — View raw adb/scrcpy output in the Console tab

## Features

- Real-time MJPEG screen mirroring via scrcpy
- Touch and keyboard input forwarding
- Auto-reconnect on device disconnect with retry loop
- USB device detection (polls adb devices every 3 seconds)
- Logcat viewer with package name and log level filtering
- DPI and resolution override controls
- Screen on/off and stay-awake-while-plugged toggle
- Touch macro recording and replay (useful for repeatable robot tests)
- Raw console output from adb, scrcpy, and ffmpeg

## Use Cases for Students

| Project | How NeonMirror Helps |
|---------|---------------------|
| OpenBot Robotics | Mirror the phone running OpenBot to see camera feed, sensor data, and control the robot remotely |
| Android App Development | Test and debug apps on a real device without needing the phone in hand |
| Data Collection | Record touch macros to automate repetitive data collection sequences |
| Presentations | Mirror a phone screen to a projector or display for class presentations |

## Service Health Check

```text
GET https://<neon-mirror-service-url>/health
```

Returns: `{ ok, service, state, device, mirroring, uptime }`

## WebSocket API

Connect to `wss://<service-url>/ws` for real-time communication.

### Commands (client to server)

| Type | Fields | Description |
|------|--------|-------------|
| `start_mirror` | `maxFps?`, `bitRate?`, `maxSize?` | Start mirroring |
| `stop_mirror` | — | Stop mirroring |
| `touch` | `action`, `x`, `y`, `width`, `height` | Touch event |
| `key` | `keyCode` | Android keyevent |
| `text` | `text` | Type text |
| `start_logcat` | `packageName?`, `level?` | Start logcat |
| `stop_logcat` | — | Stop logcat |
| `set_density` | `dpi` | Change DPI |
| `set_size` | `width`, `height` | Change resolution |
| `reset_display` | — | Reset display settings |
| `screen_on` / `screen_off` | — | Wake/sleep screen |
| `stay_awake` | `enabled` | Toggle stay on while plugged |
| `macro_start` | `name` | Start recording macro |
| `macro_stop` | — | Stop recording |
| `macro_play` | `name` | Replay macro |
| `macro_list` | — | List saved macros |
| `macro_delete` | `name` | Delete macro |

## Troubleshooting

- **No device detected**: Ensure USB debugging is enabled on the Android device and the device is connected via USB to the service container. Students should follow the STRIVE Center guide for enabling Developer Options.
- **Mirror won't start**: Check that adb, scrcpy, and ffmpeg are installed (`install-deps.sh`)
- **Black screen**: The device may need to be unlocked first. Use "Screen On" in Settings
- **High latency**: Reduce bitrate or max size in Settings tab
- **OpenBot app not showing**: Make sure the OpenBot app is installed and running on the phone before starting the mirror
