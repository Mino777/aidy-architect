# WO-243: Server — People Notes + Contact Streak (v9.2~v9.3)

## 담당: server

## 스펙
`specs/api-contract.md` § 5.71 (People Notes), § 5.72 (Streak)

## 엔드포인트
- GET /api/people/{personId}/notes — 노트 목록
- POST /api/people/{personId}/notes — 생성
- PUT /api/people/{personId}/notes/{id} — 수정
- DELETE /api/people/{personId}/notes/{id} — 삭제
- GET /api/people/{personId}/streak — 스트릭 조회
- GET /api/streaks/leaderboard — 순위

## 구현 범위
1. PersonNote + ContactStreak 엔티티
2. PersonNoteService + StreakService
3. PersonNoteController + StreakController + 테스트
4. Flyway 마이그레이션

## 완료 기준
- 6개 엔드포인트 동작 + 테스트 PASS
- 커밋: [R7-server] feat: WO-243 설명
