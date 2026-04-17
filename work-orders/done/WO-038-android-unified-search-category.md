# WO-038: Android — 통합 검색 + 메모리 카테고리 변경 UI

**담당**: android
**우선순위**: P1
**상태**: in-progress
**의존**: WO-036

## 구현 요구사항

### 1. 통합 검색 UI
- 새 화면 또는 기존 화면에 통합 검색 바
- ApiService.search(query) → GET /api/search?q=
- 결과 섹션별: 채팅 / 메모리 / 인물
- 각 섹션 탭 → 상세 이동
- debounce 300ms

### 2. 메모리 카테고리 변경
- MemoryScreen 수정 다이얼로그에서 category DropdownMenu 추가
- ApiService.updateMemory에 category 파라미터 추가
- MemoryViewModel updateMemory에 category 반영

### 3. TestTags
- SEARCH_UNIFIED_TEXTFIELD, SEARCH_CHAT_SECTION, SEARCH_MEMORY_SECTION, SEARCH_PEOPLE_SECTION
- MEMORY_EDIT_CATEGORY_PICKER

### 4. Feature Catalog 업데이트
- docs/feature-catalog.md에 통합 검색 + 카테고리 변경 추가

## 검증 기준
- [ ] 통합 검색 UI + API 연동
- [ ] 카테고리 변경 UI + API 연동
- [ ] Feature Catalog 업데이트
- [ ] 기존 테스트 통과 유지
