# WO-070: Weekly Summary API (Server, v1.8)

**담당**: server
**우선순위**: P2
**상태**: backlog
**API 버전**: v1.8.0

## 작업 내용

### Weekly Summary API
- 새 엔드포인트: `GET /api/summary/weekly?weekOffset=0`
- WeeklySummaryService: 주간 통계 집계 + AI 요약 생성
- 통계 (DB 쿼리): totalChats, totalMessages, memoriesCreated, memoriesUpdated, topCategories
- AI 생성: highlights (최대 5개), advice (한 줄 조언)
- Sentiment 재활용: 주간 overall/score/trend/dominantEmotion
- Topics 재활용: topTopics (count 내림차순, 최대 5개)
- trend: 전주 대비 score 비교 → "improving" | "stable" | "declining"
- 캐싱: 같은 weekOffset으로 6시간 이내 재요청 시 캐시 반환
- 데이터 없는 경우 기본값 처리

### 참조
- `specs/api-contract.md` v1.8 섹션

## 완료 기준
- [ ] GET /api/summary/weekly 동작
- [ ] AI highlights + advice 생성
- [ ] 전주 대비 trend 계산
- [ ] 캐싱 구현
- [ ] 테스트 최소 8건
- [ ] 커밋: `[RN-server] feat: Weekly Summary API (v1.8)`
