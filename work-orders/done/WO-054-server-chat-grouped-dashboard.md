# WO-054: 대화 그룹핑 + 대시보드 — Server

**워커**: server
**스펙**: api-contract v1.3 — GET /api/chat/history/grouped, GET /api/user/dashboard
**라운드**: autoceo-s22-R6

## 작업

1. ChatController에 `GET /api/chat/history/grouped` 추가
   - 날짜별 대화 그룹핑 (messageCount, firstMessage, lastMessage, topics, memoriesCreated)
   - days 파라미터 (기본 7, 최대 30)
2. 새 DashboardController에 `GET /api/user/dashboard` 추가
   - chat/memory/people/activity 4개 섹션 통합 통계
   - 기존 서비스 메서드 조합 (새 쿼리 최소화)
3. 응답 DTO 정의
4. 유닛 + E2E 테스트

## 제약

- 커밋: `[R6-server] feat: 대화 그룹핑 + 대시보드 (v1.3)`
- 커밋 1건당 파일 10개 이하
