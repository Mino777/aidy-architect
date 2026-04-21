# WO-118: AI Chat Suggestions API (v3.4) — Server

## 담당: server
## 스펙: api-contract.md § 5.25

## 작업
1. `ChatSuggestion` DTO (id, type, text, reason, relatedMemoryId, personName)
2. `ChatSuggestionService`
   - generateSuggestions(userId, limit): AI가 맥락 분석 → 추천 생성
     - followup: 2주+ 된 미해결 메모리 후속 질문
     - reminder: 7일 내 기념일/일정
     - exploration: 2주+ 메모리 없는 카테고리
     - check_in: healthScore 낮은 인물 안부
   - markUsed(userId, suggestionId): 사용 기록
3. `ChatSuggestionController` — 2개 엔드포인트
   - GET /api/chat/suggestions
   - POST /api/chat/suggestions/{id}/use
4. 테스트 각 최소 3개

## 금지
- 기존 Chat 엔드포인트 수정 금지
- 커밋 1건당 파일 10개 이하
