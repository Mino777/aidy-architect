# WO-063: Memory Smart Review API (v1.6)

**담당**: server
**우선순위**: P2
**상태**: backlog
**API 버전**: v1.6.0

## 작업 내용

### 1. Memory Smart Review Suggestions

엔드포인트: `GET /api/memories/review-suggestions?limit=5`

구현:
- 30일+ 된 메모리 조회 (dismissed/pinned 제외)
- AI(Claude)에 메모리 목록 전달 → priority + reason 결정
- schedule/work/health 카테고리 우선
- daysSinceCreated 계산
- 간단한 캐시 (동일 userId로 1시간 이내 재요청 시)

DB:
- Memory 엔티티에 `reviewedAt` 컬럼 추가 (nullable, Flyway 마이그레이션)

### 2. Memory Review Action

엔드포인트: `POST /api/memories/{id}/review`

구현:
- action: confirm (reviewedAt 갱신), update (reviewedAt 갱신), delete (메모리 삭제)
- confirm/update 시 다음 리뷰 대상에서 제외 (reviewedAt 기준)

### 참조
- `specs/api-contract.md` v1.6 섹션

## 완료 기준
- [ ] Flyway 마이그레이션 (reviewedAt 컬럼)
- [ ] GET /api/memories/review-suggestions — AI 기반 리뷰 추천
- [ ] POST /api/memories/{id}/review — confirm/update/delete
- [ ] 테스트 최소 10건
- [ ] 커밋: `[R2-server] feat: Memory Smart Review (v1.6)`
