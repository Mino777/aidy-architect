# WO-106: Relationship Map API (v3.0) — Server

## 담당: server
## 스펙: api-contract.md § 5.21

## 작업
1. `PersonLink` Entity + Repository
   - id, userId, sourcePersonId, targetPersonId, relationship, strength(1~5), createdAt
   - UNIQUE(userId, sourcePersonId, targetPersonId)
2. `RelationshipMapService`
   - getMap(userId): 노드(인물+healthScore+memoryCount) + 엣지 반환
   - createLink(userId, req): 관계 연결 생성 (중복 체크)
   - deleteLink(userId, linkId): 관계 연결 삭제
   - strength 자동 산출: 두 인물 공동 등장 메모리 수 기반
3. `RelationshipMapController` — 3개 엔드포인트
   - GET /api/people/map
   - POST /api/people/map/link
   - DELETE /api/people/map/link/{id}
4. 테스트: Controller + Service 각 최소 3개

## 금지
- 기존 Person/People 엔티티 구조 변경 금지
- 커밋 1건당 파일 10개 이하
