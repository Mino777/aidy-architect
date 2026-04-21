# WO-146: Home Dashboard API (v4.4)

**담당**: server
**우선순위**: P2
**상태**: backlog

## 구현 요구사항

### 1. Service
- `getDashboard(userId)` — 여러 서비스 데이터를 통합 조회
  - greeting: 시간대별 (아침 06~12, 점심 12~18, 저녁 18~22, 밤 22~06)
  - digest: 오늘 새 메모리 수, 7일 내 기념일 (max 3), 미처리 넛지 수
  - suggestions: 기존 Chat Suggestions에서 상위 3개
  - relationshipSummary: People + HealthScore 집계
  - recentHighlights: 24h 내 하이라이트 (max 3)
  - onboarding: 미완료 시만 포함

### 2. Controller (1 endpoint)
- `GET /api/dashboard` — §5.35 스키마 준수

### 3. 주의사항
- 기존 서비스 재사용 (새 Repository 불필요)
- N+1 쿼리 주의: 한 번의 요청에 여러 서비스 호출 → 필요시 캐시

## 완료 기준
- [ ] 빌드 PASS + 테스트 숫자 보고
- [ ] 응답 스키마가 api-contract §5.35 필드와 일치
- [ ] greeting이 시간대별로 변경됨
- [ ] onboarding 완료 시 null 반환
