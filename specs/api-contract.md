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

## 1. Auth (v0.2 — 아직 미구현)

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
최근 대화 히스토리 (최신 20건)

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

---

## 3. Memory

### GET /api/memories
전체 메모리 조회 (카테고리 필터 가능)

```json
// Query: ?category=finance (optional)
// Response 200
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

### GET /api/memories/search
키워드 검색

```json
// Query: ?q=점심
// Response 200
[ ...MemoryItem[] ]
```

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

## 4. Health

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

| Code | HTTP | 설명 |
|------|------|------|
| EMPTY_MESSAGE | 400 | 빈 메시지 |
| INVALID_CREDENTIALS | 401 | 로그인 실패 |
| UNAUTHORIZED | 401 | 인증 필요 |
| FORBIDDEN | 403 | 권한 없음 |
| MEMORY_NOT_FOUND | 404 | 메모리 없음 |
| DUPLICATE_EMAIL | 409 | 이메일 중복 |
| RATE_LIMITED | 429 | 요청 초과 |
| AI_TIMEOUT | 504 | AI 응답 시간 초과 |
| INTERNAL_ERROR | 500 | 서버 오류 |

---

## 버전 히스토리

| 버전 | 날짜 | 변경 |
|------|------|------|
| v0.1 | 2026-04-15 | 초기 스펙 (Chat + Memory + Health) |
| v0.1.1 | 2026-04-16 | AI_TIMEOUT 에러 코드 추가 (WO-004) |
