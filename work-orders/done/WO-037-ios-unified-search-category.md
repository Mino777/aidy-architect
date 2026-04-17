# WO-037: iOS — 통합 검색 + 메모리 카테고리 변경 UI

**담당**: ios
**우선순위**: P1
**상태**: in-progress
**의존**: WO-036

## 구현 요구사항

### 1. 통합 검색 UI
- 새 탭 또는 기존 탭에 통합 검색 바 추가
- APIClient.search(query:) → GET /api/search?q=
- 결과를 섹션별 표시: 채팅 / 메모리 / 인물
- 각 섹션 탭 시 해당 상세로 이동
- debounce 300ms

### 2. 메모리 카테고리 변경
- MemoryView 수정 시트에서 category Picker 추가 (기존 읽기전용 → 편집 가능)
- APIClient.updateMemory에 category 파라미터 추가
- MemoryFeature editMemory에 category 변경 반영

### 3. accessibilityIdentifier
- search_unified_textfield, search_chat_section, search_memory_section, search_people_section
- memory_edit_category_picker

### 4. Feature Catalog 업데이트
- docs/feature-catalog.md에 통합 검색 + 카테고리 변경 추가

## 검증 기준
- [ ] 통합 검색 UI + API 연동
- [ ] 카테고리 변경 UI + API 연동
- [ ] Feature Catalog 업데이트
- [ ] 기존 테스트 통과 유지
