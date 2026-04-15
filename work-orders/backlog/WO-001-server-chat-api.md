# WO-001: 채팅 API + 메모리 추출 파이프라인

**담당**: server
**우선순위**: P0-긴급
**상태**: backlog
**의존**: 없음 (첫 작업)

## 목표
사용자가 메시지를 보내면 AI가 응답하고, 대화에서 중요 정보를 자동 추출하여 메모리에 저장하는 코어 파이프라인 완성.

## 스펙 참조
- `specs/api-contract.md` § 2. Chat
- `specs/api-contract.md` § 3. Memory
- `specs/api-contract.md` § 4. Health

## 구현 요구사항
1. Docker PostgreSQL 실행 + Flyway 마이그레이션 검증
2. `POST /api/chat` — 메시지 수신 → AI 호출 → 응답 + 메모리 추출
3. `GET /api/chat/history` — 최근 20건 조회
4. `GET /api/memories` — 전체/카테고리별 조회
5. `GET /api/memories/search` — 키워드 검색
6. `DELETE /api/memories/{id}` — 삭제 (권한 체크)
7. `GET /api/memories/categories` — 카테고리 요약 (신규 엔드포인트)
8. `GET /api/health` — 헬스 체크
9. Error response 형식: `{ "error": "메시지", "code": "ERROR_CODE" }` 통일

## 테스트 요구사항
- [ ] ChatController 통합 테스트 (MockMvc)
- [ ] MemoryService 단위 테스트
- [ ] AI 응답에서 메모리 추출 파싱 테스트
- [ ] 빈 메시지 → 400 EMPTY_MESSAGE
- [ ] 존재하지 않는 메모리 삭제 → 404 MEMORY_NOT_FOUND

## 검증 기준
- [ ] `./gradlew test` 전체 통과
- [ ] `./gradlew build` 통과
- [ ] Docker PostgreSQL + bootRun 정상 기동
- [ ] curl로 채팅 → 응답 + 메모리 저장 확인
- [ ] Error code가 스펙과 정확히 일치

## 워커 세션 시작 명령
```
이 세션의 역할: aidy-server 백엔드 워커
프로젝트: ~/Develop/aidy-server

시작 전 반드시 읽기:
1. ~/Develop/aidy-server/CLAUDE.md
2. ~/Develop/aidy-architect/specs/api-contract.md
3. ~/Develop/aidy-architect/specs/conventions.md
4. 이 work-order (WO-001)

작업 완료 후:
- git commit + push
- 이 파일의 "완료 보고" 섹션 작성
```

## 완료 보고
- PR:
- 소요 시간:
- 특이사항:
