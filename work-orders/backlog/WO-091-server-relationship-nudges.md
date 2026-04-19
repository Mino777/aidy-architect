# WO-091: Server — Relationship Nudges API (v2.5)

**담당**: server
**스펙**: `specs/api-contract.md` § 5.16 Relationship Nudges (v2.5)

## 구현 범위

### DB
1. `nudges` 테이블 (Flyway 마이그레이션)
   - id, user_id, person_id, reason, suggestion, priority, dismissed, created_at
2. `nudge_settings` 테이블
   - user_id, enabled, silent_days_threshold, max_nudges_per_day, excluded_person_ids (JSON)

### API
1. **GET /api/nudges** — 활성 넛지 목록 (priority 정렬)
2. **POST /api/nudges/{id}/dismiss** — 넛지 숨김 (7일 후 재생성 가능)
3. **GET /api/nudges/settings** — 넛지 설정 조회
4. **PUT /api/nudges/settings** — 넛지 설정 업데이트

### 로직
- Person의 lastMentionedAt + silentDaysThreshold로 넛지 생성
- Daily Digest 생성 시 함께 갱신 (별도 스케줄러 불필요)
- priority: high(30일+), medium(14~29일), low(7~13일)
- AI 호출로 suggestion 생성 (chat 버킷 rate limit)
- excludedPersonIds에 포함된 인물 제외

### 커밋 규칙
- 메시지: `[R6-server] feat: Relationship Nudges API (v2.5)`
- 파일 10개 이하/커밋
