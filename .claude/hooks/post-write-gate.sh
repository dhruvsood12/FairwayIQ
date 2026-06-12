#!/bin/bash
# PostToolUse gate for Edit|Write on Swift files: lints the changed file with
# swiftformat and runs swift test when the change touches the SwiftPM package.
# Exit 2 reports the failure back so it gets fixed before work continues.

FILE_PATH=$(python3 -c '
import json, sys
payload = json.load(sys.stdin)
print(payload.get("tool_input", {}).get("file_path", ""))
')

case "$FILE_PATH" in
  *.swift) ;;
  *) exit 0 ;;
esac

REPO_ROOT="$FILE_PATH"
while [ "$REPO_ROOT" != "/" ]; do
  REPO_ROOT=$(dirname "$REPO_ROOT")
  [ -f "$REPO_ROOT/Package.swift" ] && break
done
if [ ! -f "$REPO_ROOT/Package.swift" ]; then
  exit 0
fi

if command -v swiftformat >/dev/null 2>&1; then
  LINT_OUT=$(swiftformat --lint "$FILE_PATH" 2>&1)
  if [ $? -ne 0 ]; then
    echo "swiftformat --lint failed for $FILE_PATH:" >&2
    echo "$LINT_OUT" >&2
    exit 2
  fi
else
  echo "warning: swiftformat not installed; lint gate skipped (brew install swiftformat)" >&2
fi

case "$FILE_PATH" in
  "$REPO_ROOT"/Sources/*|"$REPO_ROOT"/Tests/*)
    TEST_OUT=$(cd "$REPO_ROOT" && swift test 2>&1)
    if [ $? -ne 0 ]; then
      echo "swift test failed after editing $FILE_PATH:" >&2
      echo "$TEST_OUT" | tail -30 >&2
      exit 2
    fi
    ;;
esac

exit 0
