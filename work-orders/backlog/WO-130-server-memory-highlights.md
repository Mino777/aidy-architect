# WO-130: Memory Highlights API (v3.8) — Server

## 담당: server
## 스펙: api-contract.md § 5.29

## 작업
1. `MemoryHighlight` Entity + Repository
   - id, userId, memoryId, reason, importance, tags, period, periodStart, periodEnd, saved, savedAt
2. `SavedHighlight` (saved=true인 하이라이트 별도 조회용 인덱스)
3. `MemoryHighlightService`
   - generateHighlights(userId, period, date): AI가 기간 내 메모리 분석 → 핵심 선별
     - importance 0.0~1.0
     - tags: milestone, positive, negative, habit_change, relationship_change, decision, learning
     - summary 자동 생성
   - saveHighlight(userId, highlightId): 영구 저장
   - getSavedHighlights(userId, offset, limit): 저장된 하이라이트 목록
4. `MemoryHighlightController` — 3개 엔드포인트
   - GET /api/memories/highlights
   - POST /api/memories/highlights/{highlightId}/save
   - GET /api/memories/highlights/saved
5. 테스트 각 최소 3개

## 금지
- 기존 Memory 엔드포인트 수정 금지
- 커밋 1건당 파일 10개 이하
