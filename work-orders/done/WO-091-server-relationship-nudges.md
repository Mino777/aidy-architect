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

## 완료 보고

**커밋 1**: `[R4-server] feat: Relationship Nudges API (v2.5) — 구현` (9파일)
**커밋 2**: `[R4-server] test: Relationship Nudges 테스트 추가` (2파일)

### 구현 내역
1. **V29 Flyway 마이그레이션**: `nudges` (user_id, person_id, reason, suggestion, priority, dismissed, dismissed_at) + `nudge_settings` (enabled, silent_days_threshold, max_nudges_per_day, excluded_person_ids JSON)
2. **Nudge 엔티티**: User/Person ManyToOne, dismissed 상태 관리
3. **NudgeSettings 엔티티**: User OneToOne, excludedPersonIds JSON TEXT
4. **NudgeRepository**: findByUserIdAndDismissedFalseOrderByCreatedAtDesc, findByIdAndUserId
5. **NudgeSettingsRepository**: findByUserId
6. **NudgeService**:
   - `listNudges`: priority 정렬 (high>medium>low), daysSilent 계산, limit coerceIn(1,20)
   - `dismiss`: dismissed=true + dismissedAt 기록
   - `getSettingsOrCreate`/`updateSettings`: partial update, JSON 직렬화
   - 검증: silentDaysThreshold 1~90, maxNudgesPerDay 1~10
7. **NudgeController**: 4개 엔드포인트 (스펙 § 5.16 일치)
8. **NUDGE_NOT_FOUND** 에러 코드 추가

### 테스트 결과
- NudgeServiceTest: 13개 (listNudges 3, dismiss 2, settings 8)
- NudgeControllerTest: 8개 (GET/POST/PUT + 인증 + 에러)
- `./gradlew test`: **748 tests · 0 failures · 0 errors**

### 스펙 대조
- GET /api/nudges → ✅ priority 정렬, limit, daysSilent 계산
- POST /api/nudges/{id}/dismiss → ✅ 204, NUDGE_NOT_FOUND
- GET /api/nudges/settings → ✅ 기본값 일치
- PUT /api/nudges/settings → ✅ partial update, VALIDATION_ERROR
