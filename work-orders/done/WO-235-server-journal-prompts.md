# WO-235: Server — Relationship Journal Prompts (v8.5)

## 담당: server

## 스펙
`specs/api-contract.md` § 5.66 참조

## 엔드포인트
- GET /api/journal/prompts/today — 오늘의 프롬프트
- POST /api/journal/entries — 저널 엔트리 생성
- GET /api/journal/entries — 목록 조회
- GET /api/journal/stats — 통계
- DELETE /api/journal/entries/{id} — 삭제

## 구현 범위
1. JournalPrompt + JournalEntry 엔티티
2. JournalService (프롬프트 생성은 규칙 기반 Phase 1)
3. JournalController + 테스트
4. Flyway 마이그레이션

## 완료 기준
- 5개 엔드포인트 동작 + 테스트 PASS
- 커밋 메시지: `[R4-server] feat: WO-235 Journal Prompts`
