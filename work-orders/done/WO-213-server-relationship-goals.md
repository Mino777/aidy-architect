# WO-213: Server Relationship Goals (v7.1)

## 목표
인물별 커스텀 관계 목표 CRUD + 달성 기록 + 대시보드.

## 스펙 참조
`specs/api-contract.md` §5.54 Relationship Goals (v7.1)

## 구현 범위
1. GoalEntity + GoalCompletionEntity + GoalRepository
2. GoalService — CRUD + complete + summary 로직
3. GoalController — 5개 엔드포인트 (POST, GET, POST complete, DELETE, GET summary)
4. streak 계산 로직 (연속 달성일/주/월 계산)
5. overdue 판정 로직 (frequency 기반)
6. Controller + Service 테스트

## 제약
- 커밋 메시지: `[R2-server] feat: WO-213 Relationship Goals`
- `./gradlew test` 통과 필수
- 커밋 1건당 파일 10개 이하
