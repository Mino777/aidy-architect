# WO-080: iOS — Daily Digest UI (v2.1)

**담당**: ios
**스펙**: `specs/api-contract.md` § 5.12 Daily Digest (v2.1)
**선행**: WO-077 (서버 API)

## 구현 범위

### 1. API Client
- `DailyDigestClient` (TCA DependencyKey)
  - `fetchToday()` → DailyDigestResponse

### 2. Feature (TCA)
- `DailyDigestFeature`
  - State: greeting, reminders[], highlights[], stats, isLoading, date
  - Action: onAppear → API 호출, reminderTapped(id), highlightTapped
  - 딥링크: person_checkin → People 상세, memory_followup → Memory 상세

### 3. View (SwiftUI)
- `DailyDigestView`
  - greeting 카드 (상단, 큰 텍스트)
  - "오늘의 리마인더" 섹션 (reminders, 아이콘+제목+상세)
  - "하이라이트" 섹션 (highlights, 카드형)
  - 하단 stats 바 (totalMemories, thisWeekMessages, activePeople, streakDays)
  - pull-to-refresh

### 4. 네비게이션
- 메인 탭에 "오늘" 탭 추가 또는 홈 화면 상단에 Daily Digest 카드
- reminder 탭 시 해당 person/memory로 이동

### 5. 테스트
- Feature 테스트 (TCA TestStore)
- 빈 reminders/highlights 상태 테스트

### 커밋 규칙
- 메시지: `[R5-ios] feat: Daily Digest UI (v2.1)`
- 파일 10개 이하/커밋
