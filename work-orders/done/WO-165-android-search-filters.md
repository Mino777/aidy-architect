# WO-165: Advanced Search Filters UI (Android)

**담당**: android
**우선순위**: P4
**상태**: done
**스펙**: api-contract.md §5.38

## 구현 요구사항

### 1. Search API 확장
- SearchRepository에 필터 파라미터 추가
- SearchApi에 query params 추가

### 2. 검색 화면 UI
- 검색바 아래 필터 칩 바 (LazyRow):
  - 날짜 범위 (DateRangePicker)
  - 인물 선택 (기존 People list 활용)
  - 카테고리 선택 (FilterChip)
  - 타입 (채팅/메모리/인물)
  - 정렬 (관련도/최신/오래된)
- FilterChip으로 활성 필터 표시, X로 해제
- 페이지네이션: LazyColumn + 추가 로드

### 3. 테스트
- SearchViewModelTest 보강: 필터 적용/해제/페이지네이션

## 완료 기준
- [ ] 필터 칩 바 UI
- [ ] 날짜/인물/카테고리/타입/정렬 필터
- [ ] 페이지네이션
- [ ] 빌드 PASS + 테스트 숫자 보고
