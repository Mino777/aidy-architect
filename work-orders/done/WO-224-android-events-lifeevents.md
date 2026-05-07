# WO-224: Android Recurring Events + Life Events (v7.4~v7.5)

## 목표
반복 이벤트 + 생애 이벤트 UI.

## 스펙 참조
- `specs/api-contract.md` §5.57 Recurring Events (v7.4)
- `specs/api-contract.md` §5.58 Life Events (v7.5)

## 구현 범위

### Recurring Events
1. RecurringEventApiService — CRUD + upcoming 엔드포인트
2. RecurringEventRepository
3. RecurringEventViewModel — 인물별 이벤트 CRUD
4. UpcomingEventsViewModel — 전체 다가오는 이벤트
5. RecurringEventListScreen + UpcomingEventsScreen (Compose)
6. PersonDetailScreen에 "반복 이벤트" 섹션 추가

### Life Events
7. LifeEventApiService — CRUD 엔드포인트
8. LifeEventRepository
9. LifeEventViewModel — 인물별 타임라인
10. LifeEventListScreen (Compose) — 타임라인 + 추가/편집
11. PersonDetailScreen에 "생애 이벤트" 섹션 추가
12. ViewModel 테스트

## 제약
- 커밋 메시지: `[R5-android] feat: WO-224 Events + Life Events`
- testDebugUnitTest 통과 필수
- 커밋 1건당 파일 10개 이하
