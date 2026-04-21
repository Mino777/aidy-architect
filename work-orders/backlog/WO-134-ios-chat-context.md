# WO-134: Chat Context Memory UI (v3.9) — iOS

## 담당: ios
## 스펙: api-contract.md § 5.30

## 작업
1. `ChatContext` 모델 + `ChatContextClient` API
2. `ChatContextFeature` (TCA Reducer)
   - 컨텍스트 조회/갱신/초기화
3. `ChatContextView`
   - 채팅 화면 상단에 현재 맥락 요약 배너
   - "맥락 초기화" 버튼
   - "맥락 갱신" 버튼
4. 테스트 각 최소 3개

## 금지
- 기존 Chat 화면 구조 변경 금지
- 커밋 1건당 파일 10개 이하
