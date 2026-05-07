# WO-222: Server Conversation Coaching + Relationship Forecast (v7.6~v7.7)

## 목표
AI 대화 코칭 팁 생성 + 관계 건강 예측.

## 스펙 참조
- `specs/api-contract.md` §5.59 Conversation Coaching (v7.6)
- `specs/api-contract.md` §5.60 Relationship Forecast (v7.7)

## 구현 범위

### Conversation Coaching (v7.6)
1. CoachingService — 인물의 최근 메모리, 감정 트렌드, 생애 이벤트를 종합해 팁 생성
2. CoachingController — GET /api/chat/coaching/{personId}, POST feedback (2개 엔드포인트)
3. CoachingTip 모델 (type enum: TOPIC_SUGGEST, TONE_ADVICE, AVOID_TOPIC, FOLLOW_UP, LIFE_EVENT)
4. 팁 생성은 룰 기반 (AI 호출 없이 메모리/감정/이벤트 데이터 기반 로직)

### Relationship Forecast (v7.7)
5. ForecastService — 최근 30일 interaction 빈도, 감정 분포, 목표 달성률로 예측 점수 계산
6. ForecastController — GET /api/people/{personId}/forecast, GET /api/forecast/summary (2개 엔드포인트)
7. 예측은 룰 기반 (연락 빈도 추세 + 감정 트렌드 + 목표 overdue 가중)

## 영향 테스트 (사전 분석)
- MemoryService, GoalService, LifeEventService를 주입받지만 시그니처 변경 없음
- 기존 테스트 영향 없음

## 제약
- 커밋 메시지: `[R3-server] feat: WO-222 Coaching + Forecast`
- `./gradlew test` 통과 필수
- 커밋 1건당 파일 10개 이하 (초과 시 분할)
