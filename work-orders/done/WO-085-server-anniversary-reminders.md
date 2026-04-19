# WO-085: Server — Anniversary Reminders API (v2.3)

**담당**: server
**스펙**: `specs/api-contract.md` § 5.14 Anniversary Reminders (v2.3)
**선행**: 없음

## 구현 범위

### 엔드포인트
1. `GET /api/anniversaries` — 목록 조회 (?upcoming=true&days=30)
2. `POST /api/anniversaries` — 수동 등록
3. `PUT /api/anniversaries/{id}` — 수정
4. `DELETE /api/anniversaries/{id}` — 삭제
5. `POST /api/anniversaries/detect` — AI 자동 감지

### 상세
1. **Anniversary 엔티티** — id, userId, personId, title, date(MM-dd), type, note, autoDetected, sourceMemoryId, createdAt
2. **AnniversaryController** — 5개 엔드포인트
3. **AnniversaryService**
   - CRUD 로직
   - detect: AI가 메모리 스캔 → 기념일 후보 반환 (저장 안 함)
   - daysUntil, nextOccurrence 자동 계산
4. **type enum**: birthday | anniversary | custom
5. **Flyway 마이그레이션**: anniversaries 테이블 (새 파일만 생성)
6. **에러**: PERSON_NOT_FOUND, ANNIVERSARY_NOT_FOUND, VALIDATION_ERROR

### 커밋 규칙
- 메시지: `[R3-server] feat: Anniversary Reminders API (v2.3)`
- 파일 10개 이하/커밋
