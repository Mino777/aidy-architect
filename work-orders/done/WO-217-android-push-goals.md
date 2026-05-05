# WO-217: Android Push Notification + Relationship Goals (v7.0~v7.1)

## 목표
푸시 알림 수신/표시 + 이력 화면 + 관계 목표 UI.

## 스펙 참조
- `specs/api-contract.md` §5.53 Push Notification Delivery (v7.0)
- `specs/api-contract.md` §5.54 Relationship Goals (v7.1)

## 구현 범위

### Push Notification
1. NotificationApiService — history, read, test 엔드포인트
2. NotificationRepository
3. NotificationViewModel — 이력 조회 + 읽음 처리
4. NotificationListScreen (Compose)
5. 딥링크 데이터 → NavGraph 라우팅

### Relationship Goals
6. GoalApiService — CRUD + complete + summary 엔드포인트
7. GoalRepository
8. GoalViewModel — 인물별 목표 + 달성 기록
9. GoalSummaryViewModel — 전체 대시보드
10. GoalListScreen + GoalSummaryScreen (Compose)
11. PersonDetailScreen에 "목표" 섹션 추가

## 제약
- 커밋 메시지: `[R5-android] feat: WO-217 Push + Goals`
- testDebugUnitTest 통과 필수
- 커밋 1건당 파일 10개 이하
