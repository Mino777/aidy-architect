# WO-097: Server — Relationship Timeline API (v2.7)

**담당**: server
**스펙**: `specs/api-contract.md` § 5.18 Relationship Timeline (v2.7)

## 구현 범위

### API
1. **GET /api/people/{personId}/timeline** — 인물별 상호작용 통합 타임라인

### 로직
- Person 소유권 검증 (userId 매칭)
- 3가지 이벤트 타입 통합: chat, memory, anniversary
- **chat**: PersonMemory와 연결된 ChatMessage 조회 (person_memories → memories → chat_messages)
- **memory**: 해당 Person의 PersonMemory 목록
- **anniversary**: 해당 Person의 Anniversary 목록 (미래 포함)
- types 파라미터로 필터링 (쉼표 구분, 기본 전체)
- 정렬: timestamp 내림차순, isFuture=true인 기념일은 맨 위
- 페이지네이션: limit(1~50, 기본 20) + offset(기본 0)
- detail: 원본 content 앞 100자 요약
- PersonMemory JOIN 쿼리 최적화 (N+1 방지)

### 커밋 규칙
- 메시지: `[R2-server] feat: Relationship Timeline API (v2.7)`
- 파일 10개 이하/커밋
