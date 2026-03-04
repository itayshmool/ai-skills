#!/usr/bin/env python3
"""Mixed Hebrew/English BiDi renderer.
Hebrew segments are converted to visual RTL order via fribidi.
English segments stay LTR. Mixed lines are handled per-segment."""

import subprocess
import sys


def is_hebrew_char(ch):
    return '\u0590' <= ch <= '\u05FF'


def fribidi(text):
    result = subprocess.run(
        ['fribidi', '--nopad'],
        input=text, capture_output=True, text=True
    )
    return result.stdout.strip()


def process_line(line):
    if not line.strip():
        return line

    has_hebrew = any(is_hebrew_char(ch) for ch in line)
    has_latin = any(ch.isascii() and ch.isalpha() for ch in line)

    if has_hebrew and not has_latin:
        # Pure Hebrew — full fribidi
        return fribidi(line)
    elif not has_hebrew:
        # Pure English — pass through
        return line
    else:
        # Mixed — split into segments by script
        segments = []
        current = ''
        current_is_heb = None

        for ch in line:
            if is_hebrew_char(ch):
                is_heb = True
            elif ch.isalpha() and ch.isascii():
                is_heb = False
            else:
                current += ch
                continue

            if current_is_heb is not None and is_heb != current_is_heb:
                segments.append((current.strip(), current_is_heb))
                current = ''
            current += ch
            current_is_heb = is_heb

        if current.strip():
            segments.append((current.strip(), current_is_heb))

        parts = []
        for seg, is_heb in segments:
            if is_heb:
                parts.append(fribidi(seg))
            else:
                parts.append(seg)

        return ' '.join(parts)


if __name__ == '__main__':
    if len(sys.argv) > 1:
        text = ' '.join(sys.argv[1:])
    else:
        text = sys.stdin.read()

    for line in text.splitlines():
        print(process_line(line))
