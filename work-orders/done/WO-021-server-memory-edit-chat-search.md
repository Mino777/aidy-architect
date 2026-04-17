# WO-021: Server — 메모리 수정 + 채팅 검색 API

**담당**: server
**우선순위**: P1-높음 (새 기능)
**상태**: in-progress
**의존**: api-contract v0.3.0

## 목표
PUT /api/memories/{id} (메모리 수정) + GET /api/chat/history/search (채팅 검색) 구현.

## 구현 요구사항

### 1. PUT /api/memories/{id}
- MemoryController에 PUT 엔드포인트 추가
- Request: `{ "title": "string", "content": "string" }` — 둘 다 필수
- 소유권 검증 (userId 일치) → 403 FORBIDDEN
- 존재 확인 → 404 MEMORY_NOT_FOUND
- title/content 빈 문자열 → 400 VALIDATION_ERROR
- category, createdAt 변경 불가
- MemoryService에 update 메서드 추가
- 응답: 수정된 MemoryItem (기존 GET과 동일 스키마)

### 2. GET /api/chat/history/search
- ChatController에 GET 엔드포인트 추가
- Query: `?q=keyword` (필수)
- `q` 빈 문자열 → 400 VALIDATION_ERROR
- ChatMessageRepository에 검색 쿼리 추가 (LIKE %keyword%, case-insensitive)
- 최대 50건, 최신순
- 응답: ChatMessage[] (기존 history와 동일 스키마)

### 3. 테스트
- MemoryController PUT 테스트 (성공, 빈 필드, 404, 403)
- ChatController search 테스트 (성공, 빈 쿼리, 결과 없음)
- 기존 226 tests 통과 유지

## 검증 기준
- [ ] PUT /api/memories/{id} 구현 + 테스트
- [ ] GET /api/chat/history/search 구현 + 테스트
- [ ] api-contract v0.3.0 스펙과 정확히 일치
- [ ] ./gradlew test 전체 통과
