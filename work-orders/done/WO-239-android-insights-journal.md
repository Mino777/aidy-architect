# WO-239: Android — Conversation Insights + Journal Prompts (v8.4~v8.5)

## 담당: android

## 스펙
`specs/api-contract.md` § 5.65, 5.66 참조

## 구현 범위

### v8.4 Conversation Insights
1. ChatInsightApi + ChatInsightRepository
2. ChatInsightViewModel + tests
3. ChatInsightListScreen + ChatInsightDetailScreen (Compose)

### v8.5 Journal Prompts
1. JournalApi + JournalRepository
2. JournalViewModel + tests
3. JournalScreen + JournalStatsScreen (Compose)

## 완료 기준
- testDebugUnitTest PASS
- 커밋 메시지: `[R5-android] feat: WO-239 Conversation Insights + Journal`
- ViewModel 테스트 필수
