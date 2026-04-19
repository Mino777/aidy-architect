# WO-078: iOS — Relationship Health Score UI (v2.0)

**담당**: ios
**스펙**: `specs/api-contract.md` § 5.11 Relationship Health Score (v2.0)
**선행**: WO-076 (서버 API)

## 구현 범위

### 1. API Client
- `RelationshipHealthClient` (TCA DependencyKey)
  - `fetchHealth(personId:)` → PersonHealthResponse
  - `fetchSummary()` → HealthSummaryResponse

### 2. Feature (TCA)
- `RelationshipHealthFeature` — 인물별 건강 점수 상세
  - State: healthScore, grade, factors[], suggestion, trend, isLoading
  - Action: onAppear → API 호출, refresh
- `HealthSummaryFeature` — 전체 요약 (대시보드)
  - State: totalPeople, averageHealth, distribution, topHealthy[], needsAttention[]

### 3. View (SwiftUI)
- `RelationshipHealthView`
  - 원형 게이지 (healthScore 0-100)
  - grade 배지 (excellent=초록, good=파랑, fair=노랑, needs_attention=빨강)
  - 4 factors 카드 (각각 프로그레스 바 + label + detail)
  - suggestion 말풍선
  - trend 아이콘 (↑ improving, → stable, ↓ declining)
- `HealthSummaryView`
  - 평균 점수 + 분포 차트 (grade별 count)
  - topHealthy / needsAttention 리스트

### 4. 네비게이션
- People 탭 → 인물 선택 → 기존 상세 뷰에 "관계 건강" 섹션 추가
- 대시보드에 "관계 건강 요약" 카드 추가

### 5. 테스트
- Feature 테스트 (TCA TestStore)
- healthScore=0 빈 상태 테스트

### 커밋 규칙
- 메시지: `[R4-ios] feat: Relationship Health Score UI (v2.0)`
- 파일 10개 이하/커밋
