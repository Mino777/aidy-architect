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
