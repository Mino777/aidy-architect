# WO-159: Advanced Search Filters API

**담당**: server
**우선순위**: P4
**상태**: done
**스펙**: api-contract.md §5.38

## 구현 요구사항

### 1. 기존 SearchController/Service 확장
- GET /api/search에 신규 파라미터 추가: from, to, person, category, type, sort, limit, offset
- 기존 q-only 검색 하위 호환 유지

### 2. 필터 로직
- from/to: createdAt BETWEEN (inclusive)
- person: Memory → Person 관계를 통해 normalizedName LIKE
- category: Memory.category 정확 일치
- type: chat/memories/people 중 선택 (미지정 시 전체)
- sort: relevance(기본), newest(createdAt DESC), oldest(createdAt ASC)
- pagination: limit/offset

### 3. Browse 모드
- q가 빈 문자열 + 다른 필터 있으면 → 필터만으로 검색 (LIKE 없이)
- q도 필터도 없으면 → 400 VALIDATION_ERROR

### 4. 테스트
- SearchControllerTest 보강: 필터 조합 테스트

## 완료 기준
- [ ] 7개 신규 파라미터 지원
- [ ] 기존 검색 하위 호환
- [ ] 빌드 PASS + 테스트 숫자 보고
