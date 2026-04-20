# WO-104: Smart Notifications UI (v2.9) — iOS

## 담당: ios
## 스펙: api-contract.md § 5.20

## 작업
1. `SmartNotificationClient` — API 3개 엔드포인트 연동
2. `SmartNotificationFeature` (TCA Reducer)
   - State: notifications, isLoading, error
   - Action: fetch, dismiss, generate, response 처리
3. `SmartNotificationListView` — 알림 목록 UI
   - 타입별 아이콘 (contact_reminder, anniversary_upcoming 등)
   - priority별 색상 구분
   - 스와이프하여 dismiss
4. Navigation: 메인 탭 또는 대시보드에서 진입
5. 테스트: Reducer 최소 3개

## 금지
- 기존 Notification 관련 코드 수정 금지
- 커밋 1건당 파일 10개 이하
