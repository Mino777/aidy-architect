# WO-090: Android — Notification Preferences UI (v2.4)

**담당**: android
**스펙**: `specs/api-contract.md` § 5.15 Notification Preferences (v2.4)
**선행**: WO-088 (서버 API)

## 구현 범위

### 화면
1. **NotificationPreferencesScreen** — Settings 하위 화면
   - 각 알림 유형별 Switch
   - dailyDigestTime: TimePicker
   - weeklySummaryDay: Dropdown/Dialog
   - anniversaryReminderDaysBefore: Slider (1~30)
   - 마스터 스위치 off 시 전체 비활성 표시

### 데이터
1. **NotificationPreferencesApi** — Retrofit 인터페이스
2. **NotificationPreferencesRepository**
3. **NotificationPreferencesViewModel** — 상태 관리
4. Settings 화면에서 "알림 설정" 행 추가 → navigate

### 커밋 규칙
- 메시지: `[R4-android] feat: Notification Preferences UI (v2.4)`
- 파일 10개 이하/커밋
