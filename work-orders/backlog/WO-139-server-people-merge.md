# WO-139: People Merge Suggestions API (v4.1) — Server

## 담당: server
## 스펙: api-contract.md § 5.32

## 작업
1. `PersonMergeSuggestion` Entity + Repository
   - id, userId, person1Id, person2Id, confidence, reason, sharedMemoryCount, dismissed
2. `PersonMergeService`
   - getSuggestions(userId): AI가 이름/메모리 패턴으로 중복 인물 탐지
   - merge(userId, suggestionId, keepPersonId): 두 인물 병합
     - keepPerson의 이름 유지
     - 다른 인물의 메모리 이관 (personName 업데이트)
     - 다른 인물 삭제 (soft delete)
   - dismiss(userId, suggestionId): 제안 무시
3. `PersonMergeController` — 3개 엔드포인트
   - GET /api/people/merge-suggestions
   - POST /api/people/merge-suggestions/{id}/merge
   - POST /api/people/merge-suggestions/{id}/dismiss
4. 테스트 각 최소 3개

## 금지
- 기존 People 엔드포인트 수정 금지
- 커밋 1건당 파일 10개 이하
