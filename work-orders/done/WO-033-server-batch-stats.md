# WO-033: Server — 메모리 일괄 작업 + 채팅 통계

**담당**: server
**우선순위**: P1
**상태**: in-progress
**의존**: api-contract v0.5.0

## 구현 요구사항

### 1. POST /api/memories/batch
- MemoryController에 POST 엔드포인트 추가
- Request: { action: "delete"|"pin"|"unpin", memoryIds: Long[] }
- memoryIds 최대 50개 검증
- 본인 소유만 처리 (타인 skip)
- MemoryService에 batchOperation 메서드

### 2. GET /api/chat/stats
- ChatController에 GET 엔드포인트 추가
- ChatService에 getStats 메서드
- 응답: totalMessages, userMessages, assistantMessages, firstMessageAt, lastMessageAt, totalMemoriesExtracted, dailyAverage
- 메시지 0건 → 숫자 0, 날짜 null

### 3. 테스트
- batch: delete/pin/unpin 성공, 빈 배열, 50개 초과, 타인 메모리 skip — 5건+
- stats: 정상, 메시지 0건 — 2건+

## 검증 기준
- [ ] POST /api/memories/batch 스펙 일치
- [ ] GET /api/chat/stats 스펙 일치
- [ ] 테스트 7건+ 추가
- [ ] ./gradlew test 전체 통과, 커밋 메시지에 통계 포함
