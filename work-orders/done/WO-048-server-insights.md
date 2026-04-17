# WO-048: Memory Insights API — 서버

**워커**: server
**스펙**: api-contract v0.8 — GET /api/memories/insights
**라운드**: autoceo-s17-R4

## 작업

1. MemoryService에 getInsights(userId) 추가
2. MemoryController에 GET /api/memories/insights 추가
3. 로직:
   - categoryDistribution: count desc, percentage 소수점 1자리
   - weeklyActivity: 최근 7일 메모리 생성 수 (GROUP BY date)
   - streakDays: 오늘부터 역산 연속일
   - mostActiveCategory: count 최대
4. 테스트: 단위 + E2E

## 제약

- 커밋: `[R4-server] feat: Memory Insights API (v0.8)`
- 커밋 1건당 파일 10개 이하
