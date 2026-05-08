# WO-234: Server — AI Conversation Insights (v8.4)

## 담당: server

## 스펙
`specs/api-contract.md` § 5.65 참조

## 엔드포인트
- GET /api/chat/insights — 인사이트 목록
- GET /api/chat/insights/{id} — 상세 조회
- DELETE /api/chat/insights/{id} — 삭제

## 구현 범위
1. ChatInsight 엔티티 + JPA Repository
2. ChatInsightService (AI 분석 로직은 Phase 2, 이번엔 mock/stub)
3. ChatInsightController + 테스트
4. Flyway 마이그레이션 (새 파일만)

## 완료 기준
- 3개 엔드포인트 동작 + 테스트 PASS
- 커밋 메시지: `[R4-server] feat: WO-234 AI Conversation Insights`
- 커밋당 파일 10개 이하
