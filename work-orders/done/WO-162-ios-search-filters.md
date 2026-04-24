# WO-162: Advanced Search Filters UI (iOS)

**담당**: ios
**우선순위**: P4
**상태**: done
**스펙**: api-contract.md §5.38

## 구현 요구사항

### 1. Search API Client 확장
- 기존 SearchClient에 필터 파라미터 추가
- SearchRequest 모델에 from/to/person/category/type/sort/limit/offset

### 2. 검색 화면 UI
- 검색바 아래 필터 칩 바 (수평 스크롤):
  - 날짜 범위 (DatePicker sheet)
  - 인물 선택 (기존 People list에서 선택)
  - 카테고리 선택 (Memory Categories enum에서 선택)
  - 타입 (채팅/메모리/인물)
  - 정렬 (관련도/최신/오래된)
- 활성 필터 칩에 X 버튼으로 개별 해제
- 페이지네이션: 스크롤 하단 도달 시 추가 로드

### 3. 테스트
- SearchFilterFeatureTests: 필터 적용/해제/페이지네이션

## 완료 기준
- [ ] 필터 칩 바 UI
- [ ] 날짜/인물/카테고리/타입/정렬 필터
- [ ] 페이지네이션
- [ ] 빌드 PASS
