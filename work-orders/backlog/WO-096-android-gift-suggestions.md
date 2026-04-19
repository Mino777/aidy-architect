# WO-096: Android — Gift Suggestions UI (v2.6)

**담당**: android
**스펙**: `specs/api-contract.md` § 5.17 Gift Suggestions (v2.6)
**선행**: WO-094 (서버 API)

## 구현 범위

### 화면
1. **GiftSuggestionsScreen** — 선물 제안 카드 리스트
   - category별 아이콘
   - priceRange 표시
   - reason 텍스트 (AI 근거)
   - sourceMemoryIds 탭 → 메모리 상세
2. **GiftRequestDialog** — 요청 설정 다이얼로그
   - occasion 드롭다운
   - budget 입력 (NumberTextField)
   - count Slider (1~10)

### 데이터
1. **GiftSuggestionsApi** — Retrofit
2. **GiftSuggestionsRepository**
3. **GiftSuggestionsViewModel** — 상태 관리
4. People 상세에서 "선물 추천" 버튼 추가

### 커밋 규칙
- 메시지: `[R8-android] feat: Gift Suggestions UI (v2.6)`
- 파일 10개 이하/커밋
