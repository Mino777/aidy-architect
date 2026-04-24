# WO-160: Activity Heatmap API

**담당**: server
**우선순위**: P4
**상태**: backlog
**스펙**: api-contract.md §5.39

## 구현 요구사항

### 1. Controller + Service
- GET /api/activity/heatmap
- year/month 파라미터 (optional, default 현재)
- month 미지정 시 연간 데이터

### 2. 데이터 집계
- 날짜별 chatCount (ChatMessage.createdAt), memoryCount (Memory.createdAt)
- level 계산: 사분위수 기반 0~4 레벨
- summary: activeDays, totalChats, totalMemories, maxDayTotal
- streak 계산: currentStreak (오늘부터 역산), longestStreak

### 3. 성능
- GROUP BY date로 집계 (N+1 방지)
- 월간: 최대 31일, 연간: 최대 366일 — 쿼리 1~2개로 해결

### 4. 테스트
- ActivityHeatmapControllerTest: 월간/연간/빈 데이터/level 계산

## 완료 기준
- [ ] GET /api/activity/heatmap 구현
- [ ] level 0~4 사분위수 계산
- [ ] streak 계산 (current + longest)
- [ ] 빌드 PASS + 테스트 숫자 보고
