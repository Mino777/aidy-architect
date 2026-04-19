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

---

## 완료 보고

**커밋**: `[R3-ios] feat: Notification Preferences UI (v2.4)`
**파일 수**: 7 (신규 5 + 수정 2)
**테스트**: 498 tests, 1 pre-existing failure (ConversationStarterFeatureTests)
**신규 테스트**: 11건 전체 PASS

### 구현 내역

| 항목 | 파일 | 상태 |
|------|------|------|
| Model | `Core/Model/NotificationPreferences.swift` | NotificationPreferences, NotificationPreferencesPatch, Weekday enum |
| Client | `Core/Network/NotificationPreferencesClient.swift` | @DependencyClient, GET/PUT 2 endpoints |
| Feature | `Feature/Settings/NotificationPreferencesFeature.swift` | 9개 알림 유형별 토글 + 서버 동기화 |
| View | `Feature/Settings/NotificationPreferencesView.swift` | 토글, DatePicker(시간), Picker(요일), Stepper(1~30) |
| SettingsView | `Feature/Settings/SettingsView.swift` | NavigationLink 추가 |
| L10n | `Core/L10n/L10n.swift` | 알림 설정 한/영 19개 문자열 |
| Tests | `Tests/NotificationPreferencesFeatureTests.swift` | 11 tests (happy + error + edge cases) |

### 스펙 준수 확인
- [x] API contract § 5.15 필드명/타입 1:1 대조 완료
- [x] 엔드포인트 URL contract 그대로 복사
- [x] Keychain 토큰 사용 (UserDefaults 미사용)
- [x] masterEnabled: Settings.notification 마스터 스위치 연동
- [x] anniversaryReminderDaysBefore: 1~30 범위 클램핑
- [x] TestStore 테스트 필수 (happy + error + edge cases)
