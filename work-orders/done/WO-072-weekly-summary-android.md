# WO-072: Weekly Summary UI (Android, v1.8)

**담당**: android
**우선순위**: P2
**상태**: backlog
**API 버전**: v1.8.0

## 작업 내용

### Weekly Summary UI
- 새 화면: WeeklySummaryScreen + WeeklySummaryViewModel
- 위치: 대시보드/인사이트 탭에 "주간 리포트" 카드 추가
- 하이라이트: LazyColumn으로 표시 (이모지 + 텍스트)
- 통계 카드: Material3 Card에 totalChats, totalMessages 등 숫자
- 감정 요약: overall 이모지 + LinearProgressIndicator(score) + trend 화살표
- 주요 토픽: FlowRow에 AssistChip으로 표시 (count 포함)
- AI 조언: 하단 ElevatedCard에 advice
- 주 선택: Material3 SegmentedButton (이번 주 / 지난주 / 2주 전 등)
- AidyApiService: `getWeeklySummary(weekOffset: Int)`

### 참조
- `specs/api-contract.md` v1.8 섹션

## 완료 기준
- [ ] 주간 리포트 화면 존재
- [ ] 하이라이트 + 통계 + 감정 + 토픽 표시
- [ ] 주 선택 동작
- [ ] 테스트 최소 8건
- [ ] 커밋: `[RN-android] feat: Weekly Summary UI (v1.8)`
