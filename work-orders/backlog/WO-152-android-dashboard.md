# WO-152: Home Dashboard UI (v4.4)

**담당**: android
**우���순위**: P2
**상태**: backlog

## 구현 요구사항

### 1. API 클라이언트
- DashboardApi: getDashboard
- DashboardResponse 모델 (§5.35 스키���)

### 2. ViewModel
- `DashboardViewModel`: 대시보드 로드, 풀투리프레시
- UiState: Loading / Success(dashboard) / Error

### 3. UI (Jetpack Compose, DESIGN.md 준수)
- 인사말 카드 (상단, MaterialTheme.typography.headlineMedium)
- 다이제스트 Row (새 메모리, 기념일, 넛지 — 아이콘+숫자)
- 추천 카드 LazyColumn (suggestions, 최대 3개)
- 관계 요약 (healthy/needsAttention/new 카운트)
- 최근 하이라이트 리스트 (아바타 + 스니펫)
- 온보딩 배너 (미완료 시)

### 4. 탭 통합
- 기존 Chat 탭을 홈 대시보드로 교체
- BottomNavigation: Home / People / Settings

## 완료 기준
- [ ] 빌드 PASS + 테스트 숫자 보고
- [ ] GET /api/dashboard 호출 → UI 렌더링
- [ ] 각 섹션 탭 → 상세 화면 네비게이션
