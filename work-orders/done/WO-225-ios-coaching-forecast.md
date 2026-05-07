# WO-225: iOS Conversation Coaching + Relationship Forecast (v7.6~v7.7)

## 목표
AI 대화 코칭 팁 UI + 관계 예측 UI.

## 스펙 참조
- `specs/api-contract.md` §5.59 Conversation Coaching (v7.6)
- `specs/api-contract.md` §5.60 Relationship Forecast (v7.7)

## 구현 범위

### Conversation Coaching
1. CoachingClient — coaching tips + feedback API
2. CoachingFeature (TCA) — 팁 로드 + 피드백 전송
3. CoachingTipsView (SwiftUI) — 코칭 팁 카드 리스트
4. ChatView에 코칭 팁 배너/시트 추가

### Relationship Forecast
5. ForecastClient — per-person forecast + summary API
6. ForecastFeature (TCA) — 예측 데이터 로드
7. ForecastView (SwiftUI) — 예측 점수 + 트렌드 + 요인
8. ForecastSummaryView — 전체 인물 예측 요약
9. PersonDetailView에 "관계 전망" 섹션 추가

## 제약
- 커밋 메시지: `[R7-ios] feat: WO-225 Coaching + Forecast`
- tuist build 통과 필수 (xcodebuild test 금지)
- 커밋 1건당 파일 10개 이하
