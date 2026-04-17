# WO-024: Server — 채팅 삭제 + 메모리 내보내기 API

**담당**: server
**우선순위**: P1
**상태**: in-progress
**의존**: api-contract v0.3.1

## 목표
DELETE /api/chat/{id} (메시지 삭제) + GET /api/memories/export (메모리 내보내기) 구현.

## 구현 요구사항

### 1. DELETE /api/chat/{id}
- ChatController에 DELETE 엔드포인트 추가
- 소유권 검증 (userId) → 403 FORBIDDEN
- 존재 확인 → 404 MESSAGE_NOT_FOUND
- **Pair delete**: user 메시지 삭제 시 직후 assistant 메시지도 삭제
- assistant 메시지 단독 삭제: 해당 메시지만
- 추출된 메모리는 유지 (독립 엔티티)
- ChatService에 deleteMessage 메서드 추가

### 2. GET /api/memories/export
- MemoryController에 GET 엔드포인트 추가
- Response: JSON 파일 다운로드 (Content-Disposition: attachment)
- `?category=finance` 필터 가능
- 응답 스키마: { exportedAt, totalCount, memories[] }
- MemoryService에 exportMemories 메서드 추가

### 3. 테스트
- DELETE: 성공, pair delete, 404, 403 — 4건 이상
- Export: 성공, 카테고리 필터, 빈 결과 — 3건 이상
- 기존 235 tests 통과 유지

## 검증 기준
- [ ] DELETE /api/chat/{id} 스펙 일치
- [ ] GET /api/memories/export 스펙 일치
- [ ] 테스트 7건+ 추가
- [ ] ./gradlew test 전체 통과
