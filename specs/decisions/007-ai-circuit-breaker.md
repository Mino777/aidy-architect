# ADR-007: AI Circuit Breaker (P-004 Phase 1)

**Date**: 2026-04-16
**Status**: Accepted
**Sprint**: autoceo-s4-R2
**Related**: P-004 (BACKLOG), AiService, ai-study Journal 006

## 배경
AI API (Anthropic Claude) 장애 시 서버가 매 요청마다 timeout(30s)을 소진하며 스레드 풀이 마비. 기존 `executeWithRetry`(max-retries=2)는 단일 요청 내 재시도만 해결 — 지속 장애 구간의 stampede는 막지 못함.

## 결정
in-memory Circuit Breaker (0 dependency) 도입. `util/AiCircuitBreaker`.

- 상태 머신: `CLOSED` → `OPEN` → `HALF_OPEN` → `CLOSED`/`OPEN`
- CLOSED: 최근 `windowSize` 중 실패율 ≥ `failureThreshold` 이고 호출 수 ≥ `minCalls` 이면 OPEN.
- OPEN: 즉시 `ApiException(AI_UNAVAILABLE, 503)`. `cooldownMs` 후 첫 호출에서 HALF_OPEN.
- HALF_OPEN: 단일 probe — 성공 → CLOSED + window clear, 실패 → OPEN. 중복 probe는 AI_UNAVAILABLE.
- Thread-safety: `ReentrantReadWriteLock` + `@Volatile`. 상태 변이는 write lock.

## 파라미터 (application.yml, env override)
```yaml
aidy.ai.circuit-breaker:
  failure-threshold: 0.5
  min-calls: 5
  cooldown-ms: 30000
  window-size: 10
```

## 통합 지점
`AiService.callAndParse` → `circuitBreaker.execute { executeWithRetry(...) }` 단일 래핑.

## 대안 검토
- **resilience4j**: 기능 풍부하나 의존성 추가 금지 (P-004 Phase 1 범위 외). Phase 2 Multi-Provider 재검토 시.
- **Spring Retry**: retry만 있고 CB는 별도.
- **DB-backed state**: 분산 배포용 — 현재 단일 인스턴스이므로 YAGNI.

## Trade-off
- (+) 0 의존성, 단순, 테스트 쉬움, 파라미터 튜닝 가능.
- (−) 인스턴스별 독립 상태 — 멀티 인스턴스 배포 시 각자 열고 닫힘. 스케일아웃 시 Phase 2.
- (−) 4xx (예: 401 키 오류)도 failure 카운트. 향후 세분화 여지.

## Phase 2 (미결, 다음 스프린트)
- Multi-Provider Fallback (OpenAI 등 보조) — 2nd API key 필요 → 별도 WO.
- 4xx/5xx 분류 실패 카운팅 정교화.
- Metrics export (Micrometer) — R5 Observability와 연계.

## 테스트
`util/AiCircuitBreakerTest` 10/10 pass: 상태전이, 차단, 복구, window 슬라이딩, cooldown, HALF_OPEN 중복 probe.
