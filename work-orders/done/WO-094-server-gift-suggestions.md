# WO-094: Server — Gift Suggestions API (v2.6)

**담당**: server
**스펙**: `specs/api-contract.md` § 5.17 Gift Suggestions (v2.6)

## 구현 범위

### API
1. **POST /api/people/{id}/gift-suggestions** — AI 선물 제안

### 로직
- Person의 PersonMemory에서 취향/관심사 추출
- 다가오는 Anniversary가 있으면 자동 occasion 설정
- AI 프롬프트로 선물 제안 생성 (기존 AiService 활용)
- sourceMemoryIds로 근거 연결
- budget 파라미터로 가격대 필터링 힌트
- rate limit: chat 버킷 공유

### 커밋 규칙
- 메시지: `[R7-server] feat: Gift Suggestions API (v2.6)`
- 파일 10개 이하/커밋

## 완료 보고

**커밋**: `[R7-server] feat: Gift Suggestions API (v2.6)` (6파일)

### 구현 내역
1. **GiftSuggestionDto**: Request(occasion, budget, count) / Response(personId, personName, occasion, suggestions[], generatedAt)
2. **GiftSuggestionService**:
   - Person 소유권 검증 (userId 매칭)
   - PersonMemory에서 취향/관심사 추출 → memoriesText 구성
   - AI 호출로 선물 제안 생성 (기존 AiService 활용)
   - occasion enum 검증: birthday/anniversary/holiday/thank_you/general
   - count coerceIn(1, 10), budget optional
3. **GiftSuggestionController**: POST `/api/people/{id}/gift-suggestions` (request body optional)
4. **AiService.generateGiftSuggestions**: sourceMemoryIds 필터링 (유효 ID만), priceRange/category AI 추정
5. **parseGiftSuggestionsResponse**: JSON 파싱 + sourceMemoryIds 유효성 필터

### 테스트 결과
- GiftSuggestionServiceTest: 10개 (정상, 기본값, 검증 에러, PERSON_NOT_FOUND, 타유저, count coerce, 전체 occasion, displayName fallback, budget 전달)
- GiftSuggestionControllerTest: 5개 (200, 빈바디, 404, 400, 401)
- `./gradlew test`: **796 tests · 0 failures · 0 errors**

### 스펙 대조
- POST /api/people/{id}/gift-suggestions → ✅
- occasion enum → ✅ birthday/anniversary/holiday/thank_you/general
- budget optional, count 1~10 → ✅
- sourceMemoryIds 연결 → ✅
- Error: PERSON_NOT_FOUND, VALIDATION_ERROR → ✅
