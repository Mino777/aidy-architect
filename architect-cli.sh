#!/bin/bash
# Aidy Architect CLI — 멀티 에이전트 오케스트레이션
#
# 모드 1: tmux 기반 (권장 — 시각적 관제)
#   ./architect-cli.sh tmux-setup     → tmux 4개 윈도우 생성 + Claude Code 실행
#   ./architect-cli.sh send <target> "<prompt>"  → tmux send-keys
#
# 모드 2: Claude CLI 병렬 실행 (VS Code 터미널에서 사용)
#   ./architect-cli.sh run <target> "<prompt>"   → claude -p 로 원샷 실행
#   ./architect-cli.sh run-all                   → 전체 WO 병렬 실행
#
# 공통:
#   ./architect-cli.sh wo <number>    → WO를 backlog→in-progress 이동 + 프롬프트 생성

set -euo pipefail

TMUX_SESSION="aidy"
ARCH_DIR="$HOME/Develop/aidy-architect"
WO_DIR="$ARCH_DIR/work-orders"

GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# ─── tmux 모드 ───

tmux_setup() {
    echo -e "${GREEN}[Architect] tmux 관제 세션 생성${NC}"

    tmux kill-session -t "$TMUX_SESSION" 2>/dev/null || true

    tmux new-session -d -s "$TMUX_SESSION" -n "architect" -c "$ARCH_DIR"
    tmux new-window -t "$TMUX_SESSION" -n "server" -c "$HOME/Develop/aidy-server"
    tmux new-window -t "$TMUX_SESSION" -n "ios" -c "$HOME/Develop/aidy-ios"
    tmux new-window -t "$TMUX_SESSION" -n "android" -c "$HOME/Develop/aidy-android"

    # 각 윈도우에서 Claude Code 시작
    for w in server ios android; do
        tmux send-keys -t "$TMUX_SESSION:$w" "claude" C-m
        echo -e "${CYAN}  [$w] Claude Code 시작${NC}"
    done

    echo ""
    echo -e "${GREEN}완료! 접속: tmux attach -t $TMUX_SESSION${NC}"
    echo -e "  Ctrl+B → 0: architect"
    echo -e "  Ctrl+B → 1: server"
    echo -e "  Ctrl+B → 2: ios"
    echo -e "  Ctrl+B → 3: android"
}

# pane 매핑 (architect 윈도우에 합친 경우)
# pane 0: architect, pane 1: server, pane 2: ios, pane 3: android
get_pane_index() {
    case "$1" in
        server)  echo 1 ;;
        ios)     echo 2 ;;
        android) echo 3 ;;
        *)       echo "" ;;
    esac
}

tmux_send() {
    local target=$1
    local prompt=$2
    echo -e "${GREEN}[Architect → $target]${NC} 전송 중..."

    local pane_idx
    pane_idx=$(get_pane_index "$target")

    # 먼저 윈도우로 시도, 없으면 pane으로 fallback
    if tmux list-windows -t "$TMUX_SESSION" -F '#{window_name}' 2>/dev/null | grep -q "^${target}$"; then
        tmux send-keys -t "$TMUX_SESSION:$target" "$prompt" C-m
    elif [[ -n "$pane_idx" ]]; then
        tmux send-keys -t "$TMUX_SESSION:architect.${pane_idx}" "$prompt" C-m
    else
        echo -e "${RED}[오류] $target 윈도우/pane을 찾을 수 없습니다.${NC}"
        exit 1
    fi
    echo -e "${GREEN}[완료]${NC}"
}

# ─── Claude CLI 모드 (VS Code 호환) ───

cli_run() {
    local target=$1
    local prompt=$2
    local cwd="$HOME/Develop/aidy-$target"

    echo -e "${GREEN}[Architect → $target]${NC} claude -p 실행..."
    claude -p "$prompt" --cwd "$cwd" &
    echo -e "${CYAN}  PID: $!${NC}"
}

cli_run_all() {
    echo -e "${GREEN}[Architect] 전체 워커 병렬 실행${NC}"

    for wo_file in "$WO_DIR/in-progress"/WO-*.md; do
        [ -f "$wo_file" ] || continue
        local target=$(grep "^\*\*담당\*\*:" "$wo_file" | sed 's/.*: //')
        local filename=$(basename "$wo_file")
        local prompt=$(build_prompt "$target" "$filename")
        cli_run "$target" "$prompt"
    done

    echo -e "${YELLOW}wait 중... (모든 워커 완료 대기)${NC}"
    wait
    echo -e "${GREEN}[전체 완료]${NC}"
}

