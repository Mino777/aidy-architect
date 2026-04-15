#!/bin/bash
# Architect Dispatch — 워커 세션에 Work Order 기반 명령 전송
# 사용법: ./dispatch.sh <wo-number>
# 예시:  ./dispatch.sh 001   → WO-001을 서버 워커에게 전송

TMUX_SESSION="aidy"
WO_DIR="$HOME/Develop/aidy-architect/work-orders"

dispatch_wo() {
    local wo_num=$1
    local wo_file=$(find "$WO_DIR/backlog" -name "WO-${wo_num}*" 2>/dev/null | head -1)

    if [ -z "$wo_file" ]; then
        wo_file=$(find "$WO_DIR/in-progress" -name "WO-${wo_num}*" 2>/dev/null | head -1)
    fi

    if [ -z "$wo_file" ]; then
        echo "WO-${wo_num} 파일을 찾을 수 없습니다."
        exit 1
    fi

    # WO 파일에서 담당 세션 추출
    local target=$(grep "^\\*\\*담당\\*\\*:" "$wo_file" | sed 's/.*: //')

    # backlog → in-progress 이동
    local filename=$(basename "$wo_file")
    if [[ "$wo_file" == *"backlog"* ]]; then
        mv "$wo_file" "$WO_DIR/in-progress/$filename"
        echo "[이동] backlog → in-progress: $filename"
        wo_file="$WO_DIR/in-progress/$filename"
        # 상태 업데이트
        sed -i '' 's/\*\*상태\*\*: backlog/**상태**: in-progress/' "$wo_file"
    fi

    # 워커 세션에 보낼 프롬프트 구성
    local prompt="너는 aidy-${target} 워커야. 아래 파일을 순서대로 읽고 작업을 시작해:

1. ~/Develop/aidy-${target}/CLAUDE.md
2. ~/Develop/aidy-architect/specs/api-contract.md
3. ~/Develop/aidy-architect/specs/conventions.md
4. ~/Develop/aidy-architect/work-orders/in-progress/${filename}

work-order의 '구현 요구사항'을 하나씩 구현하고, 완료되면 git commit해줘. 커밋 메시지는 한글로."

    echo "[Architect → $target] WO-${wo_num} 전송 중..."
    tmux send-keys -t "$TMUX_SESSION:$target" "$prompt" C-m
    echo "[완료] $target 워커가 작업을 시작합니다."
}

dispatch_wo "$1"
