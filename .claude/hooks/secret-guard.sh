#!/bin/bash
# secret-guard.sh — Edit/Write 시 시크릿 유출 차단
# Exit 2 = 도구 실행 차단 (exit 1은 경고만, 실행됨!)

FORBIDDEN=(
  'sk-[a-zA-Z0-9]{20,}'         # OpenAI
  'sk-ant-[a-zA-Z0-9]{20,}'     # Anthropic
  'ghp_[a-zA-Z0-9]{36}'         # GitHub PAT
  'AKIA[0-9A-Z]{16}'            # AWS Access Key
  'AIza[0-9A-Za-z_-]{35}'       # Google API Key
  'xoxb-[0-9]{10,}'             # Slack Bot Token
  'glpat-[a-zA-Z0-9_-]{20,}'   # GitLab PAT
)

# $CLAUDE_TOOL_INPUT contains the file content being written
INPUT="${CLAUDE_TOOL_INPUT:-}"

for pattern in "${FORBIDDEN[@]}"; do
  if echo "$INPUT" | grep -qE "$pattern" 2>/dev/null; then
    echo "🚫 SECRET GUARD: API 키/시크릿 패턴 감지 ($pattern)" >&2
    echo "파일에 시크릿을 직접 포함하지 마세요. 환경변수를 사용하세요." >&2
    exit 2
  fi
done
