#!/usr/bin/env python3
"""PreToolUse guard for Edit|Write: rejects writes into .build/ or any write
that would produce a file over 1 MB. Exit 2 blocks the tool call."""

import json
import os
import sys

payload = json.load(sys.stdin)
tool_input = payload.get("tool_input", {})
path = tool_input.get("file_path", "")
if not path:
    sys.exit(0)

normalized = os.path.normpath(path)
parts = normalized.split(os.sep)
if ".build" in parts or "DerivedData" in parts:
    print(f"BLOCKED: refusing to write build artifact path: {path}", file=sys.stderr)
    sys.exit(2)

LIMIT = 1_000_000
content = tool_input.get("content")
if content is not None:
    projected = len(content.encode("utf-8"))
else:
    try:
        current = os.path.getsize(path)
    except OSError:
        current = 0
    old = tool_input.get("old_string", "") or ""
    new = tool_input.get("new_string", "") or ""
    projected = current - len(old.encode("utf-8")) + len(new.encode("utf-8"))

if projected > LIMIT:
    print(
        f"BLOCKED: write would produce a {projected}-byte file (limit 1 MB): {path}",
        file=sys.stderr,
    )
    sys.exit(2)

sys.exit(0)
