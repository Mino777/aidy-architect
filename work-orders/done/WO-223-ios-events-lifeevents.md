# WO-223: iOS Recurring Events + Life Events (v7.4~v7.5)

## 목표
반복 이벤트 + 생애 이벤트 UI.

## 스펙 참조
- `specs/api-contract.md` §5.57 Recurring Events (v7.4)
- `specs/api-contract.md` §5.58 Life Events (v7.5)

## 구현 범위

### Recurring Events
1. RecurringEventClient — CRUD + upcoming API 호출
2. RecurringEventListFeature (TCA) — 인물별 이벤트 목록
3. RecurringEventListView (SwiftUI) — 이벤트 목록 + 추가/편집
4. UpcomingEventsFeature — 전체 다가오는 이벤트
5. PersonDetailView에 "반복 이벤트" 섹션 추가

### Life Events
6. LifeEventClient — CRUD API 호출
7. LifeEventListFeature (TCA) — 인물별 생애 이벤트 타임라인
8. LifeEventListView (SwiftUI) — 타임라인 뷰 + 추가/편집
9. PersonDetailView에 "생애 이벤트" 섹션 추가

## 제약
- 커밋 메시지: `[R4-ios] feat: WO-223 Events + Life Events`
- tuist build 통과 필수 (xcodebuild test 금지)
- 커밋 1건당 파일 10개 이하
