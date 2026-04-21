#!/bin/bash
# auto-gate1.sh — 커밋 시점 자동 스펙 검증 (Hook용)
# 워커의 PreToolUse hook에서 git commit 감지 시 실행
# 사용법: auto-gate1.sh <project-type> <project-dir>
#   project-type: server | ios | android
#   project-dir: 프로젝트 루트 경로

set -euo pipefail

PROJECT_TYPE="${1:-}"
PROJECT_DIR="${2:-}"
CONTRACT="$HOME/Develop/aidy-architect/specs/api-contract.md"
RESULT_FILE="/tmp/auto-gate1-${PROJECT_TYPE}.log"

if [[ -z "$PROJECT_TYPE" || -z "$PROJECT_DIR" ]]; then
    echo "Usage: auto-gate1.sh <server|ios|android> <project-dir>"
    exit 1
fi

if [[ ! -f "$CONTRACT" ]]; then
    echo "⚠️ AUTO-GATE1: api-contract.md 없음 — 스킵"
    exit 0
fi

ERRORS=0
WARNINGS=0

# ── 서버 검증 ──
check_server() {
    cd "$PROJECT_DIR"

    # 1. Controller의 엔드포인트 추출
    local endpoints
    endpoints=$(grep -rn '@\(Get\|Post\|Put\|Delete\|Patch\)Mapping' src/main/kotlin/ 2>/dev/null | \
        grep -v test | grep -v Test | \
        sed 's/.*Mapping("\(.*\)").*/\1/' | sort -u)

    # 2. 새로 추가된 엔드포인트가 스펙에 있는지 확인
    local staged_files
    staged_files=$(git diff --cached --name-only 2>/dev/null || git diff HEAD~1 --name-only 2>/dev/null || echo "")

    local new_controllers
    new_controllers=$(echo "$staged_files" | grep -i "controller" | grep -v test || true)

    if [[ -n "$new_controllers" ]]; then
        for ctrl_file in $new_controllers; do
            if [[ -f "$ctrl_file" ]]; then
                local ctrl_endpoints
                ctrl_endpoints=$(grep -oE 'Mapping\("[^"]+' "$ctrl_file" 2>/dev/null | sed 's/Mapping("//' || true)
                for ep in $ctrl_endpoints; do
                    if ! grep -q "$ep" "$CONTRACT" 2>/dev/null; then
                        echo "❌ 스펙에 없는 엔드포인트: $ep (in $ctrl_file)"
                        ERRORS=$((ERRORS + 1))
                    fi
                done
            fi
        done
    fi

    # 3. 새 에러코드가 스펙에 있는지 확인
    local new_error_codes
    new_error_codes=$(git diff --cached -- src/ 2>/dev/null | grep -oE '"[A-Z_]{5,}"' | sed 's/"//g' | sort -u || \
                      git diff HEAD~1 -- src/ 2>/dev/null | grep -oE '"[A-Z_]{5,}"' | sed 's/"//g' | sort -u || true)

    for code in $new_error_codes; do
        # 일반적인 문자열은 스킵 (CONTENT, CREATE 등)
        if echo "$code" | grep -qE '_NOT_FOUND$|_EXISTS$|_ERROR$|_EXCEEDED$|_INVALID$|UNAUTHORIZED|RATE_LIMITED|AI_'; then
            if ! grep -q "$code" "$CONTRACT" 2>/dev/null; then
                echo "⚠️ 스펙에 없는 에러코드: $code"
                WARNINGS=$((WARNINGS + 1))
            fi
        fi
    done

    # 4. DTO 필드명이 camelCase인지 확인
    local new_dtos
    new_dtos=$(echo "$staged_files" | grep -i "dto\|Dto" | grep -v test || true)

    if [[ -n "$new_dtos" ]]; then
        for dto_file in $new_dtos; do
            if [[ -f "$dto_file" ]]; then
                local snake_fields
                snake_fields=$(grep -oE 'val [a-z]+_[a-z]+' "$dto_file" 2>/dev/null || true)
                if [[ -n "$snake_fields" ]]; then
                    echo "❌ DTO snake_case 필드 발견 (camelCase 필수): $dto_file"
                    echo "   $snake_fields"
                    ERRORS=$((ERRORS + 1))
                fi
            fi
        done
    fi
}