# ─── Work Order 관리 ───

build_prompt() {
    local target=$1
    local wo_filename=$2

    cat <<EOF
너는 aidy-${target} 워커야. 아래 파일을 순서대로 읽고 작업을 시작해:

1. ~/Develop/aidy-${target}/CLAUDE.md
2. ~/Develop/aidy-architect/specs/api-contract.md
3. ~/Develop/aidy-architect/specs/conventions.md
4. ~/Develop/aidy-architect/work-orders/in-progress/${wo_filename}

work-order의 '구현 요구사항'을 하나씩 구현하고, 완료되면 git commit해줘. 커밋 메시지는 한글로.
EOF
}

wo_activate() {
    local wo_num=$1
    local wo_file=$(find "$WO_DIR/backlog" -name "WO-${wo_num}*" 2>/dev/null | head -1)

    if [ -z "$wo_file" ]; then
        echo -e "${RED}WO-${wo_num}을 backlog에서 찾을 수 없습니다.${NC}"
        exit 1
    fi

    local filename=$(basename "$wo_file")
    local target=$(grep "^\*\*담당\*\*:" "$wo_file" | sed 's/.*: //')

    # backlog → in-progress
    mv "$wo_file" "$WO_DIR/in-progress/$filename"
    sed -i '' 's/\*\*상태\*\*: backlog/**상태**: in-progress/' "$WO_DIR/in-progress/$filename"

    echo -e "${GREEN}[WO-${wo_num}] backlog → in-progress (담당: $target)${NC}"
    echo ""
    echo -e "${YELLOW}워커에게 보낼 프롬프트:${NC}"
    echo "────────────────────────────────────"
    build_prompt "$target" "$filename"
    echo "────────────────────────────────────"
    echo ""
    echo -e "tmux 모드: ${CYAN}./architect-cli.sh send $target \"$(build_prompt $target $filename | head -1)...\"${NC}"
    echo -e "CLI 모드:  ${CYAN}./architect-cli.sh run $target \"...\"${NC}"
}

wo_complete() {
    local wo_num=$1
    local wo_file=$(find "$WO_DIR/in-progress" -name "WO-${wo_num}*" 2>/dev/null | head -1)

    if [ -z "$wo_file" ]; then
        echo -e "${RED}WO-${wo_num}을 in-progress에서 찾을 수 없습니다.${NC}"
        exit 1
    fi

    local filename=$(basename "$wo_file")
    mv "$wo_file" "$WO_DIR/done/$filename"
    sed -i '' 's/\*\*상태\*\*: in-progress/**상태**: done/' "$WO_DIR/done/$filename"
    echo -e "${GREEN}[WO-${wo_num}] in-progress → done ✅${NC}"
}

# ─── 메인 라우터 ───

case "${1:-help}" in
    tmux-setup)  tmux_setup ;;
    send)        tmux_send "$2" "$3" ;;
    run)         cli_run "$2" "$3" ;;
    run-all)     cli_run_all ;;
    wo)          wo_activate "$2" ;;
    wo-done)     wo_complete "$2" ;;
    status)
        echo -e "${GREEN}[Work Orders]${NC}"
        echo -e "  ${YELLOW}Backlog:${NC}"
        ls "$WO_DIR/backlog/" 2>/dev/null || echo "    (비어있음)"
        echo -e "  ${CYAN}In Progress:${NC}"
        ls "$WO_DIR/in-progress/" 2>/dev/null || echo "    (비어있음)"
        echo -e "  ${GREEN}Done:${NC}"
        ls "$WO_DIR/done/" 2>/dev/null || echo "    (비어있음)"
        ;;
    *)
        echo "Aidy Architect CLI — 멀티 에이전트 오케스트레이션"
        echo ""
        echo "tmux 모드 (시각적 관제):"
        echo "  ./architect-cli.sh tmux-setup           — 4 세션 생성"
        echo "  ./architect-cli.sh send <target> \"msg\"   — 워커에게 명령"
        echo ""
        echo "CLI 모드 (VS Code 호환):"
        echo "  ./architect-cli.sh run <target> \"msg\"    — claude -p 원샷"
        echo "  ./architect-cli.sh run-all               — 전체 병렬 실행"
        echo ""
        echo "Work Order:"
        echo "  ./architect-cli.sh wo <number>           — WO 활성화"
        echo "  ./architect-cli.sh wo-done <number>      — WO 완료"
        echo "  ./architect-cli.sh status                — 현황"
        ;;
esac
