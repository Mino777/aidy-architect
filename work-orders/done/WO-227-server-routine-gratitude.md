# WO-227: Server Daily Routine + Gratitude Journal (v8.0~v8.1)

## 목표
일과 기반 루틴 CRUD + 감사 일기 CRUD + 트렌드.

## 스펙 참조
- `specs/api-contract.md` §5.61 Daily Routine (v8.0)
- `specs/api-contract.md` §5.62 Gratitude Journal (v8.1)

## 구현 범위

### Daily Routine (v8.0)
1. RoutineEntity + RoutineCompletionEntity
2. Flyway V60__create_routines.sql
3. RoutineRepository + RoutineCompletionRepository
4. RoutineService — CRUD + complete + streak 계산 + completedToday 판정
5. RoutineController — POST, GET, POST complete, PUT, DELETE (5개)
6. Controller + Service 테스트

### Gratitude Journal (v8.1)
7. GratitudeEntryEntity + GratitudePersonEntity (M:N)
8. Flyway V61__create_gratitude.sql
9. GratitudeRepository
10. GratitudeService — CRUD + trend (월별 집계 + streak 계산)
11. GratitudeController — POST, GET, GET trend, DELETE (4개)
12. Controller + Service 테스트

## 영향 테스트
- 기존 테스트 영향 없음 (신규 Entity/Service)

## Flyway
- V60, V61 사용

## 제약
- 커밋 메시지: `[R2-server] feat: WO-227 ...`
- `./gradlew test` 통과 필수
- 커밋 1건당 파일 10개 이하
