# Aidy API Contract v0.1

> **이 문서는 설계자(Architect)만 수정한다.**
> 워커는 이 스펙을 읽고 구현한다. 스펙과 다른 구현은 Gate 1에서 차단된다.

## Base

- **Base URL**: `{SERVER_URL}/api`
- **Content-Type**: `application/json`
- **Auth Header**: `Authorization: Bearer {JWT_TOKEN}` (v0.2+)
- **User Header**: `X-User-Id: {userId}` (v0.1 임시)
- **Error Format**: `{ "error": "메시지", "code": "ERROR_CODE" }`

---

## 1. Auth (v0.2)

### POST /api/auth/signup
```json
// Request
{ "email": "string", "password": "string", "nickname": "string" }
// Response 201
{ "userId": 1, "token": "jwt...", "nickname": "string" }
// Error 409
{ "error": "이미 등록된 이메일입니다.", "code": "DUPLICATE_EMAIL" }
```

### POST /api/auth/login
```json
// Request
{ "email": "string", "password": "string" }
// Response 200
{ "userId": 1, "token": "jwt...", "nickname": "string" }
// Error 401
{ "error": "이메일 또는 비밀번호가 올바르지 않습니다.", "code": "INVALID_CREDENTIALS" }
```

### POST /api/auth/password/reset/request (v0.2.5)
비밀번호 재설정 토큰 발급. 이메일에 해당 사용자 존재 시 1회용 토큰을 DB에 저장. 이번 Phase 1 에서는 이메일 발송은 없고 서버 로그에 토큰 출력 (개발/테스트용).

```json
// Request
{ "email": "string" }
// Response 200 — 항상 200 (사용자 존재 여부 유출 방지)
{ "message": "이메일이 발송되었습니다." }
```
- 토큰: 32자 랜덤 URL-safe, expires in 30분
- 실제 존재하는 이메일만 DB에 기록, 무관 이메일은 no-op (응답은 동일)

### POST /api/auth/password/reset/confirm (v0.2.5)
토큰 + 새 비밀번호로 실제 변경.

```json
// Request
{ "token": "string", "newPassword": "string" }
// Response 200
{ "message": "비밀번호가 변경되었습니다." }
// Error 400 VALIDATION_ERROR — 비밀번호 길이/형식
// Error 400 PASSWORD_RESET_TOKEN_INVALID — 토큰 없음/만료/이미 사용됨
```
- newPassword bcrypt 해싱 + User.passwordHash 업데이트
- 토큰은 usedAt 설정해 재사용 방지
- 성공 시 기존 JWT 토큰은 여전히 유효 (rotation은 다음 iteration)

### POST /api/auth/refresh (v0.2.3)
현재 유효한 JWT를 새 expiration으로 재발급. Refresh-token rotation은 미적용 (단순 re-sign).

```
Headers: Authorization: Bearer {현재유효한JWT}
Body: 없음
// Response 200 (login 응답과 동일 스키마)
{ "userId": 1, "token": "eyJ...신규토큰", "nickname": "홍길동" }
// Error 401 — 토큰 만료/무효/사용자 삭제 → UNAUTHORIZED
// Error 429 — auth bucket rpm=10 초과
```

---

## 2. Chat

### POST /api/chat
대화 전송 + AI 응답 + 메모리 자동 추출

```json
// Request
{ "message": "오늘 점심 12000원 썼어" }

// Response 200
{
  "reply": "점심 비용 12,000원 기록했어요! 오늘 총 지출은 25,000원이에요.",
  "memoriesExtracted": [
    {
      "id": 42,
      "category": "finance",
      "title": "점심 지출",
      "content": "12,000원 지출",
      "createdAt": "2026-04-15T22:00:00Z"
    }
  ]
}

// Error 400
{ "error": "메시지를 입력해주세요.", "code": "EMPTY_MESSAGE" }
```