# ── iOS 검증 ──
check_ios() {
    cd "$PROJECT_DIR"

    # 1. API Client의 URL 경로가 스펙과 일치하는지
    local staged_files
    staged_files=$(git diff --cached --name-only 2>/dev/null || git diff HEAD~1 --name-only 2>/dev/null || echo "")

    local new_clients
    new_clients=$(echo "$staged_files" | grep -i "client\|Client" | grep -v test || true)

    if [[ -n "$new_clients" ]]; then
        for client_file in $new_clients; do
            if [[ -f "$client_file" ]]; then
                local api_paths
                api_paths=$(grep -oE '"/api/[^"]+' "$client_file" 2>/dev/null | sed 's/^"//' || true)
                for path in $api_paths; do
                    # 동적 경로 파라미터 제거하고 확인
                    local clean_path
                    clean_path=$(echo "$path" | sed 's/\\(.*//' | sed 's/\${.*//')
                    if ! grep -q "$clean_path" "$CONTRACT" 2>/dev/null; then
                        echo "⚠️ 스펙에 없는 API 경로: $path (in $client_file)"
                        WARNINGS=$((WARNINGS + 1))
                    fi
                done
            fi
        done
    fi
}

# ── Android 검증 ──
check_android() {
    cd "$PROJECT_DIR"

    # 1. Retrofit @GET/@POST 경로가 스펙과 일치하는지
    local staged_files
    staged_files=$(git diff --cached --name-only 2>/dev/null || git diff HEAD~1 --name-only 2>/dev/null || echo "")

    local new_apis
    new_apis=$(echo "$staged_files" | grep -iE "api\|Api" | grep -v test || true)

    if [[ -n "$new_apis" ]]; then
        for api_file in $new_apis; do
            if [[ -f "$api_file" ]]; then
                local api_paths
                api_paths=$(grep -oE '@(GET|POST|PUT|DELETE|PATCH)\("[^"]+' "$api_file" 2>/dev/null | sed 's/@[A-Z]*("//' || true)
                for path in $api_paths; do
                    local clean_path
                    clean_path=$(echo "$path" | sed 's/{[^}]*}//')
                    if ! grep -q "$(echo "$clean_path" | sed 's|/api||')" "$CONTRACT" 2>/dev/null; then
                        echo "⚠️ 스펙에 없는 Retrofit 경로: $path (in $api_file)"
                        WARNINGS=$((WARNINGS + 1))
                    fi
                done
            fi
        done
    fi

    # 2. data class 필드 snake_case 확인
    local new_models
    new_models=$(echo "$staged_files" | grep -iE "model\|dto\|response\|request" | grep -v test || true)

    if [[ -n "$new_models" ]]; then
        for model_file in $new_models; do
            if [[ -f "$model_file" ]]; then
                local snake_fields
                snake_fields=$(grep -oE 'val [a-z]+_[a-z]+' "$model_file" 2>/dev/null || true)
                if [[ -n "$snake_fields" ]]; then
                    echo "❌ data class snake_case 필드 (camelCase 필수): $model_file"
                    ERRORS=$((ERRORS + 1))
                fi
            fi
        done
    fi
}

# ── 실행 ──
echo "🔍 AUTO-GATE1: ${PROJECT_TYPE} 스펙 검증..."

case "$PROJECT_TYPE" in
    server)  check_server ;;
    ios)     check_ios ;;
    android) check_android ;;
    *)       echo "Unknown project type: $PROJECT_TYPE"; exit 1 ;;
esac

# ── 결과 ──
{
    echo "project=$PROJECT_TYPE"
    echo "errors=$ERRORS"
    echo "warnings=$WARNINGS"
    echo "timestamp=$(date +%Y-%m-%dT%H:%M:%S)"
} > "$RESULT_FILE"

if [[ $ERRORS -gt 0 ]]; then
    echo "❌ AUTO-GATE1 FAILED: ${ERRORS}개 에러, ${WARNINGS}개 경고"
    echo "   스펙 위반을 수정한 후 다시 커밋하세요."
    exit 1
elif [[ $WARNINGS -gt 0 ]]; then
    echo "⚠️ AUTO-GATE1 WARN: ${WARNINGS}개 경고 (커밋은 진행)"
    exit 0
else
    echo "✅ AUTO-GATE1 PASS: 스펙 일치 확인"
    exit 0
fi
