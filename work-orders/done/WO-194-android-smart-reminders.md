# WO-194: Android — Smart Contact Reminders UI (v5.5)

## 담당: android
## 우선순위: P4
## 관련 스펙: api-contract.md § 5.45

## 작업 내용
1. SmartReminderRepository + API
2. SmartRemindersViewModel (UiState data class 패턴)
3. SmartRemindersScreen — 리마인더 목록/완료/무시
4. SmartReminderSettingsScreen — 설정 화면

## 완료 기준
- [ ] 4개 엔드포인트 연동
- [ ] UiState data class 패턴 사용
- [ ] 리마인더 상태 변경 UI
- [ ] testDebugUnitTest 통과
- [ ] 커밋: `[R3-android] feat: WO-194 Smart Reminders UI`

## 제약
- 커밋 1건당 파일 10개 이하
- 기존 패키지만 사용
