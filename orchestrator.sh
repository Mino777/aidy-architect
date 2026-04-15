#!/bin/bash
# Aidy Architect Orchestrator — tmux 기반 멀티 세션 관제
# 사용법:
#   ./orchestrator.sh setup    — tmux 세션 4개 생성 + Claude Code 실행
#   ./orchestrator.sh dispatch <session> "<prompt>"  — 워커에게 명령 전송
#   ./orchestrator.sh dispatch-all "<prompt>"         — 전체 워커에게 명령
#   ./orchestrator.sh status   — 각 세션 상태 확인
#   ./orchestrator.sh teardown — 전체 세션 종료

TMUX_SESSION="aidy"
ARCHITECT="architect"
SERVER="server"
IOS="ios"
ANDROID="android"

# 색상
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m'

setup() {
    echo -e "${GREEN}[Architect] tmux 세션 셋업 시작${NC}"

    # 메인 tmux 세션 생성 (architect 윈도우)
    tmux new-session -d -s "$TMUX_SESSION" -n "$ARCHITECT" -c "$HOME/Develop/aidy-architect"

    # 워커 윈도우 3개 생성
    tmux new-window -t "$TMUX_SESSION" -n "$SERVER" -c "$HOME/Develop/aidy-server"
    tmux new-window -t "$TMUX_SESSION" -n "$IOS" -c "$HOME/Develop/aidy-ios"
    tmux new-window -t "$TMUX_SESSION" -n "$ANDROID" -c "$HOME/Develop/aidy-android"

    # 각 워커 윈도우에서 Claude Code 실행
    echo -e "${CYAN}[Server] Claude Code 시작${NC}"
    tmux send-keys -t "$TMUX_SESSION:$SERVER" "claude" C-m

    echo -e "${CYAN}[iOS] Claude Code 시작${NC}"
    tmux send-keys -t "$TMUX_SESSION:$IOS" "claude" C-m

    echo -e "${CYAN}[Android] Claude Code 시작${NC}"
    tmux send-keys -t "$TMUX_SESSION:$ANDROID" "claude" C-m

    # Architect 윈도우에서도 Claude Code 실행
    tmux send-keys -t "$TMUX_SESSION:$ARCHITECT" "claude" C-m

    echo -e "${GREEN}[Architect] 셋업 완료!${NC}"
    echo -e "  tmux attach -t $TMUX_SESSION  로 접속"
    echo -e "  Ctrl+B → 숫자  로 윈도우 전환"
    echo ""
    echo -e "${YELLOW}워커에게 명령 보내기:${NC}"
    echo "  ./orchestrator.sh dispatch server \"WO-001 작업 시작해\""
    echo "  ./orchestrator.sh dispatch ios \"WO-002 작업 시작해\""
    echo "  ./orchestrator.sh dispatch android \"WO-003 작업 시작해\""
}

dispatch() {
    local target=$1
    local prompt=$2

    if [ -z "$target" ] || [ -z "$prompt" ]; then
        echo -e "${RED}사용법: ./orchestrator.sh dispatch <server|ios|android> \"<prompt>\"${NC}"
        exit 1
    fi

    echo -e "${GREEN}[Architect → $target] 명령 전송:${NC}"
    echo -e "${CYAN}$prompt${NC}"
    echo ""

    # tmux send-keys로 해당 세션에 직접 입력
    tmux send-keys -t "$TMUX_SESSION:$target" "$prompt" C-m

    echo -e "${GREEN}[전송 완료]${NC} $target 윈도우에서 실행 중..."
}

dispatch_all() {
    local prompt=$1
    echo -e "${GREEN}[Architect → ALL] 전체 워커에게 명령 전송${NC}"
    dispatch "$SERVER" "$prompt"
    dispatch "$IOS" "$prompt"
    dispatch "$ANDROID" "$prompt"
}

status() {
    echo -e "${GREEN}[Architect] 세션 상태 확인${NC}"
    echo ""
    tmux list-windows -t "$TMUX_SESSION" 2>/dev/null || echo -e "${RED}tmux 세션이 없습니다. ./orchestrator.sh setup 먼저 실행하세요.${NC}"
}

teardown() {
    echo -e "${YELLOW}[Architect] 전체 세션 종료${NC}"
    tmux kill-session -t "$TMUX_SESSION" 2>/dev/null
    echo -e "${GREEN}완료${NC}"
}

# 서브커맨드 라우팅
case "$1" in
    setup)     setup ;;
    dispatch)  dispatch "$2" "$3" ;;
    dispatch-all) dispatch_all "$2" ;;
    status)    status ;;
    teardown)  teardown ;;
    *)
        echo "Aidy Architect Orchestrator"
        echo ""
        echo "사용법:"
        echo "  ./orchestrator.sh setup                          — tmux 세션 생성"
        echo "  ./orchestrator.sh dispatch <session> \"<prompt>\"  — 워커에게 명령"
        echo "  ./orchestrator.sh dispatch-all \"<prompt>\"         — 전체 워커에게"
        echo "  ./orchestrator.sh status                         — 상태 확인"
        echo "  ./orchestrator.sh teardown                       — 전체 종료"
        ;;
esac
