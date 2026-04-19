# WO-066: Chat Sentiment Tracking API (v1.7)

**담당**: server
**우선순위**: P2
**상태**: backlog
**API 버전**: v1.7.0

## 작업 내용

### Chat Sentiment Analysis

엔드포인트: `GET /api/chat/sentiment?days=7`

구현:
- 최근 N일 메시지를 가져와서 AI(Claude)에 감정 분석 요청
- 프롬프트: 각 메시지의 감정 분류 (joy/calm/stress/sadness/anger) + 긍부정 점수
- 일별 집계: sentiment, score, dominantEmotion
- 전체 집계: overall, score, emotions 분포
- 캐시: ConcurrentHashMap (userId+days, 1시간 TTL) — topics 캐시 패턴 재활용

### 참조
- `specs/api-contract.md` v1.7 섹션
- ChatTopicsService 캐시 패턴 참고

## 완료 기준
- [ ] GET /api/chat/sentiment — AI 감정 분석 + 캐시
- [ ] daily 배열 (날짜별 감정 추이)
- [ ] emotions ��열 (5대 감정 분포)
- [ ] 메시지 없을 때 기본값 (neutral, 0.5)
- [ ] 테스트 최소 10건
- [ ] 커밋: `[R3-server] feat: Chat Sentiment (v1.7)`
