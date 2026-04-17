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

    # 대상 tmux target 결정 — 윈도우 우선, pane 폴백
    local tmux_target
    if tmux list-windows -t "$TMUX_SESSION" -F '#{window_name}' 2>/dev/null | grep -q "^${target}$"; then
        tmux_target="$TMUX_SESSION:$target"
    elif [[ -n "$pane_idx" ]]; then
        tmux_target="$TMUX_SESSION:architect.${pane_idx}"
    else
        echo -e "${RED}[오류] $target 윈도우/pane을 찾을 수 없습니다.${NC}"
        exit 1
    fi

    # 프롬프트 히스토리 로깅 (프롬프트 엔지니어링 학습용)
    # 파일명: docs/worker-prompts/YYYY-MM-DD.md (날짜별 append)
    local log_dir="$ARCH_DIR/docs/worker-prompts"
    mkdir -p "$log_dir"
    local log_file="$log_dir/$(date '+%Y-%m-%d').md"
    if [[ ! -f "$log_file" ]]; then
        printf '# 워커 프롬프트 로그 — %s\n\n> architect-cli.sh `send` 로 워커에게 보낸 프롬프트 원문. 프롬프트 엔지니어링 학습/회고용.\n\n' "$(date '+%Y-%m-%d')" > "$log_file"
    fi
    {
        printf '\n---\n\n## %s → %s\n\n' "$(date '+%H:%M:%S')" "$target"
        printf '```\n%s\n```\n' "$prompt"
    } >> "$log_file"

    # Paste-buffer 경유로 긴 프롬프트도 안정적으로 전송
    # (send-keys 직접 전달 시 긴 텍스트가 buffered paste 형태로 들어가서 Enter flush 실패하는 경우 회피)
    local buf_name="aidy_send_$$_$RANDOM"
    tmux set-buffer -b "$buf_name" "$prompt"
    tmux paste-buffer -b "$buf_name" -t "$tmux_target"
    tmux delete-buffer -b "$buf_name" 2>/dev/null

    # Enter flush — 최대 5회 재시도 + 실행 확인
    local attempt
    local confirmed=0
    for attempt in 1 2 3 4 5; do
        tmux send-keys -t "$tmux_target" C-m
        sleep 1.5

        # pane 캡처 — 실행 시작 여부 판별
        local tail
        tail=$(tmux capture-pane -t "$tmux_target" -p | tail -5 | tr -d '\n')

        # 아직 paste/input 상태 — 재시도
        if [[ "$tail" == *"Pasted text"* || "$tail" == *"[Pasted"* ]]; then
            continue
        fi

        # 실행 확인: Claude CLI 실행 마커 감지 (스피너, 도구 호출, 진행 표시)
        if [[ "$tail" == *"⠋"* || "$tail" == *"⠙"* || "$tail" == *"⠹"* || "$tail" == *"⠸"* || \
              "$tail" == *"⠼"* || "$tail" == *"⠴"* || "$tail" == *"⠦"* || "$tail" == *"⠧"* || \
              "$tail" == *"Reading"* || "$tail" == *"Searching"* || "$tail" == *"Running"* || \
              "$tail" == *"Editing"* || "$tail" == *"Writing"* || \
              "$tail" == *"⎿"* || "$tail" == *"Brewing"* || "$tail" == *"Ebbing"* ]]; then
            confirmed=1
            break
        fi

        # input 프롬프트(❯)에 텍스트가 남아있으면 아직 미제출 — 재시도
        if [[ "$tail" == *"❯"*"읽"* || "$tail" == *"❯"*"CLAUDE"* || \
              "$tail" == *"❯"*"작업"* || "$tail" == *"❯"*"커밋"* ]]; then
            echo -e "${YELLOW}  [attempt $attempt/5] 프롬프트가 input에 남아있음 — Enter 재시도${NC}"
            continue
        fi
    done

    # 최종 확인: 5초 후 한 번 더 체크
    if [[ "$confirmed" == "0" ]]; then
        sleep 5
        local final_check
        final_check=$(tmux capture-pane -t "$tmux_target" -p | tail -5 | tr -d '\n')
        if [[ "$final_check" == *"esc to interrupt"* || "$final_check" == *"ctrl+t"* || \
              "$final_check" == *"Reading"* || "$final_check" == *"Running"* || \
              "$final_check" == *"Brewing"* || "$final_check" == *"Ebbing"* ]]; then
            confirmed=1
        else
            echo -e "${RED}[경고] $target 실행 확인 실패 — tmux pane 수동 확인 필요${NC}"
            echo -e "${YELLOW}  tmux capture: $(echo "$final_check" | tail -c 120)${NC}"
        fi
    fi

    # 429 / rate-limit 감지 + backoff (P3-8)
    # 환경변수로 제어:
    #   AIDY_SEND_429_DETECT=0   : 비활성 (기본 1)
    #   AIDY_SEND_429_WATCH=30   : 감지 윈도우 초 (기본 30)
    #   AIDY_SEND_429_BACKOFF=300: 백오프 초 (기본 5분)
    #   AIDY_SEND_429_RETRY=1    : 재시도 횟수 (기본 1)
    if [[ "${AIDY_SEND_429_DETECT:-1}" == "1" && "${AIDY_SEND_NO_429:-0}" != "1" ]]; then
        local watch_sec="${AIDY_SEND_429_WATCH:-30}"
        local backoff_sec="${AIDY_SEND_429_BACKOFF:-300}"
        local max_retry="${AIDY_SEND_429_RETRY:-1}"
        local retry_count="${AIDY_SEND_429_TRY_NUM:-0}"

        local elapsed=0
        local hit_429=0
        local hit_pattern=""
        while [ "$elapsed" -lt "$watch_sec" ]; do
            local capture
            capture=$(tmux capture-pane -t "$tmux_target" -p | tail -20)
            # Claude Code의 rate-limit 메시지 패턴 (대소문자 무시)
            if echo "$capture" | grep -iqE '(rate limit|429|too many requests|usage limit reached|retry[- ]after|claude usage limit|api error 529)'; then
                hit_429=1
                hit_pattern=$(echo "$capture" | grep -iE '(rate limit|429|too many requests|usage limit reached|retry[- ]after|claude usage limit|api error 529)' | head -1 | tr -s ' ' | cut -c1-80)
                break
            fi
            sleep 2
            elapsed=$((elapsed + 2))
        done

        if [ "$hit_429" = "1" ]; then
            echo -e "${RED}[429 감지] $target — \"$hit_pattern\"${NC}"
            if [ "$retry_count" -lt "$max_retry" ]; then
                echo -e "${YELLOW}[backoff] ${backoff_sec}s 대기 후 재시도 ($((retry_count+1))/$max_retry)...${NC}"
                sleep "$backoff_sec"
                AIDY_SEND_429_TRY_NUM=$((retry_count + 1)) tmux_send "$target" "$prompt"
                return $?
            else
                echo -e "${RED}[중단] $target 재시도 한도 초과. 수동 개입 필요.${NC}"
                return 2
            fi
        fi
    fi

    echo -e "${GREEN}[완료]${NC}"
}

