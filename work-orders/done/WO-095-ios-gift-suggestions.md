# WO-095: iOS — Gift Suggestions UI (v2.6)

**담당**: ios
**스펙**: `specs/api-contract.md` § 5.17 Gift Suggestions (v2.6)
**선행**: WO-094 (서버 API)

## 구현 범위

### 화면
1. **GiftSuggestionsView** — 선물 제안 카드 리스트
   - category별 아이콘
   - priceRange 표시
   - reason 텍스트 (AI가 생성한 근거)
   - sourceMemoryIds 탭하면 해당 메모리로 이동
2. **GiftRequestSheet** — 요청 설정 시트
   - occasion 선택 (Picker)
   - budget 입력 (TextField, 숫자)
   - count 스테퍼 (1~10)

### 데이터
1. **GiftSuggestionsClient** — POST /api/people/{id}/gift-suggestions
2. **GiftSuggestionsFeature (TCA)** — 상태 관리
3. People 상세에서 "선물 추천" 버튼 추가

### 커밋 규칙
- 메시지: `[R8-ios] feat: Gift Suggestions UI (v2.6)`
- 파일 10개 이하/커밋

---

## 완료 보고

**커밋**: `[R8-ios] feat: Gift Suggestions UI (v2.6)`
**파일 수**: 9 (신규 5 + 수정 4)
**테스트**: 554 tests, 0 failures (전체 PASS)
**신규 테스트**: 15건 전체 PASS

### 구현 내역

| 항목 | 파일 | 상태 |
|------|------|------|
| Model | `Core/Model/GiftSuggestion.swift` | GiftSuggestion, GiftOccasion, Request/Response |
| Client | `Core/Network/GiftSuggestionsClient.swift` | POST /api/people/{id}/gift-suggestions |
| Feature | `Feature/People/GiftSuggestionsFeature.swift` | occasion/budget/count + 요청/결과 관리 |
| SuggestionsView | `Feature/People/GiftSuggestionsView.swift` | category 아이콘, priceRange, reason, sourceMemoryIds |
| RequestSheet | `Feature/People/GiftRequestSheet.swift` | occasion 피커, budget 입력, count 스테퍼(1~10) |
| PersonDetailFeature | `Feature/People/PersonDetailFeature.swift` | @Presents giftSuggestions + giftSuggestionsTapped |
| PersonDetailView | `Feature/People/PersonDetailView.swift` | '선물 추천' 버튼 + sheet |
| L10n | `Core/L10n/L10n.swift` | 선물 추천 한/영 22개 문자열 |
| Tests | `Tests/GiftSuggestionsFeatureTests.swift` | 15 tests (13 feature + 2 integration) |

### 스펙 준수 확인
- [x] API contract § 5.17 필드명/타입 1:1 대조 완료
- [x] 엔드포인트 URL contract 그대로 복사
- [x] Keychain 토큰 사용 (UserDefaults 미사용)
- [x] count: 1~10 범위 클램핑
- [x] budget: 빈 문자열 → nil 전달
- [x] TestStore 테스트 필수 (happy + error + edge cases)
