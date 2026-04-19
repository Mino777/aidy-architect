# WO-073: Memory Connections API (Server, v1.9)

**담당**: server
**우선순위**: P2
**상태**: backlog
**API 버전**: v1.9.0

## 작업 내용

### Memory Connections API
- 새 엔드포인트 3개:
  - `GET /api/memories/{id}/connections?limit=5`
  - `POST /api/memories/{id}/connections` (수동 연결)
  - `DELETE /api/memories/{id}/connections/{targetId}`
- MemoryConnectionService: AI 유사도 분석으로 관련 메모리 추천
- DB: memory_connections 테이블 (source_id, target_id, type, relevance, reason)
  - Flyway 마이그레이션 파일 새로 생성
  - UNIQUE(source_id, target_id) 제약
- type: "auto" (AI) | "manual" (사용자)
- 양방향: A→B 생성 시 B→A도 자동 생성
- AI 분석: 카테고리 + 키워드 유사도 기반 relevance 계산
- 자기 자신/dismissed/삭제된 메모리 제외

### 참조
- `specs/api-contract.md` v1.9 섹션

## 완료 기준
- [ ] GET connections 동작 (AI 추천)
- [ ] POST connections 동작 (수동 연결)
- [ ] DELETE connections 동작
- [ ] 양방향 자동 생성
- [ ] Flyway 마이그레이션
- [ ] 테스트 최소 10건
- [ ] 커밋: `[RN-server] feat: Memory Connections API (v1.9)`
