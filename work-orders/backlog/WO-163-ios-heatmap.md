# WO-163: Activity Heatmap UI (iOS)

**담당**: ios
**우선순위**: P4
**상태**: backlog
**스펙**: api-contract.md §5.39

## 구현 요구사항

### 1. Heatmap API Client
- ActivityClient: getHeatmap(year, month)
- TCA Dependency 등록

### 2. 히트맵 화면
- 프로필/설정 또는 인사이트 탭에 히트맵 섹션 추가
- 7열(일~토) × N행 그리드, level에 따른 색상 4단계
- DESIGN.md의 Primary 색상 활용 (opacity로 4단계: 0.1, 0.3, 0.6, 1.0)
- 월 선택: 좌우 화살표로 이전/다음 월
- summary 섹션: activeDays, currentStreak, longestStreak 표시
- 날짜 셀 탭: 해당 일의 chatCount/memoryCount 팝오버

### 3. 테스트
- ActivityHeatmapFeatureTests: 데이터 로드/월 변경/빈 데이터

## 완료 기준
- [ ] 히트맵 그리드 UI
- [ ] 월 네비게이션
- [ ] summary 표시
- [ ] 빌드 PASS
