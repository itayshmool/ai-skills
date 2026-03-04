#!/usr/bin/env bash
# Voice recording and transcription script for Claude Code /voice skill
# Supports Hebrew and English via whisper.cpp

set -euo pipefail

VOICE_DIR="${HOME}/.claude/voice"
PID_FILE="${VOICE_DIR}/rec.pid"
FULL_AUDIO="${VOICE_DIR}/full_recording.wav"
MODEL="${WHISPER_MODEL:-${HOME}/whisper-models/ggml-large-v3-turbo-q5_0.bin}"
LANG="${WHISPER_LANG:-auto}"

mkdir -p "$VOICE_DIR"

start() {
    # Kill any existing recording
    if [[ -f "$PID_FILE" ]]; then
        local old_pid
        old_pid=$(cat "$PID_FILE")
        kill "$old_pid" 2>/dev/null || true
        rm -f "$PID_FILE"
    fi

    rm -f "$FULL_AUDIO"

    # Start recording in background using nohup so it survives
    nohup rec -q -r 16000 -c 1 -b 16 "$FULL_AUDIO" > /dev/null 2>&1 &
    local rec_pid=$!
    echo "$rec_pid" > "$PID_FILE"

    # Verify it started
    sleep 0.3
    if kill -0 "$rec_pid" 2>/dev/null; then
        echo "RECORDING_STARTED"
    else
        rm -f "$PID_FILE"
        echo "ERROR: Failed to start recording. Check microphone permissions."
        exit 1
    fi
}

stop() {
    if [[ ! -f "$PID_FILE" ]]; then
        echo "ERROR: No active recording found. Start one with '/voice' first."
        exit 1
    fi

    local pid
    pid=$(cat "$PID_FILE")

    if kill -0 "$pid" 2>/dev/null; then
        kill "$pid" 2>/dev/null || true
        sleep 0.5
    fi
    rm -f "$PID_FILE"

    if [[ ! -f "$FULL_AUDIO" ]]; then
        echo "ERROR: No audio file found."
        exit 1
    fi

    local file_size
    file_size=$(stat -f%z "$FULL_AUDIO" 2>/dev/null || echo "0")
    if [[ "$file_size" -lt 5000 ]]; then
        echo "ERROR: Audio too short ($file_size bytes). Did you speak?"
        rm -f "$FULL_AUDIO"
        exit 1
    fi

    if [[ ! -f "$MODEL" ]]; then
        echo "ERROR: Whisper model not found at $MODEL"
        rm -f "$FULL_AUDIO"
        exit 1
    fi

    echo "TRANSCRIBING..."

    local segments_dir="${VOICE_DIR}/segments"
    rm -rf "$segments_dir"
    mkdir -p "$segments_dir"

    # Split audio on silence (pause >= 0.8s at -35dB threshold)
    # This separates language switches since people naturally pause between them
    sox "$FULL_AUDIO" "$segments_dir/seg_.wav" silence 1 0.3 0.5% 1 0.8 0.5% : newfile : restart 2>/dev/null || true

    # Collect segment files (skip empty/tiny ones)
    local segments=()
    for f in "$segments_dir"/seg_*.wav; do
        [[ -f "$f" ]] || continue
        local sz
        sz=$(stat -f%z "$f" 2>/dev/null || echo "0")
        if [[ "$sz" -gt 5000 ]]; then
            segments+=("$f")
        fi
    done

    local transcription=""

    if [[ ${#segments[@]} -gt 1 ]]; then
        # Multiple segments: transcribe each with auto-detect for mixed language support
        for seg in "${segments[@]}"; do
            local seg_text
            seg_text=$(whisper-cli \
                -m "$MODEL" \
                -l auto \
                -f "$seg" \
                --no-timestamps \
                -t 8 \
                2>/dev/null | sed '/^$/d' | sed 's/^ *//')
            if [[ -n "$seg_text" ]] && ! [[ "$seg_text" =~ ^\[.*\]$ ]]; then
                transcription="${transcription} ${seg_text}"
            fi
        done
    else
        # Single segment or splitting failed: transcribe whole file
        transcription=$(whisper-cli \
            -m "$MODEL" \
            -l "$LANG" \
            -f "$FULL_AUDIO" \
            --no-timestamps \
            -t 8 \
            2>/dev/null | sed '/^$/d' | sed 's/^ *//')
    fi

    rm -f "$FULL_AUDIO"
    rm -rf "$segments_dir"

    # Trim whitespace
    transcription=$(echo "$transcription" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

    if [[ -z "$transcription" ]]; then
        echo "ERROR: Transcription returned empty. Try speaking louder or longer."
        exit 1
    fi

    echo "TRANSCRIPTION_START"
    echo "$transcription"
    echo "TRANSCRIPTION_END"
}

status() {
    if [[ -f "$PID_FILE" ]] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
        echo "RECORDING_ACTIVE"
    else
        rm -f "$PID_FILE" 2>/dev/null
        echo "RECORDING_INACTIVE"
    fi
}

case "${1:-toggle}" in
    start)
        start
        ;;
    stop)
        stop
        ;;
    status)
        status
        ;;
    toggle)
        if [[ -f "$PID_FILE" ]] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
            stop
        else
            start
        fi
        ;;
    *)
        echo "Usage: $0 {start|stop|status|toggle}"
        exit 1
        ;;
esac
