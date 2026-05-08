# WO-242: Server — Digest Preview + AI Memory Questions (v9.0~v9.1)

## 담당: server

## 스펙
`specs/api-contract.md` § 5.69 (Digest), § 5.70 (Memory Questions)

## 엔드포인트
- GET /api/digest/weekly — 주간 다이제스트
- GET /api/digest/weekly/history — 다이제스트 이력
- GET /api/memory-questions — AI 질문 목록
- POST /api/memory-questions/{id}/answer — 답변 + 메모리 생성
- POST /api/memory-questions/{id}/skip — 건너뛰기

## 구현 범위
1. WeeklyDigest 엔티티 + MemoryQuestion 엔티티
2. DigestService + MemoryQuestionService
3. DigestController + MemoryQuestionController + 테스트
4. Flyway 마이그레이션 (새 파일만)

## 완료 기준
- 5개 엔드포인트 동작 + 테스트 PASS
- 커밋: [R7-server] feat: WO-242 설명 / 커밋당 파일 10개 이하
