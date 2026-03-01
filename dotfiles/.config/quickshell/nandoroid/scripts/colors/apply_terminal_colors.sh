#!/usr/bin/env python3
import os
import sys

# Script to apply terminal colors globally.
# Reads the sequences file (containing raw bytes) and writes to all active PTYs.

SEQUENCES_FILE = os.path.expanduser("~/.local/state/quickshell/user/generated/terminal/sequences.txt")

if not os.path.exists(SEQUENCES_FILE):
    sys.exit(0)

def apply_colors():
    try:
        with open(SEQUENCES_FILE, "rb") as f:
            raw_data = f.read()

        for d in os.listdir("/dev/pts"):
            if d.isdigit():
                pts_path = os.path.join("/dev/pts", d)
                if os.access(pts_path, os.W_OK):
                    try:
                        with open(pts_path, "wb") as pts:
                            pts.write(raw_data)
                            pts.flush()
                    except Exception:
                        pass
    except Exception as e:
        print(f"Error applying colors: {e}", file=sys.stderr)

if __name__ == "__main__":
    apply_colors()
