# WO-166: Activity Heatmap UI (Android)

**담당**: android
**우선순위**: P4
**상태**: backlog
**스펙**: api-contract.md §5.39

## 구현 요구사항

### 1. Heatmap API
- ActivityRepository: getHeatmap(year, month)
- ActivityApi retrofit interface

### 2. 히트맵 화면
- 프로필/설정 또는 인사이트에 히트맵 섹션 추가
- Canvas 또는 LazyVerticalGrid: 7열(일~토) × N행
- level에 따른 Primary 색상 4단계 (alpha: 0.1, 0.3, 0.6, 1.0)
- 월 선택: 좌우 IconButton으로 이전/다음 월
- summary 카드: activeDays, currentStreak, longestStreak
- 날짜 셀 클릭: Dialog로 chatCount/memoryCount 표시

### 3. 테스트
- ActivityHeatmapViewModelTest: 데이터 로드/월 변경/빈 데이터

## 완료 기준
- [ ] 히트맵 그리드 UI
- [ ] 월 네비게이션
- [ ] summary 표시
- [ ] 빌드 PASS + 테스트 숫자 보고
