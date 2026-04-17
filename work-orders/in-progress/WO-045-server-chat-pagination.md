# WO-045: Chat pagination + 전체 삭제 — 서버

**워커**: server
**스펙**: api-contract v0.8 — GET /api/chat/history pagination + DELETE /api/chat/history
**라운드**: autoceo-s17-R3

## 작업

1. GET /api/chat/history에 offset/limit 파라미터 추가
   - offset/limit 있으면 since 무시
   - X-Total-Count, X-Offset, X-Limit, X-Has-More 헤더
   - 응답에 id 필드 추가
2. DELETE /api/chat/history — 전체 대화 삭제
   - 메모리는 유지
   - { "deleted": N } 응답
3. 테스트: E2E (페이지네이션 + 전체 삭제)

## 제약

- 기존 since 방식 호환 유지
- offset >= 0, limit 1~100
- 커밋: `[R3-server] feat: Chat pagination + 전체 삭제 (v0.8)`
- 커밋 1건당 파일 10개 이하
