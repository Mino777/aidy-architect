# WO-126: Chat Reactions UI (v3.6) — Android

## 담당: android
## 스펙: api-contract.md § 5.27

## 작업
1. `ChatReaction` 데이터 클래스 + `ChatReactionApi` Retrofit
2. `ChatReactionRepository` + ViewModel 통합
   - 메시지 롱프레스 → 이모지 선택 팝업
   - 반응 추가/제거 토글
   - 반응 통계 조회
3. Compose UI
   - 메시지 하단 이모지 반응 바 (작은 이모지 + 카운트)
   - 이모지 선택 다이얼로그 (6종: ❤️💡😊👍😢🔥)
   - 반응 통계 화면
4. 기존 ChatBubble에 반응 영역 추가
5. 테스트 각 최소 3개

## 금지
- 기존 Chat 메시지 컴포넌트 구조 변경 금지
- 커밋 1건당 파일 10개 이하