### GET /api/chat/history
최근 대화 히스토리.
- `since` 쿼리 없음 → 최근 20건 (오래된 순 반환)
- `?since=2026-04-16T10:00:00Z` (ISO 8601 Instant) → 해당 시각 이후 메시지 오름차순 반환 (증분 동기화용)
- `since` 파싱 실패 → 400 VALIDATION_ERROR

```json
// Response 200
[
  {
    "role": "user",
    "content": "오늘 점심 12000원 썼어",
    "createdAt": "2026-04-15T22:00:00Z"
  },
  {
    "role": "assistant",
    "content": "점심 비용 12,000원 기록했어요!",
    "createdAt": "2026-04-15T22:00:01Z"
  }
]
```

### DELETE /api/chat/{id} (v0.3.1)
채팅 메시지 개별 삭제. 사용자 본인 메시지 + 해당 AI 응답도 함께 삭제 (pair delete).

```json
// Response 204 (No Content)
// Error 404
{ "error": "메시지를 찾을 수 없습니다.", "code": "MESSAGE_NOT_FOUND" }
// Error 403
{ "error": "권한이 없습니다.", "code": "FORBIDDEN" }
```
- user 메시지 삭제 시: 직후 assistant 메시지도 함께 삭제 (pair)
- assistant 메시지 단독 삭제: 해당 메시지만 삭제
- 삭제된 메시지에서 추출된 메모리는 유지 (메모리는 독립 엔티티)

### GET /api/chat/history/search (v0.3)
채팅 히스토리 키워드 검색. 사용자/AI 메시지 모두 대상.

```json
// Query: ?q=점심
// Response 200
[
  {
    "role": "user",
    "content": "오늘 점심 12000원 썼어",
    "createdAt": "2026-04-15T22:00:00Z"
  },
  {
    "role": "assistant",
    "content": "점심 비용 12,000원 기록했어요!",
    "createdAt": "2026-04-15T22:00:01Z"
  }
]
```
- `q` 필수, 빈 문자열 → 400 VALIDATION_ERROR
- content LIKE '%keyword%' (대소문자 무시)
- 최대 50건 반환 (최신순)
- 결과 형식은 GET /api/chat/history와 동일

---

## 3. Memory

### GET /api/memories
전체 메모리 조회 (카테고리 필터 + 페이지네이션 v0.2.2)

**응답 바디 형식은 바뀌지 않음** — 여전히 bare JSON array. 페이지네이션 정보는 HTTP response headers로 전달.

```
// Query:
//   ?category=finance (optional)
//   ?offset=0 (optional, default 0, >= 0)
//   ?limit=20 (optional, default 없음 — offset/limit 둘 다 없으면 전체 반환 — 기존 클라 호환)
//                          limit 지정 시 1~100 범위
//
// Response 200
// Headers:
//   X-Total-Count: 137       // 필터 조건 적용 후 전체 개수
//   X-Offset: 0              // 적용된 offset (페이지네이션 적용 시에만)
//   X-Limit: 20              // 적용된 limit (페이지네이션 적용 시에만)
//   X-Has-More: true         // offset+limit < total 이면 true
// Body: (기존 그대로)
[
  {
    "id": 42,
    "category": "finance",
    "title": "점심 지출",
    "content": "12,000원 지출",
    "createdAt": "2026-04-15T22:00:00Z"
  }
]
```

**호환성 규칙**:
- offset/limit 쿼리 둘 다 없음 → 전체 반환 (기존 클라 무영향), X-Total-Count만 포함 가능
- offset 또는 limit 중 하나라도 있음 → 페이지네이션 활성화, 4개 헤더 전부 포함
- limit > 100 → 400 VALIDATION_ERROR
- offset < 0 → 400 VALIDATION_ERROR

### GET /api/memories/export (v0.3.1)
전체 메모리 JSON 내보내기. 데이터 포터빌리티 용도.

