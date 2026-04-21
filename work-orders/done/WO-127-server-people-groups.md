# WO-127: People Groups API (v3.7) — Server

## 담당: server
## 스펙: api-contract.md § 5.28

## 작업
1. `PersonGroup` Entity + Repository
   - id, userId, name, color, createdAt
   - UNIQUE(userId, name)
2. `PersonGroupMember` Entity (다대다)
   - groupId, personId
   - UNIQUE(groupId, personId)
3. `PersonGroupService`
   - CRUD: create, update, delete, getAll
   - addMembers(groupId, personIds): 그룹에 인물 추가
   - removeMember(groupId, personId): 그룹에서 인물 제거
   - suggestGroups(userId): AI가 메모리/대화 패턴 분석 → 그룹 추천
4. `PersonGroupController` — 7개 엔드포인트
   - GET /api/people/groups
   - POST /api/people/groups
   - PUT /api/people/groups/{groupId}
   - DELETE /api/people/groups/{groupId}
   - POST /api/people/groups/{groupId}/members
   - DELETE /api/people/groups/{groupId}/members/{personId}
   - GET /api/people/groups/suggestions
5. 테스트 각 최소 3개

## 금지
- 기존 People 엔드포인트 수정 금지
- 커밋 1건당 파일 10개 이하
