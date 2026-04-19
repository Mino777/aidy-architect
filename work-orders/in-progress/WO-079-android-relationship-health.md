# WO-079: Android — Relationship Health Score UI (v2.0)

**담당**: android
**스펙**: `specs/api-contract.md` § 5.11 Relationship Health Score (v2.0)
**선행**: WO-076 (서버 API)

## 구현 범위

### 1. API / Repository
- `RelationshipHealthApi` (Retrofit)
  - `getPersonHealth(personId)` → PersonHealthResponse
  - `getHealthSummary()` → HealthSummaryResponse
- `RelationshipHealthRepository` — API 래핑

### 2. ViewModel
- `RelationshipHealthViewModel` — 인물별 건강 점수
  - UiState: Loading, Success(health), Error
  - fetchHealth(personId)
- `HealthSummaryViewModel` — 전체 요약
  - UiState: Loading, Success(summary), Error

### 3. Compose UI
- `RelationshipHealthScreen`
  - 원형 게이지 (Canvas 기반, healthScore 0-100)
  - grade 배지 (색상 매핑: excellent=Green, good=Blue, fair=Yellow, needs_attention=Red)
  - 4 factors LazyColumn (각 Row: 프로그레스바 + label + detail)
  - suggestion Card
  - trend 아이콘 (↑↓→)
- `HealthSummaryScreen`
  - 평균 점수 + 분포 막대 차트
  - topHealthy / needsAttention LazyColumn

### 4. 네비게이션
- People 탭 → 인물 상세 → "관계 건강" 섹션
- 대시보드에 "관계 건강 요약" 카드

### 5. 테스트
- ViewModel 테스트 (MockRepository)
- 빈 데이터 상태 테스트

### 커밋 규칙
- 메시지: `[R4-android] feat: Relationship Health Score UI (v2.0)`
- 파일 10개 이하/커밋
