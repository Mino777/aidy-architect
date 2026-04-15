#!/bin/bash
# Aidy Inbox Watcher — 워커 요청 감시
# 사용: ./inbox-watcher.sh (백그라운드: ./inbox-watcher.sh &)
#
# inbox/ 디렉토리에 *-request.md 파일이 생기면 알림.
# Architect pane에 알림을 표시한다.

INBOX="$HOME/Develop/aidy-architect/inbox"
INTERVAL=5  # 초

RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m'

echo -e "${GREEN}[Inbox Watcher] 시작 (${INTERVAL}초 간격 감시)${NC}"

while true; do
    for req in "$INBOX"/*-request.md; do
        [ -f "$req" ] || continue
        worker=$(basename "$req" | sed 's/-request.md//')

        echo ""
        echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${RED}📨 [$worker] 워커 요청 도착!${NC}"
        echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        cat "$req"
        echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${YELLOW}응답: inbox/${worker}-response.md 에 작성${NC}"
        echo ""

        # macOS 알림 (터미널이 백그라운드여도 알림)
        osascript -e "display notification \"${worker} 워커가 도움을 요청합니다\" with title \"Aidy Architect\" sound name \"Ping\"" 2>/dev/null || true
    done
    sleep "$INTERVAL"
done
