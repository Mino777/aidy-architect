#!/bin/bash
# block-dangerous.sh — PreToolUse(Bash) 위험 명령 차단
# jq로 구조화된 JSON 파싱, exit 2로 차단

CMD=$(echo "$CLAUDE_TOOL_INPUT" | jq -r '.command // empty' 2>/dev/null)
[ -z "$CMD" ] && exit 0

if echo "$CMD" | grep -qEi 'git\s+reset\s+--hard|git\s+push\s+(-f|--force)|rm\s+-rf|DROP\s+TABLE'; then
  echo "🚫 금지된 명령입니다: $(echo "$CMD" | head -c 80)" >&2
  exit 2
fi
