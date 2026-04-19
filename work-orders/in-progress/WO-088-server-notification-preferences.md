# WO-088: Server — Notification Preferences API (v2.4)

**담당**: server
**스펙**: `specs/api-contract.md` § 5.15 Notification Preferences (v2.4)

## 구현 범위

### DB
1. `notification_preferences` 테이블 생성 (Flyway 마이그레이션)
   - user_id, daily_digest, daily_digest_time, weekly_summary, weekly_summary_day
   - anniversary_reminder, anniversary_reminder_days_before
   - conversation_starters, memory_insights, relationship_health

### API
1. **GET /api/notifications/preferences** — 조회 (없으면 기본값 생성)
2. **PUT /api/notifications/preferences** — partial update

### 로직
- Settings.notification=false 이면 모든 알림 비활성 (마스터 스위치)
- dailyDigestTime: HH:mm 형식 검증
- weeklySummaryDay: enum 검증
- anniversaryReminderDaysBefore: 1~30 범위 검증

### 커밋 규칙
- 메시지: `[R3-server] feat: Notification Preferences API (v2.4)`
- 파일 10개 이하/커밋
