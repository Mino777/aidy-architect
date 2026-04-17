# Architect 핸드오프 — 2026-04-17 세션 8 (CI 인프라 독립화 4 WO)

## 세션 8 요약 (WO-012/014/015/016 + ADR-010)

**키워드**: Node.js 24 호환 + self-hosted runner 통합 + Hybrid fallback 패턴 + Mark-step 우회

**WO-012 (Node.js 24 호환) → billing 차단 발견 → 방향 전환**
- 3 리포 send-seq 직렬 dispatch (P3-7 첫 실전)
- iOS: green + merged (self-hosted 덕에 billing 무관)
- server/android: billing 차단으로 blocked → self-hosted 전환 결정 (ADR-010)

**WO-014 (server self-hosted) + WO-015 (android self-hosted + SDK 통합)**
- Architect 선행: 3 runner 등록 + JDK 17 + Android SDK 35 세팅
- server: 207 tests · 0 failures, actions/cache hang 발견→제거
- android: 135 tests · 0 failures, JDK 21 요구 발견 (spec 보정)

**WO-016 (Hybrid fallback)**
- `continue-on-error` masking 버그 발견 → Mark-step 우회 패턴 (ADR-010 §8)
- android 긴급 tmux 알림 → server main cross-check → merge 가드 패턴 추가 발견
- server/android 장애 시나리오 실증 완료 (primary fail → fallback green 3초 지연)

## WO 현황 (세션 8 종료 시점)

- done: WO-001 ~ 016 (16건)
- backlog: WO-011 (Swift 6 Sendable) / WO-013 (워크플로 통합)
- in-progress: 없음

## 다음 세션 시작 전 체크

1. **billing 상태 확인**: `gh api /repos/Mino777/aidy-server/actions/runs --jq '.workflow_runs[0] | {conclusion, created_at}'` — billing 복구 시 정상 시나리오 검증 필요 (WO-016 deferred)
2. **3 runner 상태**: `gh api /repos/Mino777/aidy-{ios,server,android}/actions/runners --jq '.runners[] | {name,status,busy}'`
3. **MBA 디스크**: `df -h /` — Android SDK + Gradle 캐시 누적 추적 (현재 61GB 여유)

## ADR 현황 (총 10건)

- ADR-001 ~ 008: 기존
- ADR-009: iOS self-hosted runner (WO-010, s7)
- **ADR-010**: Server/Android self-hosted + Hybrid fallback (WO-014/015/016, **s8**, §6-8 보강)

## 인프라 상태 (s8 종료)

### Self-hosted Runners (MBA, macOS 26.3.1)

| Runner | Labels | Repo | Service |
|---|---|---|---|
| jominhoui-mba-ios | self-hosted, macOS, ARM64, aidy-ios | aidy-ios | actions.runner.Mino777-aidy-ios.* |
| jominhoui-mba-server | self-hosted, macOS, ARM64, aidy-server | aidy-server | actions.runner.Mino777-aidy-server.* |
| jominhoui-mba-android | self-hosted, macOS, ARM64, aidy-android | aidy-android | actions.runner.Mino777-aidy-android.* |

### Workflow 패턴

| Repo | 패턴 | 근거 |
|---|---|---|
| aidy-ios | self-hosted **only** | macOS 분당 계수 10x (ADR-009) |
| aidy-server | **Hybrid** (gh-hosted primary + self-hosted fallback) | ADR-010 Mark-step §8 |
| aidy-android | **Hybrid** (동일 + merge 가드) | ADR-010 §8 확장 |

### 환경

| 항목 | 경로/버전 |
|---|---|
| JDK 17 (baseline) | `/opt/homebrew/opt/openjdk@17` (17.0.18) |
| JDK 21 (workflow) | `actions/setup-java@v5` tool-cache (Temurin 21.0.10) |
| Android SDK | `/opt/homebrew/share/android-commandlinetools` |
| SDK 컴포넌트 | build-tools 35.0.0, platform-tools 37.0.0, platforms;android-35 |

## 다음 할 일

### P0 — billing 복구 시 즉시
1. **WO-016 정상 시나리오 검증**: server/android에 빈 커밋 push → primary green + fallback skipped 확인
2. **github-hosted Android SDK 자동 제공 확인**: primary(ubuntu-latest) assembleDebug 성공 확인

### P1 — 다음 스프린트
1. **WO-011 (Swift 6 Sendable)** — backlog, iOS 전용
2. **WO-013 (워크플로 통합)** — backlog, test.yml + ai-review.yml 중복 정리
3. **Password reset SMTP 통합** — s6 후속
4. **SSE Phase 3** — Anthropic event_type 전수

### P3 — 인프라 개선
1. `dispatch.md` Phase 0: billing/quota 사전 체크 step 추가
2. Spec 예시 코드 dry-run 검증 프로세스 도입 (spec-first-verify-first)
3. MBA 디스크 모니터링 자동화 (cron or /monitor 확장)
4. Runner 대기 시간 P95 지표 도입 (ADR-010 §5 보강)
5. `gradle/actions v6` 라이선스 변경 검토 (별도 ADR)

## 이번 세션 수치

| 항목 | 수치 |
|---|---|
| WO 완료 | 4건 (012, 014, 015, 016) |
| Architect 인프라 세팅 | Runner 2대 등록 + JDK 17 + Android SDK |
| ADR | 1건 생성 (010) + 3회 보강 (§6, §7, §8) |
| 워커 테스트 실측 | iOS: green (WO-010 베이스라인) / Server: 207 · 0 fail / Android: 135 · 0 fail |
| 솔루션 | 1건 (continue-on-error masking) |
| 회고 | 1건 (s8 compound) |
| 긴급 대응 | 1건 (WO-016 §1 버그 → ADR-010 §8 → android tmux 알림) |
| send-seq 실행 | 3회 (WO-012 3워커 / WO-014+015 / WO-016) |
| 리밋 히트 | 1회 (android WO-015 dispatch 중) |

---

# Architect 핸드오프 — 2026-04-17 세션 7 (s6 후속 P3 + iOS CI 복구)

## 세션 7 요약 (s6 종료 후 P3 인프라 + WO-010)

**키워드**: P3 토큰 경제성 인프라 + iOS CI 100% fail 복구 + self-hosted runner 전환

**P3 인프라 (v0.7.1)**
- `architect-cli.sh send-seq` (직렬 dispatch + idle 대기)
- `tmux_send` 429 자동 backoff
- `ci-status.sh` (gh CLI + jq, --watch/--json/--since)
- `/monitor` Phase 6, `/gate-2` Phase 0 통합

**WO-010 iOS CI 복구 (v0.7.2, ADR-009)**
- 진단 3회 정정 (tuist↔macos14 → 결제 차단 → ai-review 알림 폭탄)
- self-hosted runner 등록 (사용자 Mac, jominhoui-mba-ios)
- main `9c3e715` Test run: success, 1m 56s, 124 tests
- 4월 macOS 분 가중치 ~180min → 0min
- 후속 WO 3건 등록 (WO-011/012/013)

## WO 현황 (세션 7 종료 시점)
- done: WO-001 ~ 010 (10건)
- backlog: WO-011 (Swift 6 Sendable) / WO-012 (Node.js 24 — 3 워커) / WO-013 (워크플로 통합)
- in-progress: 없음
