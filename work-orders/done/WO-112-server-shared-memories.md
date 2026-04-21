# WO-112: Shared Memories API (v3.2) — Server

## 담당: server
## 스펙: api-contract.md § 5.23

## 작업
1. `MemoryShare` Entity + Repository
   - id, userId, memoryId, shareId(12자 랜덤), expiresAt, createdAt
   - UNIQUE(shareId)
2. `MemoryShareService`
   - createShare(userId, memoryId, expiresInHours): 공유 링크 생성
   - getSharedMemory(shareId): 공유 메모리 조회 (만료 체크)
   - deleteShare(userId, memoryId): 공유 해제
3. `MemoryShareController` — 3개 엔드포인트
   - POST /api/memories/{id}/share
   - GET /api/shared/{shareId} (인증 불필요)
   - DELETE /api/memories/{id}/share
4. 테스트 각 최소 3개

## 금지
- 기존 Memory 엔티티 구조 변경 금지
- 커밋 1건당 파일 10개 이하
