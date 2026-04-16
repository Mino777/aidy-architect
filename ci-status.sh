#!/bin/bash
# CI Status — 3개 워커 repo의 GitHub Actions 결과 자동 수집
#
# 사용법:
#   ./ci-status.sh                         — 각 워커 최신 5건 요약
#   ./ci-status.sh --limit 10              — 건수 변경
#   ./ci-status.sh --branch main           — 특정 브랜치만
#   ./ci-status.sh --json                  — JSON 출력 (모니터링 통합용)
#   ./ci-status.sh --workflow test.yml     — 특정 워크플로만
#   ./ci-status.sh --since 24h             — 최근 24시간만 (h/d 단위)
#   ./ci-status.sh --watch                 — 실패 워크플로 한 줄 보고
#
# 종속성: gh CLI (인증 완료 상태)

set -euo pipefail

GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

WORKERS=(server ios android)
LIMIT=5
BRANCH=""
WORKFLOW=""
JSON=0
WATCH=0
SINCE=""

# ─── 인자 파싱 ───
while [ "$#" -gt 0 ]; do
    case "$1" in
        --limit)    LIMIT="$2"; shift 2 ;;
        --branch)   BRANCH="$2"; shift 2 ;;
        --workflow) WORKFLOW="$2"; shift 2 ;;
        --since)    SINCE="$2"; shift 2 ;;
        --json)     JSON=1; shift ;;
        --watch)    WATCH=1; shift ;;
        -h|--help)
            grep -E '^#' "$0" | sed 's/^# \{0,1\}//'
            exit 0 ;;
        *) echo "알 수 없는 옵션: $1" >&2; exit 1 ;;
    esac
done

# ─── 사전 체크 ───
if ! command -v gh >/dev/null 2>&1; then
    echo -e "${RED}gh CLI가 없습니다. brew install gh 후 gh auth login 하세요.${NC}" >&2
    exit 1
fi

if ! gh auth status >/dev/null 2>&1; then
    echo -e "${RED}gh 인증 안 됨. gh auth login 실행 필요.${NC}" >&2
    exit 1
fi

# ─── since 필터 (epoch 기준) ───
since_epoch=0
if [ -n "$SINCE" ]; then
    case "$SINCE" in
        *h) since_epoch=$(date -v-${SINCE%h}H +%s) ;;
        *d) since_epoch=$(date -v-${SINCE%d}d +%s) ;;
        *) echo -e "${RED}--since 형식: 24h, 7d 같은 형태${NC}" >&2; exit 1 ;;
    esac
fi

# ─── 핵심 — 워커별 fetch ───
fetch_worker() {
    local worker=$1
    local dir="$HOME/Develop/aidy-$worker"
    [ -d "$dir" ] || { echo "[skip] $dir 없음" >&2; return; }

    local repo
    repo=$(cd "$dir" && gh repo view --json nameWithOwner -q .nameWithOwner 2>/dev/null || echo "")
    [ -n "$repo" ] || { echo "[skip] $worker repo 정보 없음" >&2; return; }

    local args=(run list --repo "$repo" --limit "$LIMIT" \
                --json databaseId,name,status,conclusion,headBranch,event,createdAt,url,displayTitle,workflowName)
    [ -n "$BRANCH" ]   && args+=(--branch "$BRANCH")
    [ -n "$WORKFLOW" ] && args+=(--workflow "$WORKFLOW")

    local raw
    raw=$(gh "${args[@]}" 2>/dev/null || echo "[]")

    # since 필터
    if [ "$since_epoch" -gt 0 ]; then
        raw=$(echo "$raw" | jq --argjson cutoff "$since_epoch" \
            'map(select((.createdAt | fromdateiso8601) >= $cutoff))')
    fi

    # worker 라벨 부착
    echo "$raw" | jq --arg worker "$worker" --arg repo "$repo" \
        'map(. + {worker: $worker, repo: $repo})'
}

# ─── 모든 워커 데이터 수집 ───
all_data="[]"
for worker in "${WORKERS[@]}"; do
    chunk=$(fetch_worker "$worker")
    [ -n "$chunk" ] || chunk="[]"
    all_data=$(jq -s 'add' <(echo "$all_data") <(echo "$chunk"))
done

# ─── 출력 ───
if [ "$JSON" = "1" ]; then
    echo "$all_data"
    exit 0
fi

if [ "$WATCH" = "1" ]; then
    # 실패 워크플로만 한 줄 보고
    fails=$(echo "$all_data" | jq -r '
        map(select(.conclusion == "failure" or .conclusion == "cancelled" or .conclusion == "timed_out"))
        | sort_by(.createdAt) | reverse
        | .[] | "\(.worker)\t\(.workflowName)\t\(.headBranch)\t\(.conclusion)\t\(.url)"')
    if [ -z "$fails" ]; then
        echo -e "${GREEN}[CI OK] 실패한 최근 워크플로 없음${NC}"
        exit 0
    fi
    echo -e "${RED}[CI 실패]${NC}"
    echo "$fails" | column -t -s $'\t'
    exit 1
fi

# 표 형식 출력 (워커별 그룹)
for worker in "${WORKERS[@]}"; do
    rows=$(echo "$all_data" | jq -r --arg w "$worker" '
        map(select(.worker == $w))
        | sort_by(.createdAt) | reverse
        | .[] | "\(.conclusion // .status)\t\(.workflowName)\t\(.headBranch)\t\(.event)\t\(.createdAt[0:19])\t\(.displayTitle[0:50])"')
    echo -e "${CYAN}=== aidy-$worker ===${NC}"
    if [ -z "$rows" ]; then
        echo "  (CI 결과 없음)"
    else
        # 색상 부여
        echo "$rows" | while IFS=$'\t' read -r concl workflow branch event ts title; do
            case "$concl" in
                success)            color="$GREEN" ;;
                failure|cancelled)  color="$RED" ;;
                in_progress|queued) color="$YELLOW" ;;
                *)                  color="$NC" ;;
            esac
            printf "  ${color}%-12s${NC} %-20s %-12s %-15s %s  %s\n" \
                "$concl" "$workflow" "$branch" "$event" "$ts" "$title"
        done
    fi
    echo ""
done

# 요약
total=$(echo "$all_data" | jq 'length')
fail_count=$(echo "$all_data" | jq '[.[] | select(.conclusion == "failure" or .conclusion == "cancelled")] | length')
ip_count=$(echo "$all_data" | jq '[.[] | select(.status == "in_progress" or .status == "queued")] | length')
echo -e "${GREEN}[요약]${NC} 총 $total 건 · 실패 $fail_count · 진행중 $ip_count"
