# WO-076: Server — Relationship Health Score API (v2.0)

**담당**: server
**스펙**: `specs/api-contract.md` § 5.11 Relationship Health Score (v2.0)
**선행**: 없음

## 구현 범위

### 1. DB 마이그레이션
- `relationship_health_cache` 테이블 (Flyway 새 파일만)
  - id, user_id, person_id, health_score, grade, factors_json, suggestion, trend, calculated_at
  - UNIQUE(user_id, person_id)

### 2. 엔드포인트 2개
1. **GET /api/people/{personId}/health** — 개인 건강 점수
   - PersonMemory에서 해당 인물의 메모리 조회
   - AI에게 4가지 factor 분석 요청 (interactionFrequency, sentimentTrend, memoryDiversity, recency)
   - 캐시 6시간 TTL (calculated_at 기준)
   - 캐시 hit → DB 반환, miss → AI 호출 + DB 저장

2. **GET /api/people/health/summary** — 전체 요약
   - 전체 인물의 health score 조회 (캐시된 것 사용)
   - 미계산 인물은 즉시 계산
   - topHealthy 상위 3, needsAttention 하위 3

### 3. AI 프롬프트
- 입력: 인물의 PersonMemory 목록 + 최근 30일 chat history에서 해당 인물 언급
- 출력: JSON (healthScore, factors 4개, suggestion, trend)
- Circuit Breaker 적용 (기존 패턴)

### 4. 테스트
- 단위 테스트: Service 계층 (캐시 hit/miss, 점수 계산)
- 통합 테스트: 엔드포인트 2개

### 커밋 규칙
- 메시지: `[R2-server] feat: Relationship Health Score API (v2.0)`
- 파일 10개 이하/커밋
