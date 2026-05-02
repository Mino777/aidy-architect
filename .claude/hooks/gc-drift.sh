#!/bin/bash
# gc-drift.sh — SessionStart 하네스 드리프트 감지
# 세션 시작 시 4가지 건강 체크

PROJECT_ROOT="${CLAUDE_PROJECT_DIR:-.}"
WARNINGS=0

# 1. CLAUDE.md 줄 수 체크 (≤ 250)
if [ -f "$PROJECT_ROOT/CLAUDE.md" ]; then
  LINES=$(wc -l < "$PROJECT_ROOT/CLAUDE.md")
  if [ "$LINES" -gt 250 ]; then
    echo "⚠️ DRIFT: CLAUDE.md가 ${LINES}줄 — 250줄 이하로 Skills/Rules 분리 필요" >&2
    WARNINGS=$((WARNINGS + 1))
  fi
fi

# 2. settings.json에 deny 있는지
if [ -f "$PROJECT_ROOT/.claude/settings.json" ]; then
  if ! grep -q '"deny"' "$PROJECT_ROOT/.claude/settings.json" 2>/dev/null; then
    echo "⚠️ DRIFT: settings.json에 deny 규칙 없음 — 보안 갭" >&2
    WARNINGS=$((WARNINGS + 1))
  fi
fi

# 3. hooks/ 에 .sh 파일 있는지
HOOK_COUNT=$(find "$PROJECT_ROOT/.claude/hooks" -name "*.sh" 2>/dev/null | wc -l)
if [ "$HOOK_COUNT" -eq 0 ]; then
  echo "⚠️ DRIFT: hooks/ 에 스크립트 없음 — 자동화 누락" >&2
  WARNINGS=$((WARNINGS + 1))
fi

# 4. .claude/ 에 빈 .md 파일
EMPTY_FILES=$(find "$PROJECT_ROOT/.claude" -name "*.md" -empty 2>/dev/null | wc -l)
if [ "$EMPTY_FILES" -gt 0 ]; then
  echo "⚠️ DRIFT: .claude/ 에 빈 .md 파일 ${EMPTY_FILES}개 — 정리 권장" >&2
  WARNINGS=$((WARNINGS + 1))
fi

if [ "$WARNINGS" -gt 0 ]; then
  echo "📋 하네스 드리프트 ${WARNINGS}건 감지. 위 항목을 확인하세요."
fi
