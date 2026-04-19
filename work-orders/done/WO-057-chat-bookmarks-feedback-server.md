# WO-057: Chat Bookmarks + AI Feedback API (v1.4)

**담당**: server
**우선순위**: P2
**상태**: done
**API 버��**: v1.4.0

## 작업 내용

### 1. Chat Bookmarks

DB 마이그레이션:
- `chat_bookmark` 테이블: `id`, `user_id`, `message_id`, `created_at`
- UNIQUE(user_id, message_id)

엔드포인트:
- `POST /api/chat/{id}/bookmark` — 북마크 토글 (있으면 해제, 없으면 추가)
- `GET /api/chat/bookmarks` — 북마크 목록 (offset/limit, bookmarkedAt DESC)

### 2. AI Feedback

DB 마이그레이션:
- `chat_feedback` 테이블: `id`, `user_id`, `message_id`, `rating` (good/bad), `created_at`, `updated_at`
- UNIQUE(user_id, message_id)

엔드포인트:
- `POST /api/chat/{id}/feedback` — 피드백 upsert (assistant 메시지만)

### 참조
- `specs/api-contract.md` v1.4 섹션
- `specs/conventions.md`

## 완료 기준
- [ ] Flyway 마이그레이션 파일 생성 (기존 파일 수정 금지)
- [ ] POST /api/chat/{id}/bookmark — 토글 동작 확인
- [ ] GET /api/chat/bookmarks — 페이지네이션 동작 확인
- [ ] POST /api/chat/{id}/feedback — good/bad upsert 동작 확인
- [ ] assistant 메시지만 피드백 가능 (user 메시지 시 400)
- [ ] 테스트 작성 (최소 10건)
- [ ] 커밋: `[R2-server] feat: Chat Bookmarks + AI Feedback (v1.4)`