# ─── Idle 감지 + Sequential dispatch (P3-7) ───

# pane이 idle 상태인지 판정 — worker-monitor.sh와 동일 로직
is_pane_idle() {
    local target=$1
    local pane_idx
    pane_idx=$(get_pane_index "$target")
    local tmux_target
    if tmux list-windows -t "$TMUX_SESSION" -F '#{window_name}' 2>/dev/null | grep -q "^${target}$"; then
        tmux_target="$TMUX_SESSION:$target"
    elif [[ -n "$pane_idx" ]]; then
        tmux_target="$TMUX_SESSION:architect.${pane_idx}"
    else
        return 2
    fi
    local last_lines
    last_lines=$(tmux capture-pane -t "$tmux_target" -p 2>/dev/null | grep -v "^$" | tail -5)
    # "esc to interrupt" / "ctrl+t" → 작업 중. 그 외 프롬프트 시그니처는 idle.
    if echo "$last_lines" | grep -q "esc to interrupt\|ctrl+t"; then
        return 1  # working
    fi
    if echo "$last_lines" | grep -q "bypass permissions on\|accept edits on\|? for shortcuts"; then
        return 0  # idle
    fi
    return 1  # 알 수 없음 → working으로 취급 (안전)
}

# 워커가 idle 될 때까지 대기 (timeout 초 default 1800)
wait_for_idle() {
    local target=$1
    local timeout="${2:-1800}"
    local poll="${AIDY_IDLE_POLL_SEC:-15}"
    local elapsed=0
    echo -e "${CYAN}[wait] $target idle 대기 (timeout=${timeout}s, poll=${poll}s)${NC}"
    # 첫 dispatch 직후엔 working 상태 진입까지 살짝 여유
    sleep 5
    while [ "$elapsed" -lt "$timeout" ]; do
        if is_pane_idle "$target"; then
            echo -e "${GREEN}[idle] $target 작업 종료 감지 (${elapsed}s)${NC}"
            return 0
        fi
        sleep "$poll"
        elapsed=$((elapsed + poll))
    done
    echo -e "${YELLOW}[timeout] $target ${timeout}s 내 idle 미감지 — 다음 단계 진행${NC}"
    return 1
}

