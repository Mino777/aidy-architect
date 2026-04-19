# WO-071: Weekly Summary UI (iOS, v1.8)

**담당**: ios
**우선순위**: P2
**상태**: backlog
**API 버전**: v1.8.0

## 작업 내용

### Weekly Summary UI
- 새 화면: WeeklySummaryFeature + WeeklySummaryView
- 위치: 대시보드/인사이트 탭에 "주간 리포트" 카드 추가
- 하이라이트: 리스트로 표시 (이모지 + 텍스트)
- 통계 카드: totalChats, totalMessages, memoriesCreated 등 숫자 표시
- 감정 요약: overall 이모지 + score 바 + trend 화살표 (↑↓→)
- 주요 토픽: 태그 형태로 표시 (count 포함)
- AI 조언: 하단 카드에 advice 표시
- 주 선택: weekOffset Picker (이번 주 / 지난주 / 2주 전 등)
- APIClient: `getWeeklySummary(weekOffset:)`

### 참조
- `specs/api-contract.md` v1.8 섹션

## 완료 기준
- [ ] 주간 리포트 화면 존재
- [ ] 하이라이트 + 통계 + 감정 + 토픽 표시
- [ ] 주 선택 동작
- [ ] 테스트 최소 8건
- [ ] 커밋: `[RN-ios] feat: Weekly Summary UI (v1.8)`
