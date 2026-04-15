#!/bin/bash
# Worker Monitor — 워커 완료 감지 + 상태 파일 갱신
# Architect의 Claude Code가 주기적으로 읽을 상태 파일을 생성한다.
#
# 사용: ./worker-monitor.sh &

ARCH_DIR="$HOME/Develop/aidy-architect"
STATUS_FILE="$ARCH_DIR/inbox/worker-status.json"
INTERVAL=10

while true; do
    statuses="{"
    for pane_idx in 1 2 3; do
        case $pane_idx in
            1) worker="server" ;;
            2) worker="ios" ;;
            3) worker="android" ;;
        esac

        # pane의 마지막 출력에서 상태 판단
        last_lines=$(tmux capture-pane -t aidy:architect.$pane_idx -p 2>/dev/null | grep -v "^$" | tail -5)

        if echo "$last_lines" | grep -q "bypass permissions on\|accept edits on\|? for shortcuts"; then
            # 프롬프트 대기 = 작업 완료 또는 아이들
            if echo "$last_lines" | grep -q "esc to interrupt\|ctrl+t"; then
                state="working"
            else
                state="idle"
            fi
        elif echo "$last_lines" | grep -q "zsh\|%\|\$"; then
            state="no-claude"
        else
            state="working"
        fi

        statuses="$statuses\"$worker\":\"$state\","
    done
    statuses="${statuses%,}}"

    echo "$statuses" > "$STATUS_FILE"
    sleep "$INTERVAL"
done
