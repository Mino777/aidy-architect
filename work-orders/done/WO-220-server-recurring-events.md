# WO-220: Server Recurring Events (v7.4)

## 목표
기념일 시스템 확장 — 반복 이벤트 CRUD + 다가오는 이벤트 조회 + nextOccurrence 자동 계산.

## 스펙 참조
`specs/api-contract.md` §5.57 Recurring Events (v7.4)

## 구현 범위
1. RecurringEventEntity (id, personId, userId, title, description, recurrence enum, dayOfWeek, dayOfMonth, date, time, reminderMinutes, color, nextOccurrence)
2. Flyway V57__create_recurring_events.sql
3. RecurringEventRepository
4. RecurringEventService — CRUD + nextOccurrence 계산 로직 (WEEKLY/BIWEEKLY/MONTHLY/YEARLY/ONCE)
5. RecurringEventController — POST, GET per-person, GET upcoming, PUT, DELETE (5개 엔드포인트)
6. Controller + Service 테스트

## 영향 테스트 (사전 분석)
- 기존 테스트 영향 없음 (신규 Entity/Controller/Service)

## Flyway 번호
- V57 사용

## 제약
- 커밋 메시지: `[R2-server] feat: WO-220 Recurring Events`
- `./gradlew test` 통과 필수
- 커밋 1건당 파일 10개 이하
