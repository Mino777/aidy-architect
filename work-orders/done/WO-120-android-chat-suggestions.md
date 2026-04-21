# WO-120: AI Chat Suggestions UI (v3.4) — Android

## 담당: android
## 스펙: api-contract.md § 5.25

## 작업
1. `ChatSuggestionApi` — Retrofit 2개
2. `ChatSuggestionRepository` + ViewModel 로직
3. 채팅 화면 상단에 수평 LazyRow 추천 카드 (Compose)
   - type별 아이콘, reason 표시
   - 탭 → 채팅 입력 자동 채움 + use API 호출
4. 테스트 최소 3개

## 금지
- 기존 Chat 화면 깨지지 않게
- 커밋 1건당 파일 10개 이하
