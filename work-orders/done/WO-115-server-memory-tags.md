# WO-115: Memory Tags API (v3.3) — Server

## 담당: server
## 스펙: api-contract.md § 5.24

## 작업
1. `Tag` Entity + Repository
   - id, userId, name, color, createdAt
   - UNIQUE(userId, name)
2. `MemoryTag` 중간 테이블 (memory_id, tag_id)
   - 메모리당 최대 5개 제한
3. `TagService`
   - getTags(userId): 전체 태그 (사용 빈도순)
   - createTag(userId, name, color): 생성
   - deleteTag(userId, tagId): 삭제 (연관 MemoryTag도 삭제)
   - addTagsToMemory(userId, memoryId, tagIds): 태그 추가 (5개 제한 체크)
   - removeTagFromMemory(userId, memoryId, tagId): 태그 제거
4. `TagController` — 5개 엔드포인트
5. 기존 GET /api/memories에 ?tag={tagId} 쿼리 파라미터 지원
6. 테스트 각 최소 3개

## 금지
- 기존 Memory 엔티티 필드 변경 금지 (중간 테이블로 관계)
- 커밋 1건당 파일 10개 이하
