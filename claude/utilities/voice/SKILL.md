---
name: voice
description: Voice input - record and transcribe speech to text using Whisper. Supports Hebrew and English.
allowed-tools: Bash
argument-hint: "[stop]"
---

# Voice Input Skill

Voice recording for speech-to-text. Supports **Hebrew** and **English** (auto-detected).

## How it works

- `/voice` — **toggles** recording. First call starts, second call stops and transcribes.
- `/voice stop` — explicitly stops and transcribes.

Both commands return **instantly** (no blocking).

## Instructions

When the user invokes `/voice`, run the toggle:

```bash
~/.claude/skills/voice/voice.sh toggle
```

If the user passes `/voice stop`:

```bash
~/.claude/skills/voice/voice.sh stop
```

### Interpreting the output

- `RECORDING_STARTED`: Tell the user "Recording... speak now, then type `/voice` again when done."
- `TRANSCRIBING...` followed by `TRANSCRIPTION_START` ... `TRANSCRIPTION_END`: Extract the text between those markers. Present it to the user, then **treat it as if the user typed that text** — respond to it naturally.
- `ERROR`: Report it clearly.

### Language

Default is auto-detect. User can set `WHISPER_LANG=he` or `WHISPER_LANG=en` env var.

### Important

- For ANY response containing Hebrew text, pipe it through the BiDi renderer: `echo "your text" | python3 ~/.claude/skills/voice/bidi.py` — this converts Hebrew parts to RTL while keeping English parts LTR. Include the rendered output in your response instead of raw Hebrew.
- For pure English responses, just respond normally.
- The transcribed text IS the user's message — act on it just like typed input.
