# WO-110: Interaction Log UI (v3.1) — iOS

## 담당: ios
## 스펙: api-contract.md § 5.22

## 작업
1. `InteractionClient` — API 3개 엔드포인트
2. `InteractionLogFeature` (TCA Reducer)
   - State: interactions, isLoading, selectedType filter
   - Action: fetch, create, delete, filterByType
3. `InteractionLogView` — 인물별 상호작용 목록
   - type별 아이콘 (meeting/call/message/video_call/other)
   - duration 표시, occurredAt 시간순 정렬
4. `AddInteractionSheet` — 기록 추가 폼
   - type picker, title, note, date picker, duration
5. 인물 상세 화면에서 탭으로 진입
6. 테스트: Reducer 최소 3개

## 금지
- 기존 Timeline 코드 수정 금지
- 커밋 1건당 파일 10개 이하