```json
// Response 200
// Content-Type: application/json
// Content-Disposition: attachment; filename="aidy-memories-2026-04-17.json"
{
  "exportedAt": "2026-04-17T14:00:00Z",
  "totalCount": 23,
  "memories": [
    {
      "id": 42,
      "category": "finance",
      "title": "점심 지출",
      "content": "12,000원 지출",
      "createdAt": "2026-04-15T22:00:00Z"
    }
  ]
}
```
- 카테고리 필터 가능: `?category=finance`
- 페이지네이션 없음 (전체 export)
- 파일명: `aidy-memories-{YYYY-MM-DD}.json`

### GET /api/memories/search
키워드 검색

```json
// Query: ?q=점심
// Response 200
[ ...MemoryItem[] ]
```

### PUT /api/memories/{id} (v0.3)
메모리 수정. 사용자가 AI 추출 결과를 교정할 때 사용.

```json
// Request
{
  "title": "수정된 제목",
  "content": "수정된 내용"
}
// Response 200
{
  "id": 42,
  "category": "finance",
  "title": "수정된 제목",
  "content": "수정된 내용",
  "createdAt": "2026-04-15T22:00:00Z"
}
// Error 400 VALIDATION_ERROR — title 또는 content 빈 문자열
// Error 404 MEMORY_NOT_FOUND
// Error 403 FORBIDDEN — 다른 사용자의 메모리
```
- title, content 둘 다 필수 (partial update 미지원, 클라가 기존값 채워서 전송)
- category, createdAt 변경 불가

### DELETE /api/memories/{id}
메모리 삭제

```json
// Response 204 (No Content)
// Error 404
{ "error": "메모리를 찾을 수 없습니다.", "code": "MEMORY_NOT_FOUND" }
// Error 403
{ "error": "권한이 없습니다.", "code": "FORBIDDEN" }
```

### GET /api/memories/categories
카테고리별 메모리 수 요약

```json
// Response 200
{
  "categories": [
    { "name": "finance", "displayName": "금융", "count": 15 },
    { "name": "schedule", "displayName": "일정", "count": 8 }
  ],
  "total": 23
}
```

---

## 4. People (관계 메모리)

### GET /api/memories/people
인물별 기억 조회 (normalizedName 기준 exact match)

```json
// Query: ?person=김팀장
// Auth: Authorization: Bearer {JWT} (v0.2+) 또는 X-User-Id (v0.1)
// Response 200
{
  "person": "김팀장",
  "aliases": ["김 팀장", "팀장님", "팀장"],
  "relationship": "직장 상사",
  "memories": [
    {
      "id": 101,
      "trait": "스타벅스 선호",
      "context": "점심 식사 후 대화에서 언급",
      "date": "2026-04-16",
      "sentiment": "neutral"
    }
  ],
  "totalCount": 1
}

// Error 400
{ "error": "인물 이름을 입력해주세요.", "code": "EMPTY_PERSON" }
// Error 401
{ "error": "인증이 필요합니다.", "code": "UNAUTHORIZED" }
// Error 404
{ "error": "해당 인물의 기억을 찾을 수 없습니다.", "code": "PERSON_NOT_FOUND" }
```

### POST /api/memories/{id}/feedback
기억 정확도 피드백

```json
// Request
{ "isCorrect": false }
// Response 200 (isCorrect=true)
{ "status": "ok" }
// Response 200 (isCorrect=false — 기억 삭제됨)
{ "status": "deleted" }
```

### POST /chat 응답 확장 (people 카테고리)

`memoriesExtracted` 항목이 `category: "people"`일 때 `personDetail` 추가:

```json
{
  "id": 42,
  "category": "people",
  "title": "김 팀장 — 스타벅스 선호",
  "content": "스타벅스 좋아한다고 함",
  "createdAt": "2026-04-16T12:00:00Z",
  "personDetail": {
    "normalizedName": "김팀장",
    "relationship": "직장 상사",
    "trait": "스타벅스 선호",
    "context": "점심 식사 후 대화에서 언급",
    "sentiment": "neutral"
  }
}
```

---

## 5. Health

### GET /api/health
```json
// Response 200
{ "status": "ok", "service": "aidy-server", "version": "0.1.0" }
```

---

## Memory Categories (고정 enum)

