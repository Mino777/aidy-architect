# WO-081: Android — Daily Digest UI (v2.1)

**담당**: android
**스펙**: `specs/api-contract.md` § 5.12 Daily Digest (v2.1)
**선행**: WO-077 (서버 API)

## 구현 범위

### 1. API / Repository
- `DailyDigestApi` (Retrofit)
  - `getToday()` → DailyDigestResponse
- `DailyDigestRepository` — API 래핑

### 2. ViewModel
- `DailyDigestViewModel`
  - UiState: Loading, Success(digest), Error
  - fetchToday()
  - 딥링크: reminder 탭 → person/memory 화면 이동

### 3. Compose UI
- `DailyDigestScreen`
  - greeting 카드 (큰 텍스트, 상단)
  - "오늘의 리마인더" LazyColumn (아이콘+제목+상세, 탭 가능)
  - "하이라이트" 카드 리스트
  - 하단 stats Row (totalMemories, thisWeekMessages, activePeople, streakDays)
  - SwipeRefresh

### 4. 네비게이션
- 메인 화면 상단에 Daily Digest 카드 또는 별도 탭
- reminder 탭 시 해당 person/memory 화면으로 이동

### 5. 테스트
- ViewModel 테스트 (MockRepository)
- 빈 데이터 상태 테스트

### 커밋 규칙
- 메시지: `[R5-android] feat: Daily Digest UI (v2.1)`
- 파일 10개 이하/커밋
