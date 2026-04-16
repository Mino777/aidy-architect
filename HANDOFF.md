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

## 다음 세션 시작 전 체크
- 사용자 Mac runner 상태: `gh api /repos/Mino777/aidy-ios/actions/runners`
- 다른 워커 repo (server/android) 도 같은 결제 차단 영향인지 확인 필요 (Linux runner라 영향 다를 수 있음)
- WO-012 (Node.js 24) 가 가장 시급 — 2026-06-02 강제 마이그레이션

---

# Architect 핸드오프 — 2026-04-16 세션 6 종료

## 이번 세션 요약
**키워드**: 실시간 스트리밍 + 계정 복구 + 검색 최적화 + **토큰 경제성 교훈** + memory 규칙 실적용

```
autoceo 6차 스프린트 (R1~R9 완주, R10 compound):
  R1: tmux flush 자동화 + 프롬프트 로깅 + 채팅 복사
  R2: SSE Phase 2 Anthropic streaming (서버)
  R3: iOS SSE 구독 + 서버 SSE 테스트
  R4: Android SSE 구독 + chat/history since v0.2.4
  R5: Password reset 서버 + SSE 회복성
  R6: Password reset UI (iOS/Android) + 서버 쿨다운
  R7: pg_trgm GIN V12 + 검색 UX
  R8: E2E 통합 테스트 확장
  R9: [429 재발 후 순차 재개 성공] admin stats + 디버그 뷰
  R10: compound
```

## 현재 상태

### 프로젝트 진행도

| 영역 | 상태 | 신규 (s6) |
|------|------|----------|
| Auth | ✅ JWT + Biometric + Password Reset | 6차 |
| Chat | ✅ SSE Phase 2 실제 스트리밍 | 6차 |
| Memory | ✅ 페이지네이션 + 검색 GIN | 6차 |
| People | ✅ | — |
| 드래프트 큐 | ✅ | — |
| AI 안정성 | ✅ Circuit Breaker (stream에도 적용) | 6차 확장 |
| 관측성 | ✅ Request-Id + error_logs + ai_stats + metrics | — |
| DB 성능 | ✅ V8 인덱스 + V9 user_id + V10 error_logs + V11 password_reset + V12 pg_trgm | 6차 |
| 테스트 | ✅ 456 tests 실측 + CI 자동화 | 6차 |
| 도구 | ✅ tmux flush 안정화 + 프롬프트 로깅 | 6차 |

### WO 현황
- WO-001~009: 전부 done
- Backlog: 비어있음

### BACKLOG 미결정 이슈
| ID | 제목 | 긴급도 | 상태 |
|----|------|--------|------|
| ~~P-002~~ | ~~SSE vs WebSocket~~ | — | 완료 — ADR-008 Phase 1+2 |
| ~~P-004 Phase 1~~ | ~~Circuit Breaker~~ | — | 완료 — ADR-007 |
| P-004 Phase 2 | Multi-Provider Fallback | P3 | 대기 (2nd API key) |
| P-006 | Multi-Agent Pipeline | P3 | 결정됨 (ADR-004) |

### ADR 현황 (총 8건)
- ADR-001 ~ 007: 기존
- ADR-008: SSE 스트리밍 채팅 — **Phase 2 실연동 완료 (s6-R2)**

### API Contract v0.2.5
- v0.2.4: GET /api/chat/history `?since=ISO8601`
- v0.2.5: POST /api/auth/password/reset/{request,confirm} + PASSWORD_RESET_TOKEN_INVALID

### Flyway 누적
V1~V12 (s6에서 V11 password_reset_tokens + V12 pg_trgm 추가)

## 정책 + 도구

### 자동 로깅 인프라 (NEW, s6-R1)
- `docs/worker-prompts/` — dispatch 프롬프트 자동 기록 (매 send 시 `YYYY-MM-DD.md` append)
- `docs/worker-prompts/README.md` — 컨벤션 + 학습 포인트
- `docs/worker-prompts/autoceo-s6-backfill.md` — s6 R1~R9 프롬프트 백필

### tmux 안정화
- `tmux_send` — paste-buffer + Enter flush 3회 재시도 (긴 프롬프트 유실 차단)

## 다음 세션 시작 방법

```bash
tmux attach -t aidy
# 4 panes에 Claude Code 구동 중
```

## 다음 할 일

### P1 — s6 후속 (다음 작업)
1. **Password reset SMTP 통합** — 현재 로그 출력만 → 실제 이메일
2. **SSE Phase 3** — Anthropic 공식 event_type 전수 (error, ping, usage)
3. **P-004 Phase 2** — Multi-Provider Fallback (OpenAI)

### P3 — 인프라 개선 (토큰 경제성) — ✅ 완료 (0.7.1)
6. ~~architect-cli.sh `send-seq` 모드~~ — ✅ `send-seq` + `wait-idle` + idle 감지
7. ~~429 감지 + backoff~~ — ✅ tmux_send 내장, 환경변수 제어
8. ~~CI 상태 자동 수집~~ — ✅ `ci-status.sh` (watch/json/since/branch/workflow) + /monitor, /gate-2 통합

### 긴급 — iOS CI 빨간불
- 최근 iOS Test 워크플로 2건 연속 실패 (s6-R9 커밋)
- `./ci-status.sh --watch --limit 5` 로 재확인 후 조사 필요

## 이번 세션 수치

| 항목 | 수치 |
|------|------|
| autoceo 라운드 | R1~R9 완주 / R10 compound |
| 워커 커밋 | 27건 (server 9 / ios 9 / android 9) |
| Architect 커밋 | 2건 (compound v0.7.0 + R9 재개 compound) |
| Flyway | V11 + V12 |
| API 버전 | v0.2.3 → v0.2.5 |
| **테스트 실측** | **466 · 0 failures** |
| 세션 5 대비 증분 | +126 tests |
| 롤백 | 0 · 보호파일 위반 | 0 |

## 결정적 발견 — 토큰 경제성

**문제**: 토큰 리밋 리셋 직후 17% 소비 + 429 rejection 발생.

**원인**: autoceo 10라운드 × 3 워커 병렬 = 라운드당 4 Claude 인스턴스 동시 활동. architect 1 : worker 3 소비 비율.

**박제된 교훈**:
- 3-way 병렬 dispatch는 리밋 여유 있을 때만 안전
- 리셋 직후엔 순차 또는 부분 병렬
- dispatch 후 5분 간격 폴링 (2분 너무 공격적)
- 큰 작업은 2 라운드로 쪼개기

**다음 세션 개선 후보**:
- `architect-cli.sh send --sequential` 모드
- `tmux_send` 에 429 감지 + 백오프
- 워커 소모 모니터링 (상태 파일에 cumulative 토큰 추정치)

## 구축된 인프라 (누적)

### Slash Commands (9개)
`/gate-1`, `/gate-2`, `/monitor`, `/dispatch`, `/compound`, `/cross-session-review`, `/autoceo`, `/ingest`, `/ship`

### CI/CD
- `.github/workflows/test.yml` × 3 (s5) + `ai-review.yml` × 3 (기존)

### 문서 누적
- DESIGN.md / CHANGELOG v0.7.0 / HANDOFF (이 파일)
- ADR 8건 + BACKLOG
- 회고: autoceo s1~s6 라운드별 + 세션 6건
- 솔루션 3건
- API Contract v0.2.5
- gates 정책 (test-policy × 4 + gate-checklist + security)
- **worker-prompts 로그 (신규 s6)**
