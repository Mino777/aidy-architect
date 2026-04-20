# WO-103: Smart Notifications API (v2.9) — Server

## 담당: server
## 스펙: api-contract.md § 5.20

## 작업
1. `SmartNotification` Entity + Repository 생성
   - id, userId, type(enum), title, body, personId, personName, priority(enum), triggerReason(enum), dismissed, dismissedAt, createdAt, expiresAt
2. `SmartNotificationService` 구현
   - generateNotifications(userId): AI가 메모리/기념일/건강점수 분석 → 알림 생성
   - getSmartNotifications(userId, limit, offset): 미처리 알림 조회 (7일 내)
   - dismissNotification(userId, id): 알림 무시
3. `SmartNotificationController` — 3개 엔드포인트
   - GET /api/notifications/smart
   - POST /api/notifications/smart/{id}/dismiss
   - POST /api/notifications/smart/generate
4. 테스트: Controller + Service 각 최소 3개

## 금지
- 기존 NotificationPreference 코드 수정 금지
- 실제 푸시 알림 전송 금지 (데이터만 생성)
- 커밋 1건당 파일 10개 이하
