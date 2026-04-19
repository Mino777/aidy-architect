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

## 완료 보고

**커밋**: `[R2-server] feat: Notification Preferences API (v2.4)`
**파일 수**: 8개 (10개 이하 ✅)

### 구현 내역
1. **V28 Flyway 마이그레이션**: `notification_preferences` 테이블 (user_id UNIQUE, 9개 설정 컬럼)
2. **NotificationPreference 엔티티**: User @OneToOne, 기본값 스펙 일치
3. **NotificationPreferenceRepository**: `findByUserId`
4. **NotificationPreferenceService**: `getOrCreate` (없으면 기본값 생성) + `partialUpdate` (검증 포함)
5. **NotificationPreferenceController**: GET/PUT `/api/notifications/preferences`
6. **입력 검증**:
   - `dailyDigestTime`: `^([01]\d|2[0-3]):[0-5]\d$` (HH:mm 24시간)
   - `weeklySummaryDay`: monday~sunday enum
   - `anniversaryReminderDaysBefore`: 1~30 범위
7. **테스트**: ServiceTest 9개 + ControllerTest 5개

### 테스트 결과
- `./gradlew test`: **728 tests · 0 failures · 0 errors**

### 스펙 대조
- GET /api/notifications/preferences → ✅ 9개 필드 기본값 일치
- PUT /api/notifications/preferences → ✅ partial update, VALIDATION_ERROR 반환
- Error code: VALIDATION_ERROR (스펙 일치)
