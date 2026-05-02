#!/bin/bash
# build-gate.sh — PreToolUse(Bash) 커밋 전 빌드 검증
# 사용법: build-gate.sh <project_dir> <build_command>
# 예: build-gate.sh ~/Develop/aidy-server "./gradlew build"

CMD=$(echo "$CLAUDE_TOOL_INPUT" | jq -r '.command // empty' 2>/dev/null)
[ -z "$CMD" ] && exit 0

# git commit이 아니면 통과
echo "$CMD" | grep -qE 'git commit' || exit 0

PROJECT_DIR="${1:-.}"
BUILD_CMD="${2:-echo 'no build command'}"
LOG_FILE="/tmp/aidy-build-$(basename "$PROJECT_DIR").log"

cd "$PROJECT_DIR" || exit 0
echo "🔍 QA_GATE: $BUILD_CMD..."
eval "$BUILD_CMD" > "$LOG_FILE" 2>&1
BUILD_EXIT=$?

if [ $BUILD_EXIT -ne 0 ]; then
  echo "❌ QA_GATE FAILED: 빌드/테스트 실패" >&2
  grep -iE 'FAILED|error|Error' "$LOG_FILE" | head -10 >&2
  exit 2
fi
echo "✅ QA_GATE PASSED"
