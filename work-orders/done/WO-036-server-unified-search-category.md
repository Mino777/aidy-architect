# WO-036: Server — 통합 검색 + 메모리 카테고리 변경

**담당**: server
**우선순위**: P1
**상태**: in-progress
**의존**: api-contract v0.6.0

## 구현 요구사항

### 1. GET /api/search
- 새 SearchController 생성
- SearchService: 채팅(content LIKE) + 메모리(title+content LIKE) + 인물(normalizedName+trait LIKE) 동시 검색
- 각 타입 최대 10건, case-insensitive
- 응답: { query, results: { chat[], memories[], people[] }, counts }
- q 필수, 빈 문자열 → 400

### 2. PUT /api/memories/{id} 확장
- Request에 category 필드 추가 (선택)
- category 미포함 → 기존 유지
- category 포함 → Memory Categories enum 검증, 불일치 → 400
- MemoryService.update() 수정

### 3. 테스트
- search: 전체 검색, 타입별 결과, 빈 쿼리, 결과 없음 — 4건+
- category 변경: 성공, 잘못된 카테고리, 미포함 시 유지 — 3건+

## 검증 기준
- [ ] GET /api/search 스펙 일치
- [ ] PUT /api/memories/{id} category 변경 동작
- [ ] 테스트 7건+ 추가
- [ ] ./gradlew test 전체 통과, 커밋 메시지에 통계
