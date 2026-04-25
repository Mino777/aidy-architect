# WO-170: Relationship Milestones API

**담당**: server
**우선순위**: P4
**상태**: backlog
**스펙**: api-contract.md §5.43

## 구현 요구사항

### 1. Entity
- Milestone: id, userId, personId(FK), type(auto/manual), category, title, description, date, sourceType, sourceId, celebrated, celebratedAt, createdAt

### 2. Controller + Service
- GET /api/people/{personId}/milestones — 인물별 이정표 목록 (limit/offset)
- POST /api/people/{personId}/milestones — 수동 이정표 등록
- PATCH /api/milestones/{id}/celebrate — 축하 토글
- DELETE /api/milestones/{id} — 수동 이정표만 삭제

### 3. 자동 감지 로직
- MilestoneDetector: 대화/메모리 생성 시 이벤트 기반 체크
- 카테고리: first_chat, chat_10/50/100, memory_10/50/100, streak_7/30/100
- 이미 존재하는 이정표는 중복 생성하지 않음

### 4. 테스트
- MilestoneControllerTest: CRUD + 자동 감지 + 축하 토글
- 경계: auto 삭제 시도 → 400, 중복 감지 방지

## 완료 기준
- [ ] GET/POST/PATCH/DELETE 구현
- [ ] 자동 이정표 감지 (이벤트 기반)
- [ ] auto 타입 삭제 방지
- [ ] 빌드 PASS + 테스트 숫자 보고
