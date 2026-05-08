# WO-237: Server — Smart Auto-Grouping (v8.7)

## 담당: server

## 스펙
`specs/api-contract.md` § 5.68 참조

## 엔드포인트
- POST /api/people/auto-group — AI 자동 그룹핑 실행
- POST /api/people/auto-group/{id}/apply — 추천 그룹 적용

## 구현 범위
1. AutoGroupSuggestion 엔티티 (임시 저장, TTL 24h)
2. AutoGroupService — 규칙 기반 그룹핑 (Phase 1: 대화빈도 + 카테고리 기반)
3. AutoGroupController + 테스트
4. 기존 PersonGroupService 연동 (apply 시 실제 그룹 생성)

## 완료 기준
- 2개 엔드포인트 동작 + 테스트 PASS
- 커밋 메시지: `[R4-server] feat: WO-237 Smart Auto-Grouping`
