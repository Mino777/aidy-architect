# WO-051: People 관리 API — Server

**워커**: server
**스펙**: api-contract v1.2 — GET /api/memories/people/list, POST /api/memories/people/merge, PATCH /api/memories/people/{id}
**라운드**: autoceo-s22-R2

## 작업

1. PersonController에 3개 엔드포인트 추가:
   - `GET /api/memories/people/list` — 전체 인물 목록 (lastMentionedAt 내림차순)
   - `POST /api/memories/people/merge` — 인물 병합 (source → target, PersonMemory 이동)
   - `PATCH /api/memories/people/{id}` — 인물 정보 수정 (relationship, displayName)
2. PersonService에 비즈니스 로직 추가
3. PersonRepository에 필요한 쿼리 추가
4. 응답 DTO 정의 (PeopleListResponse, MergeResponse, PersonUpdateResponse)
5. 유닛 테스트 + E2E 테스트

## 제약

- 커밋: `[R2-server] feat: People 관리 API (v1.2)`
- 커밋 1건당 파일 10개 이하
- 기존 PersonMemory/Person Entity 구조 변경 금지 (필드 추가만 가능)
