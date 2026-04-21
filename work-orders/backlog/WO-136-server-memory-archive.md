# WO-136: Memory Archive API (v4.0) — Server

## 담당: server
## 스펙: api-contract.md § 5.31

## 작업
1. Memory Entity에 `archived`, `archivedAt` 필드 추가 (Flyway migration)
2. `MemoryArchiveService`
   - getArchived(userId, offset, limit): 아카이브 메모리 목록
   - archive(userId, memoryId): 메모리 아카이브
   - restore(userId, memoryId): 아카이브 복원
   - getStats(userId): 아카이브 통계
3. `MemoryArchiveController` — 4개 엔드포인트
   - GET /api/memories/archive
   - POST /api/memories/{id}/archive
   - POST /api/memories/{id}/restore
   - GET /api/memories/archive/stats
4. 기존 GET /api/memories에서 archived=true 메모리 제외
5. 테스트 각 최소 3개

## 금지
- 기존 Memory Entity 구조 변경 금지 (필드 추가만)
- 커밋 1건당 파일 10개 이하
