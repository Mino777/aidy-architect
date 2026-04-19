# WO-089: iOS — Notification Preferences UI (v2.4)

**담당**: ios
**스펙**: `specs/api-contract.md` § 5.15 Notification Preferences (v2.4)
**선행**: WO-088 (서버 API)

## 구현 범위

### 화면
1. **NotificationPreferencesView** — Settings 하위 화면
   - 각 알림 유형별 토글 스위치
   - dailyDigestTime: 시간 피커
   - weeklySummaryDay: 요일 선택
   - anniversaryReminderDaysBefore: 스테퍼 (1~30)
   - 마스터 스위치 off 시 전체 비활성 표시

### 데이터
1. **NotificationPreferencesClient** — API 2개 엔드포인트
2. **NotificationPreferencesFeature (TCA)** — 상태 관리
3. Settings 화면에서 "알림 설정" 행 추가 → NavigationLink

### 커밋 규칙
- 메시지: `[R4-ios] feat: Notification Preferences UI (v2.4)`
- 파일 10개 이하/커밋
