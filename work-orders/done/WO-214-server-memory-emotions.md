# WO-214: Server Memory Emotions (v7.2)

## 목표
메모리에 감정 태깅 (AI 자동 추출 시 emotion 필드 추가) + 수동 수정 + 트렌드 API.

## 스펙 참조
`specs/api-contract.md` §5.55 Memory Emotions (v7.2)

## 구현 범위
1. MemoryEntity에 `emotion` 필드 추가 (enum: JOY, GRATITUDE, LOVE, SADNESS, ANGER, ANXIETY, SURPRISE, NEUTRAL)
2. Flyway 마이그레이션 — memories 테이블에 emotion 컬럼 추가 (기본 NEUTRAL)
3. AI 추출 프롬프트에 emotion 필드 추가 (기존 MemoryExtractionService 수정)
4. PATCH /api/memories/{id}/emotion 엔드포인트
5. GET /api/memories 에 ?emotion= 쿼리 파라미터 지원
6. GET /api/memories/emotions/trend 엔드포인트
7. GET /api/people/{personId}/emotions 엔드포인트
8. 테스트

## 제약
- 커밋 메시지: `[R3-server] feat: WO-214 Memory Emotions`
- 새 Flyway 파일만 생성 (기존 마이그레이션 수정 금지)
- `./gradlew test` 통과 필수
- 커밋 1건당 파일 10개 이하
