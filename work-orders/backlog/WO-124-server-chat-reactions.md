# WO-124: Chat Reactions API (v3.6) — Server

## 담당: server
## 스펙: api-contract.md § 5.27

## 작업
1. `ChatReaction` Entity + Repository
   - id, messageId, userId, emoji, createdAt
   - UNIQUE(messageId, userId, emoji)
2. `ChatReactionService`
   - addReaction(userId, messageId, emoji): 반응 추가
     - 허용 이모지: ❤️, 💡, 😊, 👍, 😢, 🔥
   - removeReaction(userId, messageId, reactionId): 반응 삭제
   - getReactions(userId, messageId): 메시지별 반응 목록
   - getStats(userId, days): 반응 통계 (byEmoji, reactionRate)
3. `ChatReactionController` — 4개 엔드포인트
   - POST /api/chat/{messageId}/reactions
   - DELETE /api/chat/{messageId}/reactions/{reactionId}
   - GET /api/chat/{messageId}/reactions
   - GET /api/chat/reactions/stats
4. 테스트 각 최소 3개

## 금지
- 기존 Chat 엔드포인트 수정 금지
- 커밋 1건당 파일 10개 이하
