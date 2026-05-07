# WO-228: Server Conversation Starters V2 + Insights Report V2 (v8.2~v8.3)

## 목표
대화 카드 V2 (카테고리+난이도+저장) + 월간/연간 리포트 확장.

## 스펙 참조
- `specs/api-contract.md` §5.63 Conversation Starters V2 (v8.2)
- `specs/api-contract.md` §5.64 Relationship Insights Report V2 (v8.3)

## 구현 범위

### Conversation Starters V2 (v8.2)
1. StarterCardEntity + SavedCardEntity
2. Flyway V62__create_starter_cards.sql
3. StarterCardService — 카드 생성 (룰 기반, 인물 데이터 활용) + 저장 + 사용 기록
4. StarterCardController — GET cards, POST save, GET saved, DELETE saved, POST used (5개)
5. 테스트

### Insights Report V2 (v8.3)
6. ReportService — 월간/연간 리포트 생성 (룰 기반 집계, AI 호출 X)
7. ReportController — GET monthly, GET yearly (2개)
8. 기존 데이터 집계: 대화수, 메모리수, 감정 평균, 활성 인물, 목표 달성, 감사 일기
9. 테스트

## 영향 테스트
- 기존 Service 주입만 (시그니처 변경 없음)

## Flyway
- V62 사용

## 제약
- 커밋 메시지: `[R3-server] feat: WO-228 ...`
- `./gradlew test` 통과 필수
- 커밋 1건당 파일 10개 이하
