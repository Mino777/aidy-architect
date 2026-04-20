# WO-109: Interaction Log API (v3.1) — Server

## 담당: server
## 스펙: api-contract.md § 5.22

## 작업
1. `Interaction` Entity + Repository
   - id, userId, personId, type(enum), title, note, occurredAt, duration(nullable), createdAt
2. `InteractionService`
   - createInteraction(userId, personId, req): 기록 생성
   - getInteractions(userId, personId, limit, offset, type): 목록 조회
   - deleteInteraction(userId, id): 삭제
3. `InteractionController` — 3개 엔드포인트
   - POST /api/people/{personId}/interactions
   - GET /api/people/{personId}/interactions
   - DELETE /api/interactions/{id}
4. 테스트: Controller + Service 각 최소 3개

## 금지
- 기존 Relationship Timeline 코드 수정 금지
- 커밋 1건당 파일 10개 이하
