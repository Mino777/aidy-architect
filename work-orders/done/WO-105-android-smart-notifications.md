# WO-105: Smart Notifications UI (v2.9) — Android

## 담당: android
## 스펙: api-contract.md § 5.20

## 작업
1. `SmartNotificationApi` — Retrofit 3개 엔드포인트
2. `SmartNotificationRepository` + `SmartNotificationViewModel`
3. `SmartNotificationScreen` (Compose)
   - 타입별 아이콘, priority별 색상
   - 스와이프하여 dismiss
4. Navigation 연동
5. 테스트: ViewModel 최소 3개

## 금지
- 기존 Notification 관련 코드 수정 금지
- 커밋 1건당 파일 10개 이하
