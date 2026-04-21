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
        tmux_target="$TMUX_SESSION:0.${pane_idx}"
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
        tmux_target="$TMUX_SESSION:0.${pane_idx}"
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
작업 지시 (${wo_filename})

## 컨텍스트 로드 (순서대로)
1. ~/Develop/aidy-${target}/CLAUDE.md
2. ~/Develop/aidy-architect/specs/api-contract.md — 해당 섹션
3. ~/Develop/aidy-architect/specs/conventions.md
4. ~/Develop/aidy-architect/work-orders/in-progress/${wo_filename}
5. ~/Develop/aidy-architect/gates/test-policy.md + gates/test-policy-${target}.md

---

## 작업

work-order의 '구현 요구사항'을 하나씩 구현해.
목업이 있으면 (work-order의 **목업**: 필드) 해당 경로의 이미지를 참조하여 UI를 구현해.

### 완료 기준
- [ ] 빌드 PASS
- [ ] 응답 스키마가 api-contract 해당 섹션 필드와 일치
- [ ] 테스트: happy path + 에러 케이스 커버
- [ ] 테스트 실행 숫자 보고 (아래 명령 사용):
  - server: \`./gradlew test\` → "NN tests · 0 failures"
  - ios: \`xcodebuild test -workspace Aidy.xcworkspace -scheme Aidy -destination 'platform=iOS Simulator,name=iPhone 17,OS=latest'\` → "Test run with NN tests passed"
  - android: \`./gradlew testDebugUnitTest\` → "NN tests · 0 failures"

---

## 제약
- 금지: git push, 기존 Entity 구조 변경 (스펙에 명시된 경우 제외), 새 패키지 설치
- 커밋: 한글 메시지, 1건당 파일 10개 이하
- "빌드 통과" 만으로 "테스트 통과" 주장 금지
- "no tests to run" 나오면 즉시 인프라 이슈 → architect에 보고

## 완료 보고
모든 작업 완료 후:
\`tmux send-keys -t aidy:0.0 '[${target} 완료]' Enter\`
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

# ─── 시스템 헬스 체크 ───

preflight() {
    echo -e "${GREEN}[Preflight] 시스템 리소스 점검${NC}"

    # Swap 사용률 체크
    local swap_info swap_used swap_total swap_pct
    swap_info=$(sysctl -n vm.swapusage 2>/dev/null)
    if [[ -n "$swap_info" ]]; then
        swap_total=$(echo "$swap_info" | sed 's/.*total = \([0-9.]*\)M.*/\1/')
        swap_used=$(echo "$swap_info" | sed 's/.*used = \([0-9.]*\)M.*/\1/')
        if [[ -n "$swap_total" && "$swap_total" != "0.00" ]]; then
            swap_pct=$(echo "$swap_used $swap_total" | awk '{printf "%.0f", ($1/$2)*100}')
            if [ "$swap_pct" -ge 80 ]; then
                echo -e "${RED}  ⚠️  Swap ${swap_pct}% (${swap_used}M/${swap_total}M) — 워커 크래시 위험!${NC}"
                echo -e "${YELLOW}  → 불필요 앱 종료 후 시작 권장${NC}"
            else
                echo -e "${GREEN}  ✅ Swap ${swap_pct}% (${swap_used}M/${swap_total}M)${NC}"
            fi
        else
            echo -e "${GREEN}  ✅ Swap 미사용${NC}"
        fi
    fi

    # Claude 인스턴스 수 체크
    local claude_count
    claude_count=$(ps aux | grep -c "[c]laude")
    if [ "$claude_count" -ge 4 ]; then
        echo -e "${RED}  ⚠️  Claude 인스턴스 ${claude_count}개 — 16GB 머신 권장 최대 3개${NC}"
    else
        echo -e "${GREEN}  ✅ Claude 인스턴스 ${claude_count}개${NC}"
    fi

    # 총 메모리
    local total_mem
    total_mem=$(sysctl -n hw.memsize 2>/dev/null | awk '{printf "%.0f", $1/1024/1024/1024}')
    echo -e "${CYAN}  📊 시스템 메모리: ${total_mem}GB${NC}"
}

# ─── 빌드/테스트 직접 검증 ───

verify() {
    local target="${1:-all}"
    local failed=0

    verify_one() {
        local name=$1
        local dir="$HOME/Develop/aidy-$name"
        local build_cmd=$2
        local test_cmd=$3
        local test_parse=$4

        echo -e "${CYAN}[$name] 빌드 검증 시작${NC}"
        if ! (cd "$dir" && eval "$build_cmd" > /tmp/aidy-verify-$name-build.log 2>&1); then
            echo -e "${RED}[$name] 빌드 FAIL${NC}"
            tail -5 /tmp/aidy-verify-$name-build.log
            failed=1
            return 1
        fi
        echo -e "${GREEN}[$name] 빌드 PASS${NC}"

        echo -e "${CYAN}[$name] 테스트 실행${NC}"
        if ! (cd "$dir" && eval "$test_cmd" > /tmp/aidy-verify-$name-test.log 2>&1); then
            echo -e "${RED}[$name] 테스트 FAIL${NC}"
            tail -10 /tmp/aidy-verify-$name-test.log
            failed=1
            return 1
        fi

        local count
        count=$(cd "$dir" && eval "$test_parse" 2>/dev/null || echo "?")
        echo -e "${GREEN}[$name] 테스트 PASS — $count tests${NC}"
    }

    case "$target" in
        server)
            verify_one server \
                "./gradlew clean build -x test" \
                "./gradlew test" \
                "grep -oh 'tests=\"[0-9]*\"' build/test-results/test/TEST-*.xml | awk -F'\"' '{sum+=\$2} END{print sum}'"
            ;;
        ios)
            verify_one ios \
                "tuist generate --no-open && xcodebuild build -workspace Aidy.xcworkspace -scheme Aidy -destination 'platform=iOS Simulator,name=iPhone 17,OS=latest' -quiet" \
                "xcodebuild test -workspace Aidy.xcworkspace -scheme Aidy -destination 'platform=iOS Simulator,name=iPhone 17,OS=latest' -quiet" \
                "cat /tmp/aidy-verify-ios-test.log | grep -o 'with [0-9]* tests' | grep -o '[0-9]*'"
            ;;
        android)
            verify_one android \
                "./gradlew assembleDebug" \
                "./gradlew testDebugUnitTest" \
                "grep -oh 'tests=\"[0-9]*\"' app/build/test-results/testDebugUnitTest/TEST-*.xml | awk -F'\"' '{sum+=\$2} END{print sum}'"
            ;;
        all)
            echo -e "${GREEN}[Architect] 전체 워커 빌드/테스트 검증${NC}"
            echo "════════════════════════════════════"
            verify_one server \
                "./gradlew clean build -x test" \
                "./gradlew test" \
                "grep -oh 'tests=\"[0-9]*\"' build/test-results/test/TEST-*.xml | awk -F'\"' '{sum+=\$2} END{print sum}'"
            echo "────────────────────────────────────"
            verify_one android \
                "./gradlew assembleDebug" \
                "./gradlew testDebugUnitTest" \
                "grep -oh 'tests=\"[0-9]*\"' app/build/test-results/testDebugUnitTest/TEST-*.xml | awk -F'\"' '{sum+=\$2} END{print sum}'"
            echo "════════════════════════════════════"
            if [ "$failed" = "0" ]; then
                echo -e "${GREEN}[전체 검증 PASS]${NC}"
            else
                echo -e "${RED}[일부 검증 FAIL — 위 로그 확인]${NC}"
            fi
            ;;
        *)
            echo -e "${RED}[오류] verify <server|ios|android|all>${NC}"
            exit 1
            ;;
    esac
    return $failed
}

# ─── 워커 완료 감시 (pub/sub 대체: bash가 폴링, Claude에 알림) ───
# 사용법: ./architect-cli.sh watch-workers [timeout_sec]
# - bash가 30초마다 tmux pane을 확인 (토큰 0)
# - 전원 idle 되면 architect pane에 알림 전송
# - architect Claude는 이 알림을 유저 메시지로 받아서 다음 단계 진행
watch_workers() {
    local timeout="${1:-1800}"
    local poll=30
    local elapsed=0
    local workers=("server" "ios" "android")

    echo -e "${CYAN}[watch] 워커 완료 감시 시작 (timeout=${timeout}s, poll=${poll}s)${NC}"
    echo -e "${CYAN}  감시 대상: ${workers[*]}${NC}"

    # 첫 dispatch 직후 working 진입 대기
    sleep 10

    while [ "$elapsed" -lt "$timeout" ]; do
        local all_idle=true
        local status_line=""
        for w in "${workers[@]}"; do
            if is_pane_idle "$w"; then
                status_line="$status_line [$w:✅]"
            else
                all_idle=false
                status_line="$status_line [$w:⏳]"
            fi
        done

        if $all_idle; then
            echo -e "${GREEN}[watch] 전원 idle! (${elapsed}s)${NC}"

            # 각 워커 커밋 상태 수집
            local report=""
            for w in "${workers[@]}"; do
                local dir="$HOME/Develop/aidy-${w}"
                if [ -d "$dir" ]; then
                    local last_commit
                    last_commit=$(cd "$dir" && git log --oneline -1 2>/dev/null || echo "unknown")
                    report="$report\n  $w: $last_commit"
                fi
            done

            # architect pane에 알림 전송
            local notify_msg="[워커 전원 완료] ${elapsed}초 소요${report}"
            tmux send-keys -t "$TMUX_SESSION:0.0" "$notify_msg" Enter
            return 0
        fi

        sleep "$poll"
        elapsed=$((elapsed + poll))
    done

    echo -e "${YELLOW}[watch] timeout (${timeout}s) — 미완료 워커 있음${NC}"
    tmux send-keys -t "$TMUX_SESSION:0.0" "[워커 감시 timeout] ${timeout}초 경과. 수동 확인 필요." Enter
    return 1
}

# ─── 워커 재시작 (compound Phase 6용) ───

restart_workers() {
    echo -e "${GREEN}[워커 재시작]${NC} 3개 워커 종료 + 재시작..."

    local workers=("server" "ios" "android")
    local panes=(1 2 3)

    # 1단계: 각 워커에 /exit 전송 (Claude가 실행 중인 경우만)
    for i in 0 1 2; do
        local pane=${panes[$i]}
        local worker=${workers[$i]}
        local tmux_target="$TMUX_SESSION:0.${pane}"

        # pane에 Claude가 돌고 있는지 확인 (프롬프트에 ❯ 또는 bypass 표시)
        local pane_content
        pane_content=$(tmux capture-pane -t "$tmux_target" -p 2>/dev/null | tail -5)

        if echo "$pane_content" | grep -qE "❯|bypass|esc to interrupt"; then
            echo -e "  ${CYAN}[$worker]${NC} Claude 실행 중 → /exit 전송"
            tmux send-keys -t "$tmux_target" "/exit" Enter
        else
            echo -e "  ${YELLOW}[$worker]${NC} Claude 미실행 (shell 상태)"
        fi
    done

    # 2단계: 모든 Claude 프로세스 종료 대기 (최대 10초)
    echo -e "  ${CYAN}종료 대기 중...${NC}"
    local wait_count=0
    while [ $wait_count -lt 10 ]; do
        local all_exited=true
        for pane in "${panes[@]}"; do
            local tmux_target="$TMUX_SESSION:0.${pane}"
            local content
            content=$(tmux capture-pane -t "$tmux_target" -p 2>/dev/null | tail -3)
            # shell 프롬프트 (% 또는 $)가 보이면 종료된 것
            if ! echo "$content" | grep -qE "^[a-z].*[%\$] *$"; then
                all_exited=false
            fi
        done
        if $all_exited; then
            break
        fi
        sleep 1
        wait_count=$((wait_count + 1))
    done
    echo -e "  ${GREEN}종료 확인 (${wait_count}초)${NC}"

    # 3단계: 재시작
    for i in 0 1 2; do
        local pane=${panes[$i]}
        local worker=${workers[$i]}
        local tmux_target="$TMUX_SESSION:0.${pane}"

        # 혹시 남은 텍스트 정리
        tmux send-keys -t "$tmux_target" C-c 2>/dev/null || true
        sleep 0.5
        tmux send-keys -t "$tmux_target" "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1 claude --dangerously-skip-permissions" Enter
        echo -e "  ${GREEN}[$worker]${NC} Claude 재시작됨"
    done

    # 4단계: 시작 확인 (최대 15초)
    echo -e "  ${CYAN}시작 확인 중...${NC}"
    sleep 10
    local ok_count=0
    for i in 0 1 2; do
        local pane=${panes[$i]}
        local worker=${workers[$i]}
        local tmux_target="$TMUX_SESSION:0.${pane}"
        local content
        content=$(tmux capture-pane -t "$tmux_target" -p 2>/dev/null | tail -5)
        if echo "$content" | grep -qE "❯|bypass"; then
            echo -e "  ${GREEN}[$worker]${NC} ✅ ready"
            ok_count=$((ok_count + 1))
        else
            echo -e "  ${YELLOW}[$worker]${NC} ⚠️ 시작 미확인 — 수동 확인 필요"
        fi
    done
    echo -e "${GREEN}[완료]${NC} $ok_count/3 워커 재시작됨"
}

# ─── 크래시 진단 (FAIL 축 개선: 원인 분류 + MTTR 추적) ───

crash_diagnose() {
    local target=$1
    local crash_dir="$ARCH_DIR/docs/crash-logs"
    mkdir -p "$crash_dir"
    local timestamp=$(date '+%Y-%m-%d_%H%M%S')
    local log_file="$crash_dir/${timestamp}_${target}.md"

    local pane_idx
    pane_idx=$(get_pane_index "$target")
    local tmux_target="$TMUX_SESSION:0.${pane_idx}"

    # 1. pane 전체 캡처 (최대 500줄)
    local pane_capture
    pane_capture=$(tmux capture-pane -t "$tmux_target" -p -S -500 2>/dev/null || echo "(캡처 실패)")

    # 2. 시스템 상태 수집
    local swap_info mem_pressure claude_count
    swap_info=$(sysctl -n vm.swapusage 2>/dev/null || echo "unknown")
    mem_pressure=$(memory_pressure 2>/dev/null | head -5 || echo "unknown")
    claude_count=$(ps aux | grep -c "[c]laude")

    # 3. 원인 분류
    local cause="UNKNOWN"
    if echo "$pane_capture" | grep -qi "out of memory\|OOM\|killed"; then
        cause="OOM"
    elif echo "$pane_capture" | grep -qi "token\|context.*limit\|too long"; then
        cause="TOKEN_OVERFLOW"
    elif echo "$pane_capture" | grep -qi "rate limit\|429\|too many"; then
        cause="RATE_LIMIT"
    elif echo "$pane_capture" | grep -qi "network\|connection\|timeout\|ECONNRESET"; then
        cause="NETWORK"
    elif echo "$pane_capture" | grep -qi "error\|panic\|crash"; then
        cause="ERROR"
    elif echo "$pane_capture" | grep -qi "Tip:.*resume\|continue"; then
        cause="SESSION_END"
    fi

    # 4. 로그 파일 작성
    cat > "$log_file" << CRASHEOF
# Crash Log: $target ($timestamp)

## 원인 분류: $cause

## 시스템 상태
- Swap: $swap_info
- Claude 인스턴스: ${claude_count}개
- Memory Pressure: $(echo "$mem_pressure" | head -1)

## Pane 캡처 (마지막 50줄)
\`\`\`
$(echo "$pane_capture" | tail -50)
\`\`\`
CRASHEOF

    echo -e "${RED}[crash-log] $target 크래시 진단: $cause${NC}"
    echo -e "${CYAN}  로그: $log_file${NC}"
    echo "$cause"
}

# ─── 메인 라우터 ───

advise() {
    local target="$1"
    local advise_file="$ARCH_DIR/inbox/${target}-advise.md"
    local advice_file="$ARCH_DIR/inbox/${target}-advice.md"

    if [[ ! -f "$advise_file" ]]; then
        echo -e "${RED}[Advisor] ${target}-advise.md 없음${NC}"
        return 1
    fi

    echo -e "${CYAN}[Advisor] ${target} 자문 요청 수신${NC}"
    echo "────────────────────────────────────"
    cat "$advise_file"
    echo "────────────────────────────────────"

    # 답변 파일이 이미 있으면 전송
    if [[ -f "$advice_file" ]]; then
        echo -e "${GREEN}[Advisor] 답변 파일 발견 → ${target}에 전송${NC}"
        tmux_send "$target" "[자문답변] ~/Develop/aidy-architect/inbox/${target}-advice.md 읽고 작업 재개해. 읽은 후 advise + advice 파일 모두 삭제."
        return 0
    fi

    echo -e "${YELLOW}[Advisor] inbox/${target}-advice.md 에 답변을 작성하세요.${NC}"
    echo -e "${YELLOW}  작성 후: ./architect-cli.sh advise-reply ${target}${NC}"
}

advise_reply() {
    local target="$1"
    local advise_file="$ARCH_DIR/inbox/${target}-advise.md"
    local advice_file="$ARCH_DIR/inbox/${target}-advice.md"

    if [[ ! -f "$advice_file" ]]; then
        echo -e "${RED}[Advisor] ${target}-advice.md 없음 — 먼저 답변 파일을 작성하세요${NC}"
        return 1
    fi

    echo -e "${GREEN}[Advisor] ${target}에 답변 전송${NC}"
    tmux_send "$target" "[자문답변] ~/Develop/aidy-architect/inbox/${target}-advice.md 읽고 작업 재개해. 읽은 후 advise + advice 파일 모두 삭제."
}

case "${1:-help}" in
    tmux-setup)  tmux_setup ;;
    send)        tmux_send "$2" "$3" ;;
    send-seq)    shift; tmux_send_sequential "$@" ;;
    wait-idle)   wait_for_idle "$2" "${3:-1800}" ;;
    run)         cli_run "$2" "$3" ;;
    run-all)     cli_run_all ;;
    preflight)   preflight ;;
    verify)      verify "${2:-all}" ;;
    restart-workers) restart_workers ;;
    watch-workers)   watch_workers "${2:-1800}" ;;
    crash-log)       crash_diagnose "$2" ;;
    advise)          advise "$2" ;;
    advise-reply)    advise_reply "$2" ;;
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
        echo "시스템:"
        echo "  ./architect-cli.sh preflight                                        — Swap/메모리/인스턴스 점검"
        echo ""
        echo "검증:"
        echo "  ./architect-cli.sh verify <server|ios|android|all>                  — 빌드+테스트 직접 검증"
        echo ""
        echo "크래시 진단:"
        echo "  ./architect-cli.sh crash-log <target>                               — 크래시 원인 분류 + 로그 저장"
        echo ""
        echo "Advisor 자문:"
        echo "  ./architect-cli.sh advise <target>                                  — 워커 자문 요청 확인 + 답변 전송"
        echo "  ./architect-cli.sh advise-reply <target>                            — 답변 파일 작성 후 워커에게 전송"
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
