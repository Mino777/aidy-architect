# WO-226: Android Conversation Coaching + Relationship Forecast (v7.6~v7.7)

## 목표
AI 대화 코칭 팁 UI + 관계 예측 UI.

## 스펙 참조
- `specs/api-contract.md` §5.59 Conversation Coaching (v7.6)
- `specs/api-contract.md` §5.60 Relationship Forecast (v7.7)

## 구현 범위

### Conversation Coaching
1. CoachingApiService — coaching tips + feedback 엔드포인트
2. CoachingRepository
3. CoachingViewModel — 팁 로드 + 피드백 전송
4. CoachingTipsScreen (Compose) — 코칭 팁 카드 리스트
5. ChatScreen에 코칭 팁 배너 추가

### Relationship Forecast
6. ForecastApiService — per-person + summary 엔드포인트
7. ForecastRepository
8. ForecastViewModel — 예측 데이터 로드
9. ForecastScreen (Compose) — 예측 점수 + 트렌드 차트
10. ForecastSummaryScreen — 전체 예측 요약
11. PersonDetailScreen에 "관계 전망" 섹션 추가
12. ViewModel 테스트

## 제약
- 커밋 메시지: `[R8-android] feat: WO-226 Coaching + Forecast`
- testDebugUnitTest 통과 필수
- 커밋 1건당 파일 10개 이하
