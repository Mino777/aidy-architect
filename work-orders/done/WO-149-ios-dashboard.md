# WO-149: Home Dashboard UI (v4.4)

**담당**: ios
**우선순위**: P2
**상태**: done

## 구현 요구사��

### 1. API 클라이언트
- DashboardAPI: getDashboard
- DashboardResponse 모델 (§5.35 스키마)

### 2. Feature (TCA)
- `DashboardFeature`: State/Action/Reducer
- 풀투리프레시 지원
- 각 섹션 탭 시 해당 상세 화면으로 네비게이션

### 3. UI (DESIGN.md 준수)
- 인사말 카드 (상단, 큰 텍스트)
- 다이제스트 요약 (새 메모리 수, 기념일 배지, 넛지 수)
- 추천 카드 리스트 (suggestions, 최대 3개)
- 관계 요약 링 차트 (healthy/needsAttention/new)
- 최근 하이라이트 리스트 (인물 아바타 + 메모리 스니펫)
- 온보딩 배너 (미완료 시, 탭하면 온보딩 화면)

### 4. 탭 통합
- 기존 Chat 탭을 홈 대시보드로 교체 (Chat은 대시보드에서 진입)
- Tab bar: Home / People / Settings

## 완료 기준
- [ ] 빌드 PASS + 테스트 숫자 보고
- [ ] GET /api/dashboard 호출 → UI 렌더링
- [ ] 각 섹션 탭 → 상세 화면 네비게이션
