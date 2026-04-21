# WO-119: AI Chat Suggestions UI (v3.4) — iOS

## 담당: ios
## 스펙: api-contract.md § 5.25

## 작업
1. `ChatSuggestionClient` — API 2개
2. `ChatSuggestionFeature` (TCA: fetchSuggestions/useSuggestion)
3. 채팅 화면 상단에 수평 스크롤 추천 카드
   - type별 아이콘 (followup/reminder/exploration/check_in)
   - reason 표시
   - 탭 시 해당 텍스트로 채팅 입력 자동 채움 + use API 호출
4. 테스트 최소 3개

## 금지
- 기존 Chat 화면 레이아웃 깨지지 않게
- 커밋 1건당 파일 10개 이하
