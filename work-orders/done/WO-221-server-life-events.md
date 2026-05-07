# WO-221: Server Life Events (v7.5)

## 목표
인물별 주요 생애 이벤트 CRUD. AI 대화 시 맥락으로 제공.

## 스펙 참조
`specs/api-contract.md` §5.58 Life Events (v7.5)

## 구현 범위
1. LifeEventEntity (id, personId, userId, title, description, category enum, date, impact enum)
2. Flyway V58__create_life_events.sql
3. LifeEventRepository
4. LifeEventService — CRUD + category 필터
5. LifeEventController — POST, GET, PUT, DELETE (4개 엔드포인트)
6. Controller + Service 테스트

## 영향 테스트
- 기존 테스트 영향 없음 (신규)

## Flyway 번호
- V58 사용

## 제약
- 커밋 메시지: `[R2-server] feat: WO-221 Life Events`
- `./gradlew test` 통과 필수
- 커밋 1건당 파일 10개 이하
