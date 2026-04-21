# WO-121: Memory Deduplication API (v3.5) — Server

## 담당: server
## 스펙: api-contract.md § 5.26

## 작업
1. `MemoryDuplicateGroup` DTO (groupId, memories, similarity, suggestedMerge)
2. `MemoryDeduplicationService`
   - findDuplicates(userId, minSimilarity, limit): 메모리 간 유사도 계산
     - 같은 personName + 내용 유사도 0.8+ → 그룹핑
     - AI로 suggestedMerge 텍스트 생성
   - mergeGroup(userId, groupId, mergedContent, keepMemoryId): 병합 실행
     - keepMemoryId의 content를 mergedContent로 업데이트
     - 나머지 메모리 삭제 (soft delete 권장)
     - originalIds 기록
   - dismissGroup(userId, groupId): 그룹 무시 처리
3. `MemoryDeduplicationController` — 3개 엔드포인트
   - GET /api/memories/duplicates
   - POST /api/memories/duplicates/{groupId}/merge
   - POST /api/memories/duplicates/{groupId}/dismiss
4. dismissed 그룹 재추천 방지 (dismissed_duplicate_groups 테이블)
5. 테스트 각 최소 3개

## 금지
- 기존 Memory 엔드포인트 수정 금지
- 커밋 1건당 파일 10개 이하
