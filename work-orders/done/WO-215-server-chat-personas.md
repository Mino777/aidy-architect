# WO-215: Server AI Chat Personas (v7.3)

## 목표
AI 대화 스타일(페르소나) 설정. 인물별 오버라이드 가능.

## 스펙 참조
`specs/api-contract.md` §5.56 AI Chat Personas (v7.3)

## 구현 범위
1. PersonaEnum (5종: empathetic, analytical, cheerful, reflective, default)
2. UserEntity에 `defaultPersona` 필드 추가 (기본 "default")
3. PersonEntity에 `personaOverride` 필드 추가 (nullable)
4. Flyway 마이그레이션 2개 (users + people 테이블)
5. PersonaController — GET personas, PUT chat/persona, PUT people/{id}/persona, DELETE
6. ChatService 수정 — AI 프롬프트에 페르소나 시스템 프롬프트 주입
7. 테스트

## 제약
- 커밋 메시지: `[R3-server] feat: WO-215 AI Chat Personas`
- `./gradlew test` 통과 필수
- 커밋 1건당 파일 10개 이하
