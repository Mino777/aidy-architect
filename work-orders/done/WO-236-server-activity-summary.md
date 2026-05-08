# WO-236: Server — Contact Activity Summary (v8.6)

## 담당: server

## 스펙
`specs/api-contract.md` § 5.67 참조

## 엔드포인트
- GET /api/people/{personId}/activity-summary — 인물별 활동 요약

## 구현 범위
1. ActivitySummaryService — 기존 서비스 데이터 집계 (Chat, Memory, Emotion, Event 등)
2. ActivitySummaryController + 테스트
3. AI 요약 텍스트 생성 (기존 AI 서비스 재사용)

## 완료 기준
- 엔드포인트 동작 + 테스트 PASS
- 커밋 메시지: `[R4-server] feat: WO-236 Contact Activity Summary`
