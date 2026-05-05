# WO-216: iOS Push Notification + Relationship Goals (v7.0~v7.1)

## 목표
푸시 알림 수신/표시 + 이력 화면 + 관계 목표 UI.

## 스펙 참조
- `specs/api-contract.md` §5.53 Push Notification Delivery (v7.0)
- `specs/api-contract.md` §5.54 Relationship Goals (v7.1)

## 구현 범위

### Push Notification
1. NotificationClient — history, read, test API 호출
2. NotificationListFeature (TCA) — 알림 이력 목록 + 읽음 처리
3. NotificationListView (SwiftUI)
4. AppDelegate에서 FCM 수신 처리 (기존 토큰 등록 확장)
5. 딥링크 데이터 파싱 → 화면 이동

### Relationship Goals
6. GoalClient — CRUD + complete + summary API 호출
7. GoalListFeature (TCA) — 인물별 목표 목록 + 달성 기록
8. GoalSummaryFeature — 전체 목표 대시보드
9. GoalListView + GoalSummaryView (SwiftUI)
10. PersonDetailView에 "목표" 섹션 추가

## 제약
- 커밋 메시지: `[R4-ios] feat: WO-216 Push + Goals`
- tuist build 통과 필수 (xcodebuild test 금지)
- 커밋 1건당 파일 10개 이하