| key | displayName | 설명 |
|-----|------------|------|
| schedule | 일정 | 날짜/시간이 있는 이벤트 |
| finance | 금융 | 수입, 지출, 자산 |
| work | 업무 | 회의, 프로젝트, 업무 메모 |
| health | 건강 | 운동, 식단, 컨디션 |
| preference | 취향 | 좋아하는 것, 싫어하는 것 |
| people | 인맥 | 사람 관련 정보 |
| general | 일반 | 분류 불가 |

---

## Error Codes (전체)

모든 에러 응답 형식: `{ "error": "사용자용 메시지 (ko)", "code": "ERROR_CODE" }`

| Code | HTTP | 설명 | Retryable |
|------|------|------|:---------:|
| EMPTY_MESSAGE | 400 | 빈 메시지 | — |
| VALIDATION_ERROR | 400 | 요청 필드 검증 실패 (error 메시지에 구체 원인) | — |
| INVALID_CREDENTIALS | 401 | 로그인 실패 | — |
| UNAUTHORIZED | 401 | 인증 필요 / 토큰 만료 | — |
| FORBIDDEN | 403 | 권한 없음 | — |
| MEMORY_NOT_FOUND | 404 | 메모리 없음 | — |
| MESSAGE_NOT_FOUND | 404 | 메시지 없음 | — |
| PERSON_NOT_FOUND | 404 | 인물 없음 | — |
| EMPTY_PERSON | 400 | 인물 이름 누락 | — |
| DUPLICATE_EMAIL | 409 | 이메일 중복 | — |
| RATE_LIMITED | 429 | 요청 초과 | ✅ |
| INTERNAL_ERROR | 500 | 서버 오류 | — |
| PASSWORD_RESET_TOKEN_INVALID | 400 | 비밀번호 재설정 토큰 무효/만료/사용됨 | — |
| AI_UNAVAILABLE | 503 | AI 서비스 일시 중단 (Circuit Breaker OPEN) | ✅ |
| AI_TIMEOUT | 504 | AI 응답 시간 초과 | ✅ |

**클라이언트 처리 규칙**:
- Retryable 코드(✅): 재시도 버튼 노출 권장 (사용자 재시도 허용)
- 401 UNAUTHORIZED: 자동 로그아웃 + 로그인 화면 이동 (ADR-006)
- 4xx NON_RETRYABLE: 토스트/알림만, 재시도 UI 감춤
- 5xx NON_RETRYABLE (INTERNAL_ERROR): 토스트 + 재시도 버튼은 선택적

---

## 버전 히스토리

| 버전 | 날짜 | 변경 |
|------|------|------|
| v0.1 | 2026-04-15 | 초기 스펙 (Chat + Memory + Health) |
| v0.1.1 | 2026-04-16 | AI_TIMEOUT 에러 코드 추가 (WO-004) |
| v0.2.0 | 2026-04-16 | People 엔드포인트 + 피드백 API + personDetail 확장 (ADR-005) |
| v0.2.1 | 2026-04-16 | AI_UNAVAILABLE + VALIDATION_ERROR 추가, retryable 플래그 문서화 (autoceo-s4-R2/R3) |
| v0.2.2 | 2026-04-16 | GET /api/memories 페이지네이션 (offset/limit) (autoceo-s5-R4) |
| v0.2.3 | 2026-04-16 | POST /api/auth/refresh — JWT 토큰 재발급 (autoceo-s5-R5) |
| v0.2.4 | 2026-04-16 | GET /api/chat/history ?since 파라미터 추가 (autoceo-s6-R4) |
| v0.2.5 | 2026-04-16 | POST /api/auth/password/reset/{request,confirm} (autoceo-s6-R5) |
| v0.3.0 | 2026-04-17 | PUT /api/memories/{id} 메모리 수정 + GET /api/chat/history/search 채팅 검색 (autoceo-s11-R1) |
| v0.3.1 | 2026-04-17 | DELETE /api/chat/{id} 메시지 삭제 + GET /api/memories/export 내보내기 (autoceo-s12-R1) |
