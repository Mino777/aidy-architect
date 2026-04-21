# WO-125: Chat Reactions UI (v3.6) — iOS

## 담당: ios
## 스펙: api-contract.md § 5.27

## 작업
1. `ChatReaction` 모델 + `ChatReactionClient` API
2. `ChatReactionFeature` (TCA Reducer)
   - 메시지 롱프레스 → 이모지 선택 팝업
   - 반응 추가/제거 토글
   - 반응 통계 조회
3. `ChatReactionView`
   - 메시지 하단 이모지 반응 바 (작은 이모지 + 카운트)
   - 이모지 선택 팝업 (6종: ❤️💡😊👍😢🔥)
   - 반응 통계 화면 (차트)
4. 기존 ChatBubbleView에 반응 영역 추가
5. 테스트 각 최소 3개

## 금지
- 기존 Chat 메시지 레이아웃 구조 변경 금지
- 커밋 1건당 파일 10개 이하
