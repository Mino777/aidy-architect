# WO-030: Server E2E 테스트 — v0.3~v0.4 엔드포인트

**담당**: server
**우선순위**: P2
**상태**: in-progress

## 목표
s11-s13에서 추가된 엔드포인트의 E2E 테스트 작성. 실 DB + HTTP 요청으로 검증.

## 대상 엔드포인트 (E2E 미커버)
1. PUT /api/memories/{id} — 메모리 수정
2. GET /api/chat/history/search — 채팅 검색
3. DELETE /api/chat/{id} — 메시지 삭제 (pair delete)
4. GET /api/memories/export — 내보내기
5. PATCH /api/auth/profile — 프로필 수정
6. POST /api/memories/{id}/pin — 핀 토글

## 검증 기준
- [ ] 6개 엔드포인트 각 1건+ E2E 테스트
- [ ] 기존 250 tests 통과 유지
- [ ] ./gradlew test 전체 통과, 커밋 메시지에 통계 포함
