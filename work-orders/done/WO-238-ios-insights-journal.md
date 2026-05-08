# WO-238: iOS — Conversation Insights + Journal Prompts (v8.4~v8.5)

## 담당: ios

## 스펙
`specs/api-contract.md` § 5.65, 5.66 참조

## 구현 범위

### v8.4 Conversation Insights
1. ChatInsightClient (API 클라이언트)
2. ChatInsightFeature (TCA Reducer)
3. ChatInsightListView + ChatInsightDetailView
4. 채팅 종료 후 인사이트 생성 알림 연동

### v8.5 Journal Prompts
1. JournalClient (API 클라이언트)
2. JournalFeature (TCA Reducer)
3. JournalPromptsView + JournalEntryView + JournalStatsView
4. 오늘의 프롬프트 홈 위젯 연동

## 완료 기준
- tuist build PASS (xcodebuild test 금지)
- 커밋 메시지: `[R5-ios] feat: WO-238 Conversation Insights + Journal`
