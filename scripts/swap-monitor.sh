#!/bin/bash
# Swap 모니터 — 80% 초과 시 macOS 알림
# crontab: */5 * * * * /Users/jominho/Develop/aidy-architect/scripts/swap-monitor.sh

THRESHOLD=80

eval $(sysctl vm.swapusage | awk '{
  gsub(/M/, "", $4); gsub(/M/, "", $7);
  printf "TOTAL=%s\nUSED=%s\n", $4, $7
}')

if (( $(echo "$TOTAL == 0" | bc -l) )); then
  exit 0
fi

PERCENT=$(echo "$USED / $TOTAL * 100" | bc -l | cut -d. -f1)

if [ "$PERCENT" -ge "$THRESHOLD" ]; then
  osascript -e "display notification \"Swap ${PERCENT}% 사용 중. 재부팅 필요!\" with title \"⚠️ Swap 경고\" sound name \"Funk\""
fi
