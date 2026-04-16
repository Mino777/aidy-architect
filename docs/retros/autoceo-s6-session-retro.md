---
session: autoceo-s6
date: 2026-04-16
rounds: 8 완주 + R9 deferred + R10 compound
status: 부분 완료
---

# 세션 6 회고 — autoceo 6차 스프린트

## 키워드
실시간 스트리밍 + 계정 복구 + 검색 최적화 + **토큰 경제성 교훈**

## 스프린트 구성

```
R1: tmux flush 자동화 + 프롬프트 로깅 + 채팅 복사
R2: SSE Phase 2 Anthropic streaming 서버
R3: iOS SSE 구독 + 서버 테스트
R4: Android SSE 구독 + /chat/history since + iOS 입력창
R5: Password reset 서버 + SSE 회복성
R6: Password reset UI (iOS/Android) + 서버 쿨다운
R7: pg_trgm GIN V12 + 검색 UX (최근어+하이라이트)
R8: E2E 통합 테스트 확장
R9: [deferred] org rate limit → 유실
R10: compound (이 문서)
```

## 수치

| 항목 | 수치 |
|------|------|
| 워커 커밋 | 24건 (server 8 / ios 8 / android 8) |
| Architect 커밋 | 예정 (compound 1건) |
| 롤백 | 0회 |
| 보호파일 위반 | 0건 |
| Flyway | V11 + V12 |
| API Contract | v0.2.3 → v0.2.5 |
| **총 테스트** | **456 · 0 failures** (server 203 / iOS 121 / android 132) |
| 세션 5 대비 증분 | +116 tests |

## 주요 기술 결정

### SSE Phase 2 — 실연동
- 서버: OkHttp `response.body.source()` 로 Anthropic SSE 파싱 (content_block_delta/message_stop)
- 클라: iOS `URLSession.bytes` / Android `BufferedSource.readUtf8Line` 모두 **외부 SSE 라이브러리 0**
- Circuit Breaker 는 streaming 에서도 동일 적용 — OPEN 시 즉시 onError

### Password Reset
- 토큰 32자 SecureRandom URL-safe / 30분 만료 / 1회용
- 5분 쿨다운 — 동일 이메일 남용 방지
- 존재하지 않는 이메일도 200 (사용자 유출 방지)
- 이메일 발송은 **로그 출력만** (SMTP Phase 2)

### 검색 GIN
- PostgreSQL `pg_trgm` extension + GIN index — LIKE '%keyword%' 성능
- H2 테스트 프로파일은 flyway.enabled=false 이므로 V12 실행 안 됨 (기존 패턴)

## 결정적 발견 — 토큰 경제성

**문제**: 토큰 리밋 리셋 직후 17% 소비 + 429 rejection 발생.

**원인**:
- autoceo 10라운드 × 3 워커 병렬 = 라운드당 4 Claude 인스턴스 동시 활동
- 각 라운드 dispatch 직후 3 워커가 동시에 10-30분 작업 → org-level rate limit
- architect 턴 자체는 무겁지 않으나 **백그라운드 워커 소비**가 약 15배

**교훈**:
- 3-way 병렬이 항상 최적은 아님 — API rate 관점에서 직렬/일부 병렬이 안전
- 세션 5에서는 리밋 여유 많을 때 시작 → OK
- 세션 6은 리셋 직후 시작 → 큐에 밀려있던 리소스 + 병렬 burst 충돌

**다음 세션 개선안**:
- 라운드 안에서 워커 순차 (server → iOS → android) 옵션
- dispatch 후 **5분 간격** 폴링 (2분 너무 공격적)
- 큰 작업 2 라운드로 쪼개기
- architect-cli.sh 에 "concurrent limit" 파라미터 추가 고려

## 잘한 것
- SSE Phase 2 실제 스트리밍까지 완주 — P-002 완결
- Password reset end-to-end (서버 + 클라 + E2E 테스트) 한 세션에 완성
- R1 ~ R8 모두 **테스트 실행 숫자 증거** 커밋 메시지 포함 (s5 정책 지속)
- 보호파일/dependency/롤백 전부 0건
- 프롬프트 로그 인프라 구축 — 앞으로 자동 기록

## 아쉬운 것
- R9 유실 — org rate limit 고려 없이 공격적 dispatch
- tmux_send 재시도는 paste 잔류는 막았지만 429 retry는 미구현
- admin 통계 + 클라 디버그 뷰는 다음 세션으로

## 다음 세션 시작점 (s7)

### P1 — R9 이월
1. GET /api/internal/stats/summary — 기존 Repository 재사용
2. iOS/Android 디버그 뷰 — 기존 컴포넌트 정리

### P2 — s6 후속
3. Password reset 이메일 SMTP 통합 (Phase 2)
4. SSE Phase 3 — Anthropic official stream 이벤트 전수 처리 (error/usage)
5. P-004 Phase 2 Multi-Provider Fallback

### P3 — 인프라
6. architect-cli.sh — 순차 dispatch 모드 `send --sequential`
7. dispatch 후 워커 상태 확인 자동화 (429 감지 + 재시도 backoff)
8. CI 통과 여부 자동 수집 (GitHub API)