# 직렬 dispatch — 가변 인자: target1 "prompt1" target2 "prompt2" ...
# 각 워커 dispatch 후 idle 될 때까지 대기. AIDY_SEQ_TIMEOUT (default 1800s) 로 워커당 timeout 제어.
tmux_send_sequential() {
    if [ "$#" -lt 2 ] || [ $(($# % 2)) -ne 0 ]; then
        echo -e "${RED}[오류] send-seq 사용법: send-seq <target1> \"<prompt1>\" [<target2> \"<prompt2>\" ...]${NC}"
        exit 1
    fi
    local seq_timeout="${AIDY_SEQ_TIMEOUT:-1800}"
    local total=$(( $# / 2 ))
    local idx=1
    while [ "$#" -gt 0 ]; do
        local target=$1
        local prompt=$2
        shift 2
        echo -e "${GREEN}[seq ${idx}/${total}] → $target${NC}"
        tmux_send "$target" "$prompt"
        if [ "$#" -gt 0 ]; then
            wait_for_idle "$target" "$seq_timeout" || true
        fi
        idx=$((idx + 1))
    done
    echo -e "${GREEN}[seq 완료]${NC} 마지막 워커 idle 대기는 생략 (수동 확인)."
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
5. ~/Develop/aidy-architect/gates/test-policy.md + gates/test-policy-${target}.md

work-order의 '구현 요구사항'을 하나씩 구현하고, 완료되면 git commit해줘. 커밋 메시지는 한글로.

⚠️ 테스트 실행 증거 필수 (autoceo-s4 교훈):
- 커밋 전 반드시 실제 테스트 실행하고 숫자 보고:
  - server: \`./gradlew test\` → "NN tests · 0 failures"
  - ios: \`xcodebuild test -workspace Aidy.xcworkspace -scheme Aidy -destination 'platform=iOS Simulator,name=iPhone 17,OS=latest'\` → "Test run with NN tests passed"
  - android: \`./gradlew testDebugUnitTest\` → "NN tests · 0 failures"
- "빌드 통과" 만으로 "테스트 통과" 주장 금지
- "no tests to run" 나오면 즉시 인프라 이슈 → architect에 보고
- 커밋 메시지 또는 inbox 파일에 숫자 포함
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
    send-seq)    shift; tmux_send_sequential "$@" ;;
    wait-idle)   wait_for_idle "$2" "${3:-1800}" ;;
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
        echo "  ./architect-cli.sh tmux-setup                                      — 4 세션 생성"
        echo "  ./architect-cli.sh send <target> \"msg\"                              — 워커에게 명령 (429 자동 backoff)"
        echo "  ./architect-cli.sh send-seq <t1> \"m1\" <t2> \"m2\" [...]               — 직렬 dispatch (idle 대기)"
        echo "  ./architect-cli.sh wait-idle <target> [timeout=1800]                — 워커 idle까지 대기"
        echo ""
        echo "CLI 모드 (VS Code 호환):"
        echo "  ./architect-cli.sh run <target> \"msg\"                               — claude -p 원샷"
        echo "  ./architect-cli.sh run-all                                          — 전체 병렬 실행"
        echo ""
        echo "Work Order:"
        echo "  ./architect-cli.sh wo <number>                                      — WO 활성화"
        echo "  ./architect-cli.sh wo-done <number>                                 — WO 완료"
        echo "  ./architect-cli.sh status                                           — 현황"
        echo ""
        echo "환경 변수:"
        echo "  AIDY_SEND_429_DETECT  (default 1)   — 429 감지 활성/비활성"
        echo "  AIDY_SEND_429_WATCH   (default 30)  — 감지 윈도우 초"
        echo "  AIDY_SEND_429_BACKOFF (default 300) — 백오프 초"
        echo "  AIDY_SEND_429_RETRY   (default 1)   — 재시도 횟수"
        echo "  AIDY_SEND_NO_429      (default 0)   — 단일 호출에서 감지 비활성"
        echo "  AIDY_SEQ_TIMEOUT      (default 1800)— send-seq 워커당 idle 대기 timeout 초"
        echo "  AIDY_IDLE_POLL_SEC    (default 15)  — idle 폴링 주기 초"
        ;;
esac
