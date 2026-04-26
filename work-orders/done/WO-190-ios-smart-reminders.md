# WO-190: iOS — Smart Contact Reminders UI (v5.5)

## 담당: ios
## 우선순위: P4
## 관련 스펙: api-contract.md § 5.45

## 작업 내용
1. SmartReminderClient (Interface/Live) — API 연동
2. SmartRemindersFeature (TCA Reducer)
3. SmartRemindersView — 리마인더 목록/완료/무시
4. SmartReminderSettingsFeature + View — 설정 화면

## 완료 기준
- [ ] Client Interface + Live 분리 (TMA)
- [ ] 리마인더 목록 + 상태 변경 (completed/dismissed)
- [ ] 설정 화면 (enabled, maxPerDay, quietHours 등)
- [ ] tuist build 통과
- [ ] 커밋: `[R3-ios] feat: WO-190 Smart Reminders UI`

## 제약
- 커밋 1건당 파일 10개 이하
- xcodebuild test 금지, tuist build만
