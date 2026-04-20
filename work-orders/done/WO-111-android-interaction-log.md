# WO-111: Interaction Log UI (v3.1) — Android

## 담당: android
## 스펙: api-contract.md § 5.22

## 작업
1. `InteractionApi` — Retrofit 3개 엔드포인트
2. `InteractionRepository` + `InteractionViewModel`
3. `InteractionLogScreen` (Compose)
   - type별 아이콘, duration, 시간순 정렬
4. `AddInteractionDialog` — 기록 추가
5. 인물 상세 화면에서 탭으로 진입
6. 테스트: ViewModel 최소 3개

## 금지
- 기존 Timeline 코드 수정 금지
- 커밋 1건당 파일 10개 이하
