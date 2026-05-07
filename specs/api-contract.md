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

### PATCH /api/auth/profile (v0.4)
프로필 수정. 현재는 닉네임만 지원. 서버 동기화용.

```json
// Request
{ "nickname": "새닉네임" }
// Response 200
{ "userId": 1, "nickname": "새닉네임" }
// Error 400 VALIDATION_ERROR — 닉네임 빈 문자열 또는 20자 초과
```
- nickname 1~20자
- 다른 필드 무시 (forward-compatible)

### PUT /api/auth/password (v0.7)
로그인 상태에서 비���번호 변경. 현재 비밀번호 확인 후 새 비밀번호로 교체.

```json
// Request
{
  "currentPassword": "string",
  "newPassword": "string"
}
// Response 200
{ "message": "비밀번호가 변경되었습니��." }
// Error 400 VALIDATION_ERROR — newPassword 8자 미만
// Error 401 INVALID_CREDENTIALS — currentPassword 불일치
```
- newPassword: 8자 이상
- currentPassword bcrypt 비교
- 성공 후 기존 JWT 유효 (rotation 미적용)

### DELETE /api/auth/account (v0.7)
계정 영구 삭제. 모든 관련 데이터 (채팅, 메모리, 설정 등) 함께 삭제.

```json
// Request
{ "password": "string" }
// Response 204 (No Content)
// Error 401 INVALID_CREDENTIALS — 비밀번호 불일치
```
- 비밀번호 확인 필수 (실수 방지)
- CASCADE 삭제: User → ChatMessage, Memory, PersonMemory, UserSettings, PasswordResetToken
- 삭제 후 JWT 무효화 (user not found)

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

### POST /api/chat/stream (ADR-008, v0.8)
SSE 스트리밍 채팅. POST /api/chat의 스트리밍 버전. 기존 POST /api/chat과 공존.

```
// Request
POST /api/chat/stream
Content-Type: application/json
Authorization: Bearer {JWT}

{ "message": "오늘 점심 12000원 썼어" }

// Response: text/event-stream
event: token
data: {"text": "점심"}

event: token
data: {"text": " 비용"}

event: memory
data: {"category": "finance", "title": "점심 지출", "content": "12,000원 지출"}

event: done
data: {"messageId": 42, "totalTokens": 128}

event: error
data: {"code": "AI_TIMEOUT", "error": "AI 응답 시간 초과"}
```
- `token`: 텍스트 청크 (점진적 표시)
- `memory`: 추출된 메모리 (있으면)
- `done`: 정상 종료
- `error`: 에러 후 스트림 종료
- SseEmitter timeout 30초
- Circuit Breaker OPEN → 즉시 error 이벤트 + close
- chat rpm=20 버킷 공유

### GET /api/chat/history
최근 대화 히스토리.
- `since` 쿼리 없음 + offset/limit 없음 → 최근 20건 (오래된 순 반환)
- `?since=2026-04-16T10:00:00Z` (ISO 8601 Instant) → 해당 시각 이후 메시지 오름차순 반환 (증분 동기화용)
- `since` 파싱 실패 → 400 VALIDATION_ERROR
- `?offset=0&limit=20` (v0.8) → 페이지네이션. offset >= 0, limit 1~100.
- offset/limit 사용 시 since 무시.

```json
// Response 200
// Headers (페이지네이션 사용 시):
//   X-Total-Count: 250
//   X-Offset: 0
//   X-Limit: 20
//   X-Has-More: true
[
  {
    "id": 1,
    "role": "user",
    "content": "오늘 점심 12000원 썼어",
    "createdAt": "2026-04-15T22:00:00Z"
  },
  {
    "id": 2,
    "role": "assistant",
    "content": "점심 비용 12,000원 기록했어요!",
    "createdAt": "2026-04-15T22:00:01Z"
  }
]
```
- 페이지네이션 호환성: 기존 since 방식과 공존. offset/limit 있으면 since 무시.
- `id` 필드 추가 (v0.8): 개별 삭제 시 필요. 기존 클라이언트는 무시 가능.

### GET /api/chat/stats (v0.5)
채팅 통계. 사용자의 대화 활동 요약.

```json
// Response 200
{
  "totalMessages": 128,
  "userMessages": 64,
  "assistantMessages": 64,
  "firstMessageAt": "2026-04-15T10:00:00Z",
  "lastMessageAt": "2026-04-17T14:30:00Z",
  "totalMemoriesExtracted": 23,
  "dailyAverage": 21.3
}
```
- dailyAverage: totalMessages / (활동 일수). 소수점 1자리.
- 메시지 0건이면 모든 숫자 0, 날짜 null.

### GET /api/chat/summary (v0.9)
최근 대화 AI 요약. 최근 24시간 대화를 요약하여 반환.

```json
// Response 200
{
  "period": "2026-04-17",
  "messageCount": 12,
  "summary": "오늘은 점심 지출 기록, 팀 미팅 일정 확인, 운동 계획을 대화했어요.",
  "topics": ["금융", "일정", "건강"],
  "memoriesCreated": 3
}
```
- 최근 24시간 대화 기준
- 대화 없으면: summary="대화 내역이 없습니다.", topics=[], memoriesCreated=0
- AI를 호출하여 요약 생성 (비용 고려: 캐시 1시간)
- Circuit Breaker OPEN 시 503 AI_UNAVAILABLE

### GET /api/chat/quickactions (v1.0)
퀵 액션 목록. 자주 쓰는 프롬프트를 카테고리별로 반환.

```json
// Response 200
{
  "actions": [
    { "id": "daily_expense", "emoji": "💰", "label": "오늘 지출 기록", "prompt": "오늘 지출을 기록할게요" },
    { "id": "schedule_check", "emoji": "📅", "label": "일정 확인", "prompt": "이번 주 일정 알려줘" },
    { "id": "mood_log", "emoji": "😊", "label": "기분 기록", "prompt": "오늘 기분을 기록할게요" },
    { "id": "work_memo", "emoji": "📝", "label": "업무 메모", "prompt": "업무 메모를 남길게요" },
    { "id": "health_log", "emoji": "🏃", "label": "운동 기록", "prompt": "오늘 운동을 기록할게요" },
    { "id": "people_note", "emoji": "👤", "label": "인물 메모", "prompt": "사람에 대해 기록할게요" }
  ]
}
```
- 서버에서 고정 목록 반환 (v1.0은 하드코딩, 추후 사용자 커스텀)
- 클라이언트: 채팅 입력 위에 가로 스크롤 퀵 버튼
- 탭 시 prompt 텍스트를 채팅 입력에 자동 채움 + 전송

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

### GET /api/chat/history/grouped (v1.3)
날짜별 채팅 그룹핑. 대화를 날짜 기준으로 그룹핑하여 반환.

```json
// Query: ?days=7 (optional, default 7, max 30)
// Response 200
{
  "days": 7,
  "groups": [
    {
      "date": "2026-04-19",
      "messageCount": 12,
      "firstMessage": "오늘 점심 뭐 먹지",
      "lastMessage": "운동 기록 남길게",
      "topics": ["금융", "건강"],
      "memoriesCreated": 3
    },
    {
      "date": "2026-04-18",
      "messageCount": 8,
      "firstMessage": "팀 미팅 언제야",
      "lastMessage": "내일 일정 알려줘",
      "topics": ["일정", "업무"],
      "memoriesCreated": 2
    }
  ],
  "totalMessages": 20,
  "totalDays": 2
}
```
- 최신 날짜 먼저 (내림차순)
- 대화 없는 날짜는 생략
- topics: 해당 날짜에 생성된 메모리의 카테고리 unique 목록
- firstMessage/lastMessage: 해당 날짜 첫/마지막 user 메시지 content (50자 초과 시 truncate + "...")
- days=0 또는 음수 → 400 VALIDATION_ERROR

### GET /api/user/dashboard (v1.3)
종합 사용 통계 대시보드. 채팅, 메모리, 인물 통계 통합.

```json
// Response 200
{
  "chat": {
    "totalMessages": 128,
    "todayMessages": 12,
    "weeklyMessages": 45,
    "dailyAverage": 21.3
  },
  "memory": {
    "totalMemories": 47,
    "pinnedCount": 5,
    "todayCreated": 3,
    "topCategory": "finance",
    "streakDays": 7
  },
  "people": {
    "totalPeople": 8,
    "totalTraits": 23,
    "mostMentioned": "김팀장"
  },
  "activity": {
    "memberSince": "2026-04-15T10:00:00Z",
    "totalActiveDays": 5,
    "lastActiveAt": "2026-04-19T14:00:00Z"
  }
}
```
- todayMessages/todayCreated: UTC 기준 오늘
- weeklyMessages: 최근 7일
- mostMentioned: PersonMemory count 최대 인물 (없으면 null)
- memberSince: 첫 메시지 시각 (메시지 없으면 계정 생성일)
- totalActiveDays: 1건 이상 메시지가 있는 고유 날짜 수

### POST /api/chat/{id}/bookmark (v1.4)
채팅 메시지 북마크 토글. 이미 북마크된 경우 해제, 없으면 추가.

```json
// Response 200 (북마크 추가)
{ "bookmarked": true, "bookmarkedAt": "2026-04-19T12:00:00Z" }
// Response 200 (북마크 해제)
{ "bookmarked": false }
// Error 404
{ "error": "메시지를 찾을 수 없습니다.", "code": "MESSAGE_NOT_FOUND" }
// Error 403
{ "error": "권한이 없습니다.", "code": "FORBIDDEN" }
```
- 토글 방식: 한 엔드포인트로 추가/해제 모두 처리
- user/assistant 메시지 모두 북마크 가능
- 삭제된 메시지의 북마크는 cascade 삭제

### GET /api/chat/bookmarks (v1.4)
북마크된 메시지 목록 조회. 최신 북마크순.

```json
// Query: ?offset=0&limit=20 (optional)
// Response 200
{
  "bookmarks": [
    {
      "id": 42,
      "role": "assistant",
      "content": "오늘 하루도 수고하셨어요!",
      "createdAt": "2026-04-19T10:00:00Z",
      "bookmarkedAt": "2026-04-19T12:00:00Z"
    }
  ],
  "total": 5,
  "offset": 0,
  "limit": 20
}
```
- 페이지네이션: offset/limit (기본 limit=20)
- 정렬: bookmarkedAt DESC

### POST /api/chat/{id}/feedback (v1.4)
AI 응답에 대한 피드백. assistant 메시지에만 허용.

```json
// Request
{ "rating": "good" }  // "good" | "bad"
// Response 200
{ "id": 42, "rating": "good", "createdAt": "2026-04-19T12:00:00Z" }
// Error 400
{ "error": "AI 응답에만 피드백할 수 있습니다.", "code": "VALIDATION_ERROR" }
// Error 404
{ "error": "메시지를 찾을 수 없습니다.", "code": "MESSAGE_NOT_FOUND" }
```
- rating: "good" | "bad" (enum, 필수)
- assistant role 메시지만 피드백 가능
- 동일 메시지에 재피드백 시 덮어쓰기 (upsert)
- 추후 AI 품질 개선 데이터로 활용

### GET /api/chat/topics (v1.5)
대화 주제 자동 요약. AI가 최근 대화를 분석해 주제별로 클러스터링.

```json
// Query: ?days=7 (optional, default 7, max 30)
// Response 200
{
  "days": 7,
  "topics": [
    {
      "title": "업무 프로젝트 진행",
      "messageCount": 15,
      "firstMessageAt": "2026-04-15T09:00:00Z",
      "lastMessageAt": "2026-04-19T14:00:00Z",
      "keywords": ["프로젝트", "회의", "마감"],
      "sampleMessageId": 42
    }
  ],
  "totalMessages": 50
}
```
- AI 기반 주제 추출 (서버 사이드 처리)
- keywords: 주제를 대표하는 키워드 3개 이하
- sampleMessageId: 해당 주제의 대표 메시지 ID (클라이언트에서 해당 위치로 스크롤 가능)
- 캐싱 권장: 같은 days 파라미터로 1시간 이내 재요청 시 캐시 반환

### GET /api/chat/export (v1.5)
대화 이력 텍스트 내보내기. 날짜 범위 지정 가능.

```json
// Query: ?format=text&days=30 (optional)
//   format: "text" | "json" (default "text")
//   days: 최근 N일 (default 30, max 365)
// Response 200 (format=text)
// Content-Type: text/plain; charset=utf-8
// Content-Disposition: attachment; filename="aidy-chat-export-2026-04-19.txt"
//
// [2026-04-19 10:00] 나: 오늘 점심 뭐 먹었어
// [2026-04-19 10:00] Aidy: 점심 기록을 도와드릴게요! 뭘 드셨나요?

// Response 200 (format=json)
// Content-Type: application/json
{
  "exportedAt": "2026-04-19T12:00:00Z",
  "days": 30,
  "messageCount": 128,
  "messages": [
    {
      "role": "user",
      "content": "오늘 점심 뭐 먹었어",
      "createdAt": "2026-04-19T10:00:00Z"
    }
  ]
}
```
- text 포맷: 읽기 편한 타임스탬프 + role + content
- json 포맷: 프로그래밍 친화적, 메시지 배열
- 메시지 없으면 빈 텍스트/빈 배열 반환 (에러 아님)

### DELETE /api/chat/history (v0.8)
전체 대화 삭제. 사용자의 모든 채팅 메시지 삭제.

```json
// Response 200
{ "deleted": 128 }
// Error 401 UNAUTHORIZED
```
- 메모리는 유지 (독립 엔티티)
- 확인 절차는 클라이언트에서 처리 (서버는 단순 실행)

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

### POST /api/memories/batch (v0.5)
메모리 일괄 작업. 다중 선택 후 일괄 삭제 또는 일괄 핀 설정.

```json
// Request
{
  "action": "delete",       // "delete" | "pin" | "unpin"
  "memoryIds": [42, 43, 44]
}
// Response 200 (action: delete)
{ "affected": 3 }
// Response 200 (action: pin/unpin)
{ "affected": 3 }
// Error 400 VALIDATION_ERROR — action 미지원 또는 memoryIds 빈 배열
```
- memoryIds 최대 50개 (초과 시 400 VALIDATION_ERROR)
- 본인 소유 메모리만 처리, 타인 메모리는 무시 (에러 없이 skip)
- delete: 해당 메모리 삭제
- pin/unpin: pinned 필드 일괄 변경

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

### POST /api/memories/import (v0.9)
메모리 JSON 가져오기. export 포맷과 동일한 구조. 중복(동일 title+content+category) 건너뜀.

```json
// Request
{
  "memories": [
    {
      "category": "finance",
      "title": "점심 지출",
      "content": "12,000원 지출"
    }
  ]
}
// Response 200
{
  "imported": 20,
  "skipped": 3,
  "total": 23
}
// Error 400 VALIDATION_ERROR — memories 빈 배열 또는 category enum 미일치
```
- `id`, `createdAt` 필드는 무시 (서버에서 새로 생성)
- 중복 판정: 동일 userId + title + content + category → skip
- 최대 200건 (초과 시 400 VALIDATION_ERROR)
- `pinned` 필드 있으면 반영, 없으면 false

### POST /api/memories/{id}/share (v1.0)
메모리 공유 링크 생성. 24시간 유효한 공유 토큰 발급.

```json
// Response 200
{
  "shareToken": "abc123def456",
  "expiresAt": "2026-04-19T01:00:00Z",
  "shareUrl": "/api/shared/abc123def456"
}
// Error 404 MEMORY_NOT_FOUND
// Error 403 FORBIDDEN
```

### GET /api/shared/{token} (v1.0)
공유 토큰으로 메모리 조회. 인증 불필요 (공개 접근).

```json
// Response 200
{
  "category": "finance",
  "title": "점심 지출",
  "content": "12,000원 지출",
  "sharedBy": "홍길동",
  "createdAt": "2026-04-18T12:00:00Z"
}
// Error 404 — 토큰 만료/미존재
{ "error": "공유 링크가 만료되었습니다.", "code": "SHARE_NOT_FOUND" }
```
- 토큰: 32자 URL-safe 랜덤
- 유효기간: 24시간
- 만료 후 자동 무효 (DB에서 삭제 불필요, 조회 시 체크)
- 공유된 메모리에 userId 등 민감 정보 미포함

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
  "content": "수정된 내용",
  "category": "work"          // 선택 — 미포함 시 기존 유지
}
// Response 200
{
  "id": 42,
  "category": "work",
  "title": "수정된 제목",
  "content": "수정된 내용",
  "pinned": false,
  "createdAt": "2026-04-15T22:00:00Z"
}
// Error 400 VALIDATION_ERROR — title/content 빈 문자열 또는 category enum 미일치
// Error 404 MEMORY_NOT_FOUND
// Error 403 FORBIDDEN — 다른 사용자의 메모리
```
- title, content 필수. category 선택 (미포함 시 기존 유지).
- createdAt 변경 불가
- category 변경 시 Memory Categories enum 값만 허용, 그 외 → 400 VALIDATION_ERROR

### POST /api/memories/{id}/pin (v0.4)
메모리 핀/언핀 토글.

```json
// Request
{ "pinned": true }
// Response 200
{
  "id": 42,
  "category": "finance",
  "title": "점심 지출",
  "content": "12,000원 지출",
  "pinned": true,
  "createdAt": "2026-04-15T22:00:00Z"
}
// Error 404 MEMORY_NOT_FOUND
// Error 403 FORBIDDEN
```
- `pinned: true` → 핀, `pinned: false` → 언핀
- GET /api/memories 응답에 `pinned` 필드 추가 (boolean, default false)
- GET /api/memories?pinned=true → 핀된 메모리만 필터
- 핀된 메모리는 리스트 상단 고정 (클라이언트 정렬)

### PATCH /api/memories/{id}/tags (v1.0)
메모리에 커스텀 태그 추가/수정.

```json
// Request
{ "tags": ["중요", "회의", "Q2"] }
// Response 200
{
  "id": 42,
  "category": "work",
  "title": "팀 미팅",
  "content": "...",
  "tags": ["중요", "회의", "Q2"],
  "pinned": false,
  "createdAt": "2026-04-18T12:00:00Z"
}
// Error 400 VALIDATION_ERROR — 태그 10개 초과 또는 태그 길이 20자 초과
// Error 404 MEMORY_NOT_FOUND
```
- 태그 최대 10개, 각 태그 1~20자
- 빈 배열 전송 시 모든 태그 삭제
- GET /api/memories 응답에 tags 필드 추가 (배열, default [])
- GET /api/memories?tag=중요 → 해당 태그 가진 메모리 필터

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

### GET /api/memories/people/list (v1.2)
전체 인물 목록. 사용자가 대화에서 언급한 모든 인물과 메모리 수.

```json
// Response 200
{
  "people": [
    {
      "id": 1,
      "normalizedName": "김팀장",
      "displayName": "김 팀장",
      "relationship": "직장 상사",
      "memoryCount": 5,
      "latestTrait": "스타벅스 선호",
      "lastMentionedAt": "2026-04-18T14:00:00Z"
    }
  ],
  "totalCount": 3
}
```
- 최근 언급순 정렬 (lastMentionedAt 내림차순)
- memoryCount: 해당 인물의 PersonMemory 수
- latestTrait: 가장 최근 PersonMemory의 trait
- lastMentionedAt: 가장 최근 PersonMemory의 createdAt

### POST /api/memories/people/merge (v1.2)
인물 병합. source 인물의 모든 메모리를 target으로 이동 후 source 삭제.

```json
// Request
{
  "sourcePersonId": 2,
  "targetPersonId": 1
}
// Response 200
{
  "mergedCount": 3,
  "target": {
    "id": 1,
    "normalizedName": "김팀장",
    "displayName": "김 팀장",
    "relationship": "직장 상사",
    "memoryCount": 8
  }
}
// Error 400 VALIDATION_ERROR — sourcePersonId == targetPersonId
// Error 404 PERSON_NOT_FOUND — source 또는 target 미존재
// Error 403 FORBIDDEN — 다른 사용자의 인물
```
- source의 PersonMemory.person → target으로 변경
- source Person 삭제
- target의 displayName/relationship은 유지
- 동일 trait 중복 시 source 쪽 PersonMemory 삭제

### PATCH /api/memories/people/{id} (v1.2)
인물 정보 수정. relationship, displayName 변경.

```json
// Request
{
  "relationship": "친한 친구",
  "displayName": "김철수 팀장"
}
// Response 200
{
  "id": 1,
  "normalizedName": "김팀장",
  "displayName": "김철수 팀장",
  "relationship": "친한 친구",
  "memoryCount": 8
}
// Error 404 PERSON_NOT_FOUND
// Error 403 FORBIDDEN
// Error 400 VALIDATION_ERROR — relationship/displayName 빈 문자열
```
- relationship, displayName 중 하나만 전달해도 됨 (partial update)
- normalizedName은 변경 불가

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

## 5. Search

### GET /api/search (v0.6)
통합 검색. 채팅, 메모리, 인물을 동시에 검색하여 타입별 그룹으로 반환.

```json
// Query: ?q=점심
// Response 200
{
  "query": "점심",
  "results": {
    "chat": [
      { "role": "user", "content": "오늘 점심 12000원 썼어", "createdAt": "2026-04-15T22:00:00Z" }
    ],
    "memories": [
      { "id": 42, "category": "finance", "title": "점심 지출", "content": "12,000원 지출", "pinned": false, "createdAt": "2026-04-15T22:00:00Z" }
    ],
    "people": [
      { "normalizedName": "김팀장", "relationship": "직장 상사", "latestTrait": "스타벅스 선호", "memoryCount": 3 }
    ]
  },
  "counts": { "chat": 1, "memories": 1, "people": 1, "total": 3 }
}
```
- `q` 필수, 빈 문자열 → 400 VALIDATION_ERROR
- 각 타입 최대 10건 (최신순)
- 채팅: content LIKE, 메모리: title+content LIKE, 인물: normalizedName+trait LIKE
- case-insensitive

---

## 5.4 Reminders (v1.0)

### GET /api/reminders
일정/알림 목록. schedule 카테고리 메모리 중 날짜가 오늘 이후인 항목.

```json
// Response 200
{
  "reminders": [
    {
      "memoryId": 55,
      "title": "팀 미팅",
      "content": "4/20 오후 2시 회의실 A",
      "date": "2026-04-20",
      "daysUntil": 2,
      "pinned": true
    }
  ],
  "todayCount": 1,
  "upcomingCount": 3
}
```
- schedule 카테고리 + content에서 날짜 추출 (YYYY-MM-DD 패턴)
- 날짜 추출 실패한 메모리는 제외
- 가까운 날짜 먼저 정렬
- daysUntil: 0=오늘, 1=내일, ...
- 지난 날짜는 제외

### POST /api/reminders/{memoryId}/dismiss (v1.0)
알림 해제 (다시 표시 안 함).

```json
// Response 204
// Error 404 MEMORY_NOT_FOUND
```
- 내부적으로 메모리에 dismissed 플래그 설정
- dismissed된 메모리는 GET /api/reminders에서 제외

---

## 5.5 Memory Timeline (v1.0)

### GET /api/memories/timeline
날짜별 메모리 타임라인. 메모리를 날짜 기준으로 그룹핑하여 반환.

```json
// Query: ?days=7 (optional, default 7, max 30)
// Response 200
{
  "days": 7,
  "timeline": [
    {
      "date": "2026-04-18",
      "count": 5,
      "memories": [
        { "id": 50, "category": "finance", "title": "점심 지출", "content": "12,000원", "pinned": false, "createdAt": "2026-04-18T12:00:00Z" }
      ]
    },
    {
      "date": "2026-04-17",
      "count": 3,
      "memories": [...]
    }
  ],
  "totalCount": 8
}
```
- 최신 날짜 먼저 (내림차순)
- 각 날짜 내 메모리는 최신순
- 메모리 없는 날짜는 생략
- days=0 또는 음수 → 400 VALIDATION_ERROR

---

## 5.6 Memory Insights (v0.8)

### GET /api/memories/insights
메모리 활동 인사이트. 카테고리별 분포 + 최근 7일 활동 추이.

```json
// Response 200
{
  "totalMemories": 47,
  "pinnedCount": 5,
  "categoryDistribution": [
    { "category": "finance", "displayName": "금융", "count": 15, "percentage": 31.9 },
    { "category": "schedule", "displayName": "일정", "count": 12, "percentage": 25.5 },
    { "category": "work", "displayName": "업무", "count": 8, "percentage": 17.0 },
    { "category": "people", "displayName": "인맥", "count": 5, "percentage": 10.6 },
    { "category": "health", "displayName": "건강", "count": 4, "percentage": 8.5 },
    { "category": "preference", "displayName": "취향", "count": 2, "percentage": 4.3 },
    { "category": "general", "displayName": "일반", "count": 1, "percentage": 2.1 }
  ],
  "weeklyActivity": [
    { "date": "2026-04-11", "count": 3 },
    { "date": "2026-04-12", "count": 7 },
    { "date": "2026-04-13", "count": 5 },
    { "date": "2026-04-14", "count": 2 },
    { "date": "2026-04-15", "count": 8 },
    { "date": "2026-04-16", "count": 12 },
    { "date": "2026-04-17", "count": 10 }
  ],
  "streakDays": 7,
  "mostActiveCategory": "finance"
}
```
- `categoryDistribution`: count 내림차순 정렬, percentage 소수점 1자리
- `weeklyActivity`: 최근 7일 (오늘 포함), 메모리 생성 수
- `streakDays`: 연속 메모리 생성일 (오늘부터 역산)
- `mostActiveCategory`: count 최대 카테고리 (동률 시 첫 번째)
- 메모리 0건이면: totalMemories=0, 빈 배열들, streakDays=0, mostActiveCategory=null

---

## 5.7 Memory Smart Review (v1.6)

### GET /api/memories/review-suggestions
오래되거나 변경 가능성이 높은 메모리를 리뷰 대상으로 추천. AI가 메모리 내용과 나이를 분석하여 리뷰 우선순위를 결정.

```json
// Query: ?limit=5 (optional, default 5, max 20)
// Response 200
{
  "suggestions": [
    {
      "memoryId": 15,
      "category": "work",
      "title": "프로젝트 마감일 4월 30일",
      "content": "이번 분기 마감일이 4월 30일이다",
      "createdAt": "2026-01-15T10:00:00Z",
      "daysSinceCreated": 94,
      "reason": "3개월 전 기록된 업무 메모리입니다. 마감일이 지났을 수 있습니다.",
      "priority": "high"
    },
    {
      "memoryId": 22,
      "category": "health",
      "title": "주 3회 운동 목표",
      "content": "주 3회 헬스장 가기로 함",
      "createdAt": "2026-02-10T08:00:00Z",
      "daysSinceCreated": 68,
      "reason": "2개월 전 건강 목표입니다. 아직 유효한지 확인해보세요.",
      "priority": "medium"
    }
  ],
  "totalReviewable": 12
}
```
- priority: "high" | "medium" | "low" (AI 결정)
- reason: 리뷰를 추천하는 이유 (한국어, 1~2문장)
- 기준: 30일 이상 된 메모리 중 일정/업무/건강 카테고리 우선
- dismissed된 메모리와 핀 고정된 메모리는 제외
- AI가 내용을 분석해 시간에 민감한 정보(날짜, 목표, 약속)를 우선 추천

### POST /api/memories/{id}/review (v1.6)
메모리 리뷰 결과 기록. 유효/수정/삭제 중 택일.

```json
// Request
{ "action": "confirm" }  // "confirm" | "update" | "delete"
// Response 200 (confirm — 메모리 유지, reviewedAt 갱신)
{ "memoryId": 15, "action": "confirm", "reviewedAt": "2026-04-19T12:00:00Z" }
// Response 200 (delete — 메모리 삭제됨)
{ "memoryId": 15, "action": "delete", "deleted": true }
// Error 404 MEMORY_NOT_FOUND
```
- confirm: 메모리의 reviewedAt 필드를 현재 시간으로 갱신 (다음 리뷰 대상에서 제외)
- update: reviewedAt 갱신 (내용 수정은 PUT /api/memories/{id}로 별도)
- delete: 메모리 삭제

---

## 5.8 Chat Sentiment (v1.7)

### GET /api/chat/sentiment (v1.7)
대화 감정 분석. AI가 최근 대화를 분석해 감정 추이와 주요 감정 패턴을 반환.

```json
// Query: ?days=7 (optional, default 7, max 30)
// Response 200
{
  "days": 7,
  "overall": "positive",
  "score": 0.72,
  "daily": [
    {
      "date": "2026-04-19",
      "sentiment": "positive",
      "score": 0.85,
      "messageCount": 12,
      "dominantEmotion": "joy"
    },
    {
      "date": "2026-04-18",
      "sentiment": "neutral",
      "score": 0.52,
      "messageCount": 8,
      "dominantEmotion": "calm"
    }
  ],
  "emotions": [
    { "emotion": "joy", "count": 15, "percentage": 37.5 },
    { "emotion": "calm", "count": 10, "percentage": 25.0 },
    { "emotion": "stress", "count": 8, "percentage": 20.0 },
    { "emotion": "sadness", "count": 4, "percentage": 10.0 },
    { "emotion": "anger", "count": 3, "percentage": 7.5 }
  ],
  "totalMessages": 40
}
```
- overall: "positive" | "neutral" | "negative" (AI 분석)
- score: 0.0 (매우 부정) ~ 1.0 (매우 긍정)
- daily: 날짜별 감정 추이 (최신순)
- emotions: 감정 분포 (count 내림차순). 5대 감정: joy, calm, stress, sadness, anger
- dominantEmotion: 해당 날짜의 가장 빈번한 감정
- 캐싱 권장: 같은 days 파라미터로 1시간 이내 재요청 시 캐시 반환
- 메시지 없으면: overall="neutral", score=0.5, 빈 배열들

---

## 5.9 Weekly Summary (v1.8)

### GET /api/summary/weekly (v1.8)
주간 종합 리포트. 대화, 메모리, 감정 데이터를 AI가 분석하여 한 주 요약을 생성.

```json
// Query: ?weekOffset=0 (optional, default 0 = 이번 주, 1 = 지난주, max 4)
// Response 200
{
  "weekStart": "2026-04-13",
  "weekEnd": "2026-04-19",
  "highlights": [
    "프로젝트 마감일 관련 대화가 많았습니다",
    "운동 목표를 3회 달성했습니다",
    "새로운 취미 활동에 대해 이야기했습니다"
  ],
  "stats": {
    "totalChats": 24,
    "totalMessages": 156,
    "memoriesCreated": 8,
    "memoriesUpdated": 3,
    "topCategories": ["work", "health", "hobby"]
  },
  "sentiment": {
    "overall": "positive",
    "score": 0.68,
    "trend": "improving",
    "dominantEmotion": "joy"
  },
  "topTopics": [
    { "topic": "프로젝트 진행", "count": 8 },
    { "topic": "운동/건강", "count": 5 },
    { "topic": "취미 활동", "count": 3 }
  ],
  "advice": "이번 주는 업무 관련 대화가 많았어요. 주말에는 취미 시간을 더 가져보는 건 어떨까요?"
}
```
- highlights: AI가 생성한 주간 하이라이트 (최대 5개, 한국어)
- stats: 정량 통계 (DB 쿼리 기반)
- sentiment: 주간 감정 요약 (v1.7 sentiment 데이터 재활용)
- trend: "improving" | "stable" | "declining" (전주 대비)
- topTopics: 주요 대화 주제 (topics 데이터 활용, count 내림차순, 최대 5개)
- advice: AI가 생성한 한 줄 조언 (선택적, 빈 문자열 가능)
- 캐싱 권장: 같은 weekOffset으로 6시간 이내 재요청 시 캐시 반환
- 데이터 없으면: highlights 빈 배열, stats 모두 0, sentiment neutral

---

## 5.10 Memory Connections (v1.9)

### GET /api/memories/{id}/connections (v1.9)
특정 메모리와 관련된 다른 메모리 목록. AI가 내용 유사도를 분석하여 연결.

```json
// Query: ?limit=5 (optional, default 5, max 10)
// Response 200
{
  "memoryId": 15,
  "connections": [
    {
      "memoryId": 22,
      "title": "주 3회 운동 목표",
      "category": "health",
      "relevance": 0.85,
      "reason": "같은 건강 목표 관련 메모리입니다"
    },
    {
      "memoryId": 31,
      "title": "헬스장 등록",
      "category": "health",
      "relevance": 0.72,
      "reason": "운동 습관과 관련된 메모리입니다"
    }
  ],
  "totalConnections": 4
}
```
- relevance: 0.0 ~ 1.0 (AI 유사도 점수)
- reason: 연결 이유 (한국어, 1문장)
- 같은 카테고리 + 키워드 유사도 기반
- 자기 자신 제외, dismissed/삭제 메모리 제외

### POST /api/memories/{id}/connections (v1.9)
수동으로 메모리 연결 추가.

```json
// Request
{ "targetMemoryId": 22 }
// Response 201
{
  "sourceMemoryId": 15,
  "targetMemoryId": 22,
  "type": "manual",
  "createdAt": "2026-04-19T12:00:00Z"
}
// Error 404 MEMORY_NOT_FOUND
// Error 409 CONNECTION_EXISTS
```
- type: "auto" (AI 생성) | "manual" (사용자 생성)
- 양방향: A→B 연결 시 B→A도 자동 생성

### DELETE /api/memories/{id}/connections/{targetId} (v1.9)
메모리 연결 삭제.

```json
// Response 204 No Content
// Error 404 CONNECTION_NOT_FOUND
```

---

## 5.11 Relationship Health Score (v2.0)

### GET /api/people/{personId}/health (v2.0)
인물별 관계 건강 점수. AI가 감정 추이, 상호작용 빈도, 메모리 다양성을 분석하여 관계 건강도를 산출.

```json
// Response 200
{
  "personId": 1,
  "personName": "김팀장",
  "healthScore": 78,
  "grade": "good",
  "factors": {
    "interactionFrequency": {
      "score": 85,
      "label": "활발",
      "detail": "최근 30일간 12회 언급"
    },
    "sentimentTrend": {
      "score": 72,
      "label": "긍정적",
      "detail": "최근 감정 추이 상승"
    },
    "memoryDiversity": {
      "score": 68,
      "label": "보통",
      "detail": "3개 카테고리에 걸쳐 기억"
    },
    "recency": {
      "score": 90,
      "label": "최근",
      "detail": "2일 전 마지막 언급"
    }
  },
  "suggestion": "김팀장과 업무 외 관심사에 대해서도 대화해 보세요.",
  "trend": "improving",
  "calculatedAt": "2026-04-19T10:00:00Z"
}
// Error 404 PERSON_NOT_FOUND
// Error 403 FORBIDDEN
```
- healthScore: 0~100 (AI 종합 점수)
- grade: "excellent" (90+) | "good" (70-89) | "fair" (50-69) | "needs_attention" (0-49)
- factors: 4가지 요인별 세부 점수 (각 0~100)
  - interactionFrequency: 최근 30일 언급 빈도
  - sentimentTrend: 감정 추이 방향 (해당 인물 관련 대화)
  - memoryDiversity: 기억 카테고리 다양성
  - recency: 최근 언급 시점
- suggestion: AI 생성 관계 개선 제안 (한국어, 1문장)
- trend: "improving" | "stable" | "declining" (30일 기준 변화)
- 캐싱: 6시간 TTL (Weekly Summary와 동일)
- PersonMemory 0건이면: healthScore=0, grade="needs_attention", 빈 factors, suggestion="아직 기억이 없습니다"

### GET /api/people/health/summary (v2.0)
전체 인물 관계 건강 요약. 대시보드용.

```json
// Response 200
{
  "totalPeople": 8,
  "averageHealth": 65,
  "distribution": {
    "excellent": 1,
    "good": 3,
    "fair": 2,
    "needs_attention": 2
  },
  "topHealthy": [
    { "personId": 1, "name": "김팀장", "healthScore": 92, "grade": "excellent" }
  ],
  "needsAttention": [
    { "personId": 5, "name": "이과장", "healthScore": 35, "grade": "needs_attention", "lastMentionedAt": "2026-03-15T08:00:00Z" }
  ],
  "calculatedAt": "2026-04-19T10:00:00Z"
}
```
- topHealthy: 상위 3명 (healthScore 내림차순)
- needsAttention: 하위 3명 (healthScore 오름차순)
- 인물 0명이면: totalPeople=0, averageHealth=0, 빈 배열들
- 캐싱: 6시간 TTL

---

## 5.12 Daily Digest (v2.1)

### GET /api/digest/today (v2.1)
오늘의 브리핑. AI가 최근 대화, 메모리, 인물 정보를 종합하여 일일 요약을 생성.

```json
// Response 200
{
  "date": "2026-04-19",
  "greeting": "좋은 아침이에요! 오늘도 의미 있는 하루 되세요.",
  "reminders": [
    {
      "type": "person_checkin",
      "title": "이과장님에게 연락할 때",
      "detail": "3주째 연락이 없습니다. 안부를 물어보는 건 어떨까요?",
      "personId": 5,
      "personName": "이과장"
    },
    {
      "type": "memory_followup",
      "title": "운동 목표 체크",
      "detail": "주 3회 운동 목표를 세웠는데, 이번 주 진행 상황을 확인해 보세요.",
      "memoryId": 22
    }
  ],
  "highlights": [
    {
      "type": "sentiment_change",
      "title": "긍정적 대화 추세",
      "detail": "이번 주 대화가 지난주보다 긍정적이에요. 좋은 흐름이네요!"
    },
    {
      "type": "new_memories",
      "title": "어제 새로운 기억 3개",
      "detail": "김팀장 커피 취향, 주말 계획, 프로젝트 마감일을 기억했어요."
    }
  ],
  "stats": {
    "totalMemories": 45,
    "thisWeekMessages": 28,
    "activePeople": 5,
    "streakDays": 7
  },
  "generatedAt": "2026-04-19T06:00:00Z"
}
```
- greeting: AI 생성 인사 (시간대/요일 반영)
- reminders: 오늘 체크인할 항목 (최대 5개)
  - type: "person_checkin" | "memory_followup" | "upcoming_event"
  - personId/memoryId: 관련 엔티티 (optional)
- highlights: 주요 인사이트 (최대 3개)
  - type: "sentiment_change" | "new_memories" | "milestone" | "pattern"
- stats: 간단한 통계
  - streakDays: 연속 대화 일수
  - activePeople: 최근 7일간 언급된 인물 수
- 캐싱: 24시간 TTL (당일 재요청 시 캐시)
- 데이터 없으면: greeting만 있고 reminders/highlights 빈 배열

---

## 5.13 Conversation Starters (v2.2)

### GET /api/people/{personId}/conversation-starters (v2.2)
특정 인물과의 대화 주제 추천. AI가 메모리/최근 대화/관심사를 분석하여 자연스러운 대화 시작 포인트를 제안.

```json
// Response 200
{
  "personId": 5,
  "personName": "김팀장",
  "starters": [
    {
      "id": "starter-1",
      "category": "recent_memory",
      "topic": "지난주 제주도 여행",
      "suggestion": "제주도 여행 어떠셨어요? 맛집 추천받고 싶어요!",
      "context": "4일 전 제주도 여행 계획을 언급함",
      "memoryId": 42,
      "confidence": 0.92
    },
    {
      "id": "starter-2",
      "category": "shared_interest",
      "topic": "커피",
      "suggestion": "요즘 새로 생긴 카페 가보셨어요? 핸드드립이 맛있다더라고요.",
      "context": "둘 다 커피를 좋아함 (3건의 관련 메모리)",
      "confidence": 0.85
    },
    {
      "id": "starter-3",
      "category": "follow_up",
      "topic": "프로젝트 마감",
      "suggestion": "프로젝트 마감 잘 끝났어요? 고생 많으셨겠다.",
      "context": "2주 전 프로젝트 마감 스트레스 언급",
      "memoryId": 38,
      "confidence": 0.78
    }
  ],
  "generatedAt": "2026-04-19T10:00:00Z"
}
```
- starters: 최대 5개, confidence 내림차순 정렬
- category: "recent_memory" | "shared_interest" | "follow_up" | "seasonal" | "general"
  - recent_memory: 최근 메모리 기반
  - shared_interest: 공통 관심사 기반
  - follow_up: 이전 대화 후속
  - seasonal: 계절/시기 기반 (명절, 연말 등)
  - general: 범용 주제
- confidence: 0.0~1.0, AI가 판단한 대화 적절도
- memoryId: 관련 메모리 (optional)
- 캐싱: 6시간 TTL
- 해당 인물 메모리 0건이면: general 카테고리 2개만 반환
- Error 404 PERSON_NOT_FOUND

---

## 5.14 Anniversary Reminders (v2.3)

### GET /api/anniversaries (v2.3)
등록된 기념일 목록 조회. 다가오는 순으로 정렬.

```json
// Query: ?upcoming=true&days=30
// Response 200
{
  "anniversaries": [
    {
      "id": 1,
      "personId": 5,
      "personName": "김팀장",
      "title": "생일",
      "date": "04-25",
      "type": "birthday",
      "daysUntil": 6,
      "nextOccurrence": "2026-04-25",
      "note": "케이크보다 꽃 선호",
      "autoDetected": true,
      "sourceMemoryId": 15,
      "createdAt": "2026-04-01T00:00:00Z"
    },
    {
      "id": 2,
      "personId": 8,
      "personName": "이과장",
      "title": "입사 기념일",
      "date": "05-10",
      "type": "custom",
      "daysUntil": 21,
      "nextOccurrence": "2026-05-10",
      "note": null,
      "autoDetected": false,
      "sourceMemoryId": null,
      "createdAt": "2026-04-10T00:00:00Z"
    }
  ],
  "total": 2
}
```
- upcoming=true: 다가오는 기념일만 (기본 true)
- days: 앞으로 N일 이내 (기본 30, 최대 365)
- type: "birthday" | "anniversary" | "custom"
- date: MM-dd 형식 (연도 없음, 매년 반복)
- daysUntil: 다음 발생까지 남은 일수
- autoDetected: AI가 대화에서 자동 감지한 기념일
- sourceMemoryId: 자동 감지 시 근거 메모리

### POST /api/anniversaries (v2.3)
기념일 수동 등록.

```json
// Request
{
  "personId": 5,
  "title": "결혼기념일",
  "date": "06-15",
  "type": "anniversary",
  "note": "올해 10주년"
}
// Response 201
{
  "id": 3,
  "personId": 5,
  "personName": "김팀장",
  "title": "결혼기념일",
  "date": "06-15",
  "type": "anniversary",
  "daysUntil": 57,
  "nextOccurrence": "2026-06-15",
  "note": "올해 10주년",
  "autoDetected": false,
  "sourceMemoryId": null,
  "createdAt": "2026-04-19T10:00:00Z"
}
// Error 400 VALIDATION_ERROR — date 형식 오류, personId 누락
// Error 404 PERSON_NOT_FOUND
```

### PUT /api/anniversaries/{id} (v2.3)
기념일 수정.

```json
// Request (partial update)
{
  "title": "결혼기념일 (10주년)",
  "note": "레스토랑 예약 필요"
}
// Response 200: 수정된 전체 Anniversary 객체
// Error 404 ANNIVERSARY_NOT_FOUND
```

### DELETE /api/anniversaries/{id} (v2.3)
기념일 삭제.

```json
// Response 204 (No Content)
// Error 404 ANNIVERSARY_NOT_FOUND
```

### POST /api/anniversaries/detect (v2.3)
AI가 기존 메모리를 스캔하여 기념일을 자동 감지. 감지된 항목을 후보로 반환 (자동 저장 안 함).

```json
// Response 200
{
  "candidates": [
    {
      "personId": 5,
      "personName": "김팀장",
      "title": "생일",
      "date": "04-25",
      "type": "birthday",
      "confidence": 0.95,
      "sourceMemoryId": 15,
      "sourceText": "김팀장 생일이 4월 25일이래"
    }
  ],
  "scannedMemories": 45,
  "generatedAt": "2026-04-19T10:00:00Z"
}
```
- candidates: 감지된 기념일 후보 (최대 20개)
- confidence: 0.0~1.0
- 이미 등록된 기념일은 제외
- AI 호출이므로 rate limit 적용 (chat 버킷)

---

## 5.15 Notification Preferences (v2.4)

알림 유형별 세분화 설정. Settings의 단순 on/off 대신, 기능별 알림을 개별 제어.

### GET /api/notifications/preferences (v2.4)
알림 선호 설정 조회. 설정이 없으면 기본값으로 생성 후 반환.

```json
// Response 200
{
  "dailyDigest": true,
  "dailyDigestTime": "09:00",
  "weeklySummary": true,
  "weeklySummaryDay": "monday",
  "anniversaryReminder": true,
  "anniversaryReminderDaysBefore": 3,
  "conversationStarters": true,
  "memoryInsights": false,
  "relationshipHealth": true
}
```
- Settings.notification=false 이면 모든 알림 비활성 (마스터 스위치)
- 개별 설정은 마스터 스위치가 true일 때만 유효
- dailyDigestTime: HH:mm (24시간 형식), 기본 "09:00"
- weeklySummaryDay: "monday"~"sunday", 기본 "monday"
- anniversaryReminderDaysBefore: 1~30, 기본 3

### PUT /api/notifications/preferences (v2.4)
알림 선호 설정 업데이트. Partial update.

```json
// Request (일부만 전달 가능)
{
  "dailyDigest": false,
  "anniversaryReminderDaysBefore": 7
}
// Response 200: 전체 Preferences 객체 (위와 동일 형식)
// Error 400 VALIDATION_ERROR — dailyDigestTime 형식 오류, anniversaryReminderDaysBefore 범위 초과
```

**알림 유형별 설명:**

| 필드 | 타입 | 기본값 | 설명 |
|------|------|--------|------|
| dailyDigest | boolean | true | Daily Digest 푸시 알림 |
| dailyDigestTime | string | "09:00" | 발송 시각 (HH:mm) |
| weeklySummary | boolean | true | Weekly Summary 푸시 알림 |
| weeklySummaryDay | string | "monday" | 발송 요일 |
| anniversaryReminder | boolean | true | 기념일 다가올 때 알림 |
| anniversaryReminderDaysBefore | int | 3 | 기념일 N일 전 알림 (1~30) |
| conversationStarters | boolean | true | 대화 주제 제안 알림 |
| memoryInsights | boolean | false | 메모리 인사이트 발견 시 알림 |
| relationshipHealth | boolean | true | 관계 건강도 변화 알림 |

---

## 5.16 Relationship Nudges (v2.5)

오래 연락하지 않은 사람에게 연락을 제안하는 AI 기반 넛지. lastMentionedAt + Relationship Health Score 기반.

### GET /api/nudges (v2.5)
현재 활성 넛지 목록. 우선순위 높은 순 정렬.

```json
// Query: ?limit=5 (optional, default 5, max 20)
// Response 200
{
  "nudges": [
    {
      "id": 1,
      "personId": 5,
      "personName": "김팀장",
      "relationship": "직장 상사",
      "reason": "32일 동안 언급이 없습니다",
      "lastMentionedAt": "2026-03-18T14:00:00Z",
      "daysSilent": 32,
      "suggestion": "김팀장의 최근 프로젝트 진행 상황을 물어보세요",
      "priority": "high",
      "createdAt": "2026-04-19T09:00:00Z"
    }
  ],
  "total": 3,
  "generatedAt": "2026-04-19T09:00:00Z"
}
```
- priority: "high" (30일+) | "medium" (14~29일) | "low" (7~13일)
- 넛지는 서버에서 Daily Digest 생성 시 함께 갱신 (별도 AI 호출 아님)
- 이미 dismiss된 넛지는 제외
- reason/suggestion은 AI가 생성

### POST /api/nudges/{id}/dismiss (v2.5)
넛지 일시 숨김. 7일 후 조건 충족 시 재생성 가능.

```json
// Response 204 (No Content)
// Error 404 NUDGE_NOT_FOUND
```

### GET /api/nudges/settings (v2.5)
넛지 생성 기준 설정 조회.

```json
// Response 200
{
  "enabled": true,
  "silentDaysThreshold": 14,
  "maxNudgesPerDay": 3,
  "excludedPersonIds": []
}
```

### PUT /api/nudges/settings (v2.5)
넛지 설정 업데이트. Partial update.

```json
// Request
{
  "silentDaysThreshold": 21,
  "excludedPersonIds": [5, 8]
}
// Response 200: 전체 Settings 객체
// Error 400 VALIDATION_ERROR — silentDaysThreshold 범위 (1~90)
```

| 필드 | 타입 | 기본값 | 설명 |
|------|------|--------|------|
| enabled | boolean | true | 넛지 기능 활성화 |
| silentDaysThreshold | int | 14 | N일 이상 미언급 시 넛지 생성 (1~90) |
| maxNudgesPerDay | int | 3 | 하루 최대 넛지 수 (1~10) |
| excludedPersonIds | int[] | [] | 넛지 제외할 인물 ID 목록 |

---

## 5.17 Gift Suggestions (v2.6)

AI가 인물의 취향, 관심사, 기념일을 분석하여 선물 아이디어를 제안.

### POST /api/people/{id}/gift-suggestions (v2.6)
인물에 대한 선물 제안 생성. AI가 해당 인물의 메모리(취향, 관심사)를 분석.

```json
// Request (optional)
{
  "occasion": "birthday",
  "budget": "30000",
  "count": 5
}
// Response 200
{
  "personId": 5,
  "personName": "김팀장",
  "occasion": "birthday",
  "suggestions": [
    {
      "id": 1,
      "title": "스타벅스 텀블러",
      "reason": "스타벅스를 좋아한다고 하셨어요",
      "priceRange": "20000-35000",
      "category": "음료/카페",
      "sourceMemoryIds": [15, 23]
    },
    {
      "id": 2,
      "title": "캠핑 머그컵",
      "reason": "주말에 캠핑을 즐기시더라고요",
      "priceRange": "15000-25000",
      "category": "아웃도어",
      "sourceMemoryIds": [42]
    }
  ],
  "generatedAt": "2026-04-19T10:00:00Z"
}
// Error 404 PERSON_NOT_FOUND
```
- occasion: "birthday" | "anniversary" | "holiday" | "thank_you" | "general" (기본 "general")
- budget: 원 단위 문자열 (optional, 기본 무제한)
- count: 1~10 (기본 5)
- AI 호출이므로 rate limit 적용 (chat 버킷)
- sourceMemoryIds: 제안 근거가 된 메모리 ID들
- priceRange: 대략적 가격대 (AI 추정)

---

## 5.18 Relationship Timeline (v2.7)

인물별 상호작용 히스토리를 시간순으로 통합 조회. 채팅 언급, 메모리, 기념일을 하나의 타임라인으로 제공.

### GET /api/people/{personId}/timeline (v2.7)
인물과 관련된 모든 이벤트를 시간순 통합 조회.

```json
// Query: ?limit=20&offset=0&types=chat,memory,anniversary (all optional)
// Response 200
{
  "personId": 5,
  "personName": "김팀장",
  "events": [
    {
      "type": "memory",
      "timestamp": "2026-04-18T14:30:00Z",
      "title": "스타벅스 선호",
      "detail": "스타벅스 좋아한다고 함",
      "memoryId": 15,
      "category": "preference"
    },
    {
      "type": "chat",
      "timestamp": "2026-04-17T10:20:00Z",
      "title": "커피 취향 대화",
      "detail": "김팀장이 스타벅스 아메리카노를 좋아한다고 했어",
      "chatMessageId": 42
    },
    {
      "type": "anniversary",
      "timestamp": "2026-04-25T00:00:00Z",
      "title": "생일",
      "detail": "케이크보다 꽃 선호",
      "anniversaryId": 1,
      "isFuture": true
    }
  ],
  "total": 15,
  "hasMore": false
}
// Error 404 PERSON_NOT_FOUND
// Error 403 FORBIDDEN
```
- types: "chat" | "memory" | "anniversary" (쉼표 구분, 기본 전체)
- limit: 1~50 (기본 20)
- offset: 페이지네이션 (기본 0)
- 정렬: timestamp 내림차순 (최신 먼저), isFuture=true인 기념일은 맨 위
- chat: 해당 인물 언급 메시지 (PersonMemory와 연결된 채팅)
- memory: 해당 인물의 PersonMemory 기록
- anniversary: 해당 인물의 기념일
- detail: 원본 내용 요약 (채팅은 content 앞 100자, 메모리는 content, 기념일은 note)

---

## 5.19 Quick Notes (v2.8)

채팅 없이 직접 메모리를 생성. 빠르게 메모를 남기고 싶을 때 사용.

### POST /api/memories/note (v2.8)
직접 메모리 생성. AI가 카테고리를 자동 분류하고 제목을 생성.

```json
// Request
{
  "content": "김팀장 생일 4월 25일, 케이크보다 꽃 선호",
  "category": "people",
  "personName": "김팀장"
}
// Response 201
{
  "id": 55,
  "title": "김팀장 생일 — 4월 25일",
  "content": "김팀장 생일 4월 25일, 케이크보다 꽃 선호",
  "category": "people",
  "createdAt": "2026-04-19T12:00:00Z",
  "autoTitle": true,
  "personDetail": {
    "normalizedName": "김팀장",
    "relationship": null,
    "trait": "케이크보다 꽃 선호",
    "context": "직접 메모",
    "sentiment": "neutral"
  }
}
// Error 400 VALIDATION_ERROR — content 빈 문자열
// Error 400 EMPTY_MESSAGE — content 누락
```
- content: 필수 (1~2000자)
- category: optional (생략 시 AI가 자동 분류)
- personName: optional (people 카테고리일 때 인물 연결)
- autoTitle: AI가 제목을 자동 생성했는지 여부
- personName 제공 시: 기존 Person 매칭 (normalizedName) 또는 새 Person 생성
- AI 호출: 제목 생성 + 카테고리 미지정 시 분류 (rate limit: chat 버킷)
- personDetail: people 카테고리일 때만 포함

### POST /api/memories/note/batch (v2.8)
여러 메모를 한 번에 생성. 최대 10개.

```json
// Request
{
  "notes": [
    { "content": "내일 팀 미팅 오후 2시", "category": "schedule" },
    { "content": "점심 12000원 지출", "category": "finance" }
  ]
}
// Response 201
{
  "created": [
    { "id": 56, "title": "팀 미팅 — 내일 오후 2시", "category": "schedule" },
    { "id": 57, "title": "점심 지출 12,000원", "category": "finance" }
  ],
  "count": 2
}
// Error 400 VALIDATION_ERROR — notes 빈 배열, 10개 초과, content 누락
```
- notes: 1~10개
- 각 note는 POST /api/memories/note와 동일 스키마
- AI 호출 1회로 전체 처리 (배치 프롬프트)

---

## 5.23 Shared Memories (v3.2)

특정 메모리를 공유 링크로 외부에 공유. 링크 접근 시 인증 불필요 (읽기 전용).
공유 링크는 만료 시간 설정 가능.

### POST /api/memories/{id}/share (v3.2)

메모리 공유 링크 생성. 이미 공유 중이면 기존 링크 반환.

```json
// Request
{ "expiresInHours": 168 }
// Response 201
{
  "shareId": "abc123xyz",
  "shareUrl": "/api/shared/abc123xyz",
  "memoryId": 1,
  "expiresAt": "2026-04-28T12:00:00Z",
  "createdAt": "2026-04-21T12:00:00Z"
}
```
- shareId: 12자 랜덤 URL-safe
- expiresInHours: 기본 168 (7일), 최대 720 (30일)

### GET /api/shared/{shareId} (v3.2)

공유된 메모리 조회 (인증 불필요).

```json
// Response 200
{
  "memory": {
    "content": "김민수가 이직 고민 중. 현재 회사 연봉 불만족.",
    "category": "people",
    "personName": "김민수",
    "createdAt": "2026-04-15T10:00:00Z"
  },
  "sharedBy": "Jo",
  "expiresAt": "2026-04-28T12:00:00Z"
}
// Error 404
{ "error": "공유 링크가 만료되었거나 존재하지 않습니다.", "code": "SHARE_NOT_FOUND" }
```

### DELETE /api/memories/{id}/share (v3.2)

공유 링크 해제 (즉시 만료).

```json
// Response 204 (No Content)
// Error 404
{ "error": "공유 링크를 찾을 수 없습니다.", "code": "SHARE_NOT_FOUND" }
```

---

## 5.24 Memory Tags (v3.3)

사용자 정의 태그로 메모리 분류. 메모리당 최대 5개 태그.

### GET /api/tags (v3.3)

사용자의 전체 태그 목록 (사용 빈도순).

```json
// Response 200
{
  "tags": [
    { "id": 1, "name": "중요", "color": "#FF5733", "count": 12 },
    { "id": 2, "name": "팔로업", "color": "#33B5FF", "count": 8 }
  ],
  "totalCount": 5
}
```

### POST /api/tags (v3.3)

태그 생성.

```json
// Request
{ "name": "중요", "color": "#FF5733" }
// Response 201
{ "id": 1, "name": "중요", "color": "#FF5733", "count": 0 }
// Error 409
{ "error": "이미 존재하는 태그입니다.", "code": "TAG_EXISTS" }
```

### DELETE /api/tags/{id} (v3.3)
```json
// Response 204 (No Content)
// Error 404
{ "error": "태그를 찾을 수 없습니다.", "code": "TAG_NOT_FOUND" }
```

### POST /api/memories/{id}/tags (v3.3)

메모리에 태그 추가.

```json
// Request
{ "tagIds": [1, 2] }
// Response 200
{
  "memoryId": 1,
  "tags": [
    { "id": 1, "name": "중요", "color": "#FF5733" },
    { "id": 2, "name": "팔로업", "color": "#33B5FF" }
  ]
}
// Error 400 (태그 5개 초과)
{ "error": "메모리당 최대 5개 태그만 가능합니다.", "code": "TAG_LIMIT_EXCEEDED" }
```

### DELETE /api/memories/{id}/tags/{tagId} (v3.3)
```json
// Response 204 (No Content)
```

### GET /api/memories?tag={tagId} (v3.3)

기존 GET /api/memories에 tag 쿼리 파라미터 추가. 특정 태그가 달린 메모리만 필터링.

---

## 5.25 AI Chat Suggestions (v3.4)

대화 시작 시 AI가 현재 맥락(최근 메모리, 시간대, 인물 건강점수)을 분석하여 대화 주제 추천.

### GET /api/chat/suggestions (v3.4)

```json
// Query: ?limit=5
// Response 200
{
  "suggestions": [
    {
      "id": 1,
      "type": "followup",
      "text": "김민수 이직 건 어떻게 됐어?",
      "reason": "2주 전 이직 고민 메모리가 있어요",
      "relatedMemoryId": 42,
      "personName": "김민수"
    },
    {
      "id": 2,
      "type": "reminder",
      "text": "내일 엄마 생신이에요. 선물 준비했어?",
      "reason": "내일 기념일이 등록되어 있어요",
      "relatedMemoryId": null,
      "personName": "엄마"
    },
    {
      "id": 3,
      "type": "exploration",
      "text": "요즘 건강 관리 어떻게 하고 있어?",
      "reason": "건강 카테고리 메모리가 2주째 없어요",
      "relatedMemoryId": null,
      "personName": null
    }
  ]
}
```

**type enum**: `followup` | `reminder` | `exploration` | `check_in`
- followup: 과거 메모리 후속 질문
- reminder: 기념일/일정 리마인드
- exploration: 오래 안 다룬 카테고리 탐색
- check_in: 관계 건강점수 낮은 인물 안부

### POST /api/chat/suggestions/{id}/use (v3.4)

추천을 사용했음을 기록 (추천 품질 개선용).

```json
// Response 200
{ "id": 1, "used": true, "usedAt": "2026-04-21T10:00:00Z" }
```

---

## 5.26 Memory Deduplication (v3.5)

AI가 유사/중복 메모리를 탐지하고 병합을 제안. 사용자가 승인하면 하나로 합침.

### GET /api/memories/duplicates (v3.5)

중복 후보 그룹 목록 조회. AI 유사도 점수 기반.

```json
// Query: ?minSimilarity=0.8&limit=10
// Response 200
{
  "groups": [
    {
      "groupId": 1,
      "memories": [
        { "id": 10, "content": "민수가 이직 준비 중이라고 했다", "createdAt": "2026-04-10T09:00:00Z" },
        { "id": 25, "content": "김민수 이직 고민 중", "createdAt": "2026-04-15T14:00:00Z" }
      ],
      "similarity": 0.92,
      "suggestedMerge": "김민수가 이직을 준비하고 있으며 고민 중이다"
    }
  ],
  "totalGroups": 3
}
```

### POST /api/memories/duplicates/{groupId}/merge (v3.5)

중복 그룹을 하나의 메모리로 병합. 원본 메모리들은 삭제되고 새 병합 메모리가 생성됨.

```json
// Request
{
  "mergedContent": "김민수가 이직을 준비하고 있으며 고민 중이다",
  "keepMemoryId": 10
}
// Response 200
{
  "mergedMemory": {
    "id": 10,
    "content": "김민수가 이직을 준비하고 있으며 고민 중이다",
    "originalIds": [10, 25],
    "mergedAt": "2026-04-21T12:00:00Z"
  },
  "deletedIds": [25]
}
// Error 404 MEMORY_NOT_FOUND — groupId 또는 keepMemoryId 없음
// Error 400 VALIDATION_ERROR — keepMemoryId가 그룹에 속하지 않음
```

### POST /api/memories/duplicates/{groupId}/dismiss (v3.5)

중복 후보를 무시 처리. 이후 동일 그룹은 다시 추천되지 않음.

```json
// Response 200
{ "groupId": 1, "dismissed": true }
```

---

## 5.27 Chat Reactions (v3.6)

채팅 메시지에 이모지 반응 추가. AI 응답 품질 피드백으로 활용.

### POST /api/chat/{messageId}/reactions (v3.6)

```json
// Request
{ "emoji": "❤️" }
// Response 201
{
  "id": 1,
  "messageId": 42,
  "emoji": "❤️",
  "createdAt": "2026-04-21T10:00:00Z"
}
// Error 404 MESSAGE_NOT_FOUND
// Error 400 INVALID_EMOJI — 허용 목록에 없는 이모지
```

**허용 이모지**: `❤️` | `💡` | `😊` | `👍` | `😢` | `🔥`

### DELETE /api/chat/{messageId}/reactions/{reactionId} (v3.6)

```json
// Response 204 (No Content)
// Error 404 REACTION_NOT_FOUND
```

### GET /api/chat/{messageId}/reactions (v3.6)

```json
// Response 200
{
  "reactions": [
    { "id": 1, "emoji": "❤️", "createdAt": "2026-04-21T10:00:00Z" },
    { "id": 2, "emoji": "💡", "createdAt": "2026-04-21T10:05:00Z" }
  ]
}
```

### GET /api/chat/reactions/stats (v3.6)

반응 통계. AI 응답 품질 개선 데이터로 활용.

```json
// Query: ?days=30
// Response 200
{
  "totalReactions": 45,
  "byEmoji": {
    "❤️": 15,
    "💡": 12,
    "😊": 8,
    "👍": 6,
    "😢": 2,
    "🔥": 2
  },
  "reactionRate": 0.23
}
```

---

## 5.28 People Groups (v3.7)

인물을 커스텀 그룹으로 분류. AI가 자동 그룹 추천도 제공.

### GET /api/people/groups (v3.7)

```json
// Response 200
{
  "groups": [
    {
      "id": 1,
      "name": "가족",
      "color": "#FF6B6B",
      "memberCount": 4,
      "createdAt": "2026-04-21T10:00:00Z"
    },
    {
      "id": 2,
      "name": "직장 동료",
      "color": "#4ECDC4",
      "memberCount": 6,
      "createdAt": "2026-04-21T10:00:00Z"
    }
  ]
}
```

### POST /api/people/groups (v3.7)

```json
// Request
{ "name": "대학 친구", "color": "#45B7D1" }
// Response 201
{
  "id": 3,
  "name": "대학 친구",
  "color": "#45B7D1",
  "memberCount": 0,
  "createdAt": "2026-04-21T10:00:00Z"
}
// Error 409 GROUP_EXISTS — 같은 이름 그룹 존재
// Error 400 VALIDATION_ERROR — 이름 빈값 또는 30자 초과
```

### PUT /api/people/groups/{groupId} (v3.7)

```json
// Request
{ "name": "대학교 친구들", "color": "#FF9F43" }
// Response 200
{ "id": 3, "name": "대학교 친구들", "color": "#FF9F43", "memberCount": 2, "createdAt": "2026-04-21T10:00:00Z" }
// Error 404 GROUP_NOT_FOUND
```

### DELETE /api/people/groups/{groupId} (v3.7)

그룹 삭제. 소속 인물의 그룹 연결만 해제, 인물 자체는 삭제 안 됨.

```json
// Response 204 (No Content)
// Error 404 GROUP_NOT_FOUND
```

### POST /api/people/groups/{groupId}/members (v3.7)

인물을 그룹에 추가.

```json
// Request
{ "personIds": [1, 3, 5] }
// Response 200
{ "groupId": 3, "addedCount": 3, "memberCount": 3 }
// Error 404 GROUP_NOT_FOUND
// Error 400 PERSON_NOT_FOUND — personIds 중 없는 인물 포함
```

### DELETE /api/people/groups/{groupId}/members/{personId} (v3.7)

```json
// Response 204 (No Content)
// Error 404 GROUP_NOT_FOUND
// Error 404 PERSON_NOT_FOUND
```

### GET /api/people/groups/suggestions (v3.7)

AI가 대화/메모리 패턴을 분석해 그룹 추천.

```json
// Response 200
{
  "suggestions": [
    {
      "name": "직장 동료",
      "personIds": [2, 4, 7],
      "personNames": ["김철수", "이영희", "박준호"],
      "reason": "직장 관련 메모리에서 자주 함께 언급되는 인물들입니다",
      "confidence": 0.85
    }
  ]
}
```

---

## 5.29 Memory Highlights (v3.8)

AI가 기간별 핵심 메모리를 선별. 주간/월간 하이라이트 카드로 제공.

### GET /api/memories/highlights (v3.8)

```json
// Query: ?period=weekly&date=2026-04-21
// Response 200
{
  "period": "weekly",
  "startDate": "2026-04-14",
  "endDate": "2026-04-20",
  "highlights": [
    {
      "id": 1,
      "memory": {
        "id": 42,
        "content": "민수가 드디어 이직에 성공했다고 알려줬다",
        "category": "RELATIONSHIP",
        "personName": "김민수",
        "createdAt": "2026-04-18T15:00:00Z"
      },
      "reason": "오랫동안 추적하던 민수의 이직 건이 해결된 중요한 전환점",
      "importance": 0.95,
      "tags": ["milestone", "positive"]
    },
    {
      "id": 2,
      "memory": {
        "id": 55,
        "content": "운동 루틴을 다시 시작했다 - 매일 30분 달리기",
        "category": "HEALTH",
        "personName": null,
        "createdAt": "2026-04-16T08:00:00Z"
      },
      "reason": "건강 습관 재개는 장기적으로 중요한 변화",
      "importance": 0.82,
      "tags": ["habit_change", "positive"]
    }
  ],
  "summary": "이번 주는 민수의 이직 성공 소식과 함께 건강 습관을 다시 시작한 의미 있는 한 주였어요.",
  "totalHighlights": 5
}
```

**period enum**: `weekly` | `monthly`
**tags enum**: `milestone` | `positive` | `negative` | `habit_change` | `relationship_change` | `decision` | `learning`

### POST /api/memories/highlights/{highlightId}/save (v3.8)

하이라이트를 영구 저장 (즐겨찾기). 이후 별도 조회 가능.

```json
// Response 200
{ "id": 1, "saved": true, "savedAt": "2026-04-21T12:00:00Z" }
```

### GET /api/memories/highlights/saved (v3.8)

저장된 하이라이트 목록.

```json
// Query: ?offset=0&limit=20
// Response 200
{
  "highlights": [ /* 위와 동일 구조 + "savedAt" 필드 추가 */ ],
  "total": 8,
  "offset": 0,
  "limit": 20
}
```

---

## 5.30 Chat Context Memory (v3.9)

AI가 최근 대화 맥락을 요약하여 저장하고, 다음 대화 시 자동 주입. 연속성 있는 대화 경험 제공.

### GET /api/chat/context (v3.9)

현재 활성 컨텍스트 조회.

```json
// Response 200
{
  "context": {
    "id": 1,
    "summary": "민수 이직 건, 운동 루틴 시작, 엄마 생신 선물 고민 중",
    "topics": ["민수 이직", "운동", "엄마 생신"],
    "lastUpdated": "2026-04-21T15:00:00Z",
    "messageCount": 25,
    "expiresAt": "2026-04-28T15:00:00Z"
  }
}
```

### POST /api/chat/context/refresh (v3.9)

AI가 최근 N개 메시지를 분석하여 컨텍스트 재생성.

```json
// Request
{ "messageCount": 50 }
// Response 200
{
  "context": {
    "id": 2,
    "summary": "민수 이직 성공 축하, 운동 3주차 유지 중, 엄마 생신 선물로 꽃 결정",
    "topics": ["민수 이직 성공", "운동 습관", "엄마 생신"],
    "lastUpdated": "2026-04-21T16:00:00Z",
    "messageCount": 50,
    "expiresAt": "2026-04-28T16:00:00Z"
  }
}
```

### DELETE /api/chat/context (v3.9)

컨텍스트 초기화.

```json
// Response 204 (No Content)
```

---

## 5.31 Memory Archive (v4.0)

90일 이상 된 메모리를 자동 아카이브. 아카이브된 메모리는 검색에서 제외되지만 복원 가능.

### GET /api/memories/archive (v4.0)

```json
// Query: ?offset=0&limit=20
// Response 200
{
  "memories": [
    {
      "id": 10,
      "content": "작년 여름 제주도 여행 계획",
      "category": "TRAVEL",
      "personName": null,
      "archivedAt": "2026-04-01T00:00:00Z",
      "originalCreatedAt": "2026-01-01T10:00:00Z"
    }
  ],
  "total": 15,
  "offset": 0,
  "limit": 20
}
```

### POST /api/memories/{id}/archive (v4.0)

메모리를 수동 아카이브.

```json
// Response 200
{ "id": 10, "archived": true, "archivedAt": "2026-04-21T12:00:00Z" }
// Error 404 MEMORY_NOT_FOUND
```

### POST /api/memories/{id}/restore (v4.0)

아카이브된 메모리 복원.

```json
// Response 200
{ "id": 10, "archived": false, "restoredAt": "2026-04-21T12:00:00Z" }
// Error 404 MEMORY_NOT_FOUND
// Error 400 NOT_ARCHIVED — 아카이브 상태가 아닌 메모리
```

### GET /api/memories/archive/stats (v4.0)

아카이브 통계.

```json
// Response 200
{
  "totalArchived": 15,
  "byCategory": { "TRAVEL": 3, "WORK": 5, "HEALTH": 2, "RELATIONSHIP": 5 },
  "oldestArchivedAt": "2026-01-15T00:00:00Z"
}
```

---

## 5.32 People Merge Suggestions (v4.1)

AI가 중복 인물을 탐지하고 병합을 제안. "김민수"와 "민수"가 같은 사람인지 판별.

### GET /api/people/merge-suggestions (v4.1)

```json
// Response 200
{
  "suggestions": [
    {
      "id": 1,
      "person1": { "id": 5, "name": "김민수" },
      "person2": { "id": 12, "name": "민수" },
      "confidence": 0.91,
      "reason": "같은 직장, 유사한 대화 패턴, 이름 부분 일치",
      "sharedMemoryCount": 8
    }
  ],
  "totalSuggestions": 2
}
```

### POST /api/people/merge-suggestions/{id}/merge (v4.1)

두 인물을 병합. keepPersonId의 이름을 유지하고, 다른 인물의 메모리를 이관.

```json
// Request
{ "keepPersonId": 5 }
// Response 200
{
  "mergedPerson": {
    "id": 5,
    "name": "김민수",
    "memoriesTransferred": 8,
    "mergedAt": "2026-04-21T12:00:00Z"
  },
  "deletedPersonId": 12
}
// Error 404 SUGGESTION_NOT_FOUND
// Error 400 INVALID_KEEP_PERSON — keepPersonId가 제안에 속하지 않음
```

### POST /api/people/merge-suggestions/{id}/dismiss (v4.1)

병합 제안 무시.

```json
// Response 200
{ "id": 1, "dismissed": true }
```

---

## 5.33 Chat Export (v4.2)

대화 내역을 텍스트/JSON 형식으로 내보내기.

### GET /api/chat/export (v4.2)

```json
// Query: ?format=text&startDate=2026-04-01&endDate=2026-04-21
// Response 200 (format=json)
{
  "export": {
    "format": "json",
    "period": { "start": "2026-04-01", "end": "2026-04-21" },
    "messageCount": 150,
    "messages": [
      {
        "id": 1,
        "role": "user",
        "content": "오늘 민수를 만났어",
        "createdAt": "2026-04-01T10:00:00Z",
        "reactions": ["❤️"]
      },
      {
        "id": 2,
        "role": "assistant",
        "content": "민수를 만났군요! 어떤 이야기를 나눴어요?",
        "createdAt": "2026-04-01T10:00:01Z",
        "reactions": []
      }
    ]
  }
}
// Response 200 (format=text) — Content-Type: text/plain
// 줄바꿈 구분 텍스트
```

**format enum**: `json` | `text`
- json: 구조화된 JSON (위 형식)
- text: 사람이 읽기 쉬운 텍스트 (타임스탬프 + 역할 + 내용)

### GET /api/chat/export/stats (v4.2)

내보내기 가능한 데이터 통계.

```json
// Response 200
{
  "totalMessages": 500,
  "firstMessageAt": "2026-04-01T10:00:00Z",
  "lastMessageAt": "2026-04-21T15:00:00Z",
  "byRole": { "user": 250, "assistant": 250 }
}
```

---

## 6. Settings (v0.7)

사용자별 앱 설정. 서버에 저장하여 다중 기기 동기화 지원.

### GET /api/settings
현재 설정 조회. 설정이 없으면 기본값으로 생성 후 반환.

```json
// Response 200
{
  "theme": "system",
  "haptics": true,
  "notification": true,
  "language": "ko"
}
```

### PUT /api/settings
설정 전체 또는 일부 업데이트. 전달된 필드만 변경, 나머지 유지 (partial update).

```json
// Request (전체 또는 일부)
{
  "theme": "dark",
  "haptics": false
}
// Response 200
{
  "theme": "dark",
  "haptics": false,
  "notification": true,
  "language": "ko"
}
// Error 400 VALIDATION_ERROR — theme enum 미일치 등
```

**설정 필드:**

| 필드 | 타입 | 기본값 | 허용 값 |
|------|------|--------|---------|
| theme | string | "system" | "system", "light", "dark" |
| haptics | boolean | true | true, false |
| notification | boolean | true | true, false |
| language | string | "ko" | "ko", "en" |

- 미인식 필드는 무시 (forward-compatible)
- 인증 필수

---

## 7. App Config (v1.0)

### GET /api/app/config
앱 설정. 인증 불필요. 최소 버전, 공지, 기능 플래그.

```json
// Response 200
{
  "minVersion": "1.0.0",
  "latestVersion": "1.0.0",
  "forceUpdate": false,
  "announcement": null,
  "features": {
    "quickActions": true,
    "memoryShare": true,
    "chatSummary": true,
    "reminders": true
  }
}
```
- `minVersion`: 이 버전 미만이면 강제 업데이트 (클라이언트 비교)
- `forceUpdate`: true면 앱 사용 차단 + 업데이트 안내
- `announcement`: 공지 메시지 (null이면 미표시)
- `features`: 기능 플래그 (false면 해당 기능 UI 숨김)
- 서버 하드코딩 (v1.0), 추후 관리 패널

---

## 8. Notification (v1.1)

### POST /api/notifications/token
푸시 알림 토큰 등록/갱신. 디바이스별 FCM/APNs 토큰 저장.

```json
// Request
{
  "token": "fcm-or-apns-token-string",
  "platform": "ios",
  "deviceId": "device-uuid"
}
// Response 200
{ "status": "registered" }
// Error 400 VALIDATION_ERROR — token/platform 누락
```
- platform: "ios" | "android"
- deviceId: 디바이스 고유 ID (중복 등록 방지)
- 같은 deviceId로 재등록 시 토큰 업데이트 (UPSERT)
- 로그아웃/계정삭제 시 토큰 자동 삭제

### DELETE /api/notifications/token
토큰 해제 (로그아웃 시).

```json
// Request
{ "deviceId": "device-uuid" }
// Response 204
```

---

## 5.20 Smart Notifications (v2.9)

AI가 메모리·기념일·관계 건강 점수를 분석하여 자동 생성하는 스마트 알림.
기존 Notification Preferences(v2.4)의 설정을 따름. 사용자가 dismiss하지 않은 알림만 노출.

### GET /api/notifications/smart (v2.9)

AI가 생성한 스마트 알림 목록. 최근 7일 내 미처리 알림만 반환.

```json
// Query: ?limit=20&offset=0
// Response 200
{
  "notifications": [
    {
      "id": 1,
      "type": "contact_reminder",
      "title": "김민수에게 연락할 때가 됐어요",
      "body": "마지막 대화가 2주 전이에요. 안부를 물어보는 건 어떨까요?",
      "personId": 5,
      "personName": "김민수",
      "priority": "medium",
      "triggerReason": "last_contact_gap",
      "createdAt": "2026-04-21T09:00:00Z",
      "expiresAt": "2026-04-28T09:00:00Z"
    }
  ],
  "totalCount": 3,
  "hasMore": false
}
```

**type enum**: `contact_reminder` | `anniversary_upcoming` | `memory_followup` | `relationship_alert`
**priority enum**: `high` | `medium` | `low`
**triggerReason enum**: `last_contact_gap` | `anniversary_near` | `health_score_drop` | `memory_stale` | `birthday_near`

### POST /api/notifications/smart/{id}/dismiss (v2.9)
```json
// Response 200
{ "id": 1, "dismissed": true, "dismissedAt": "2026-04-21T10:00:00Z" }
// Error 404
{ "error": "알림을 찾을 수 없습니다.", "code": "NOTIFICATION_NOT_FOUND" }
```

### POST /api/notifications/smart/generate (v2.9)

수동으로 스마트 알림 생성 트리거. AI가 현재 상태를 분석하여 새 알림을 생성.
기본적으로 하루 1회 자동 실행되지만, 사용자가 직접 트리거할 수 있음.

```json
// Response 200
{ "generated": 3, "message": "3개의 새 알림이 생성되었습니다." }
```

---

## 5.21 Relationship Map (v3.0)

인물 간 관계를 그래프로 시각화. 노드(인물) + 엣지(관계)로 구성.
클라이언트가 그래프 렌더링에 사용할 데이터 제공.

### GET /api/people/map (v3.0)

전체 관계 그래프 데이터. 메모리에서 추출된 인물과 관계를 반환.

```json
// Response 200
{
  "nodes": [
    {
      "personId": 1,
      "name": "김민수",
      "group": "친구",
      "healthScore": 78,
      "memoryCount": 15,
      "lastContactAt": "2026-04-18T14:00:00Z"
    }
  ],
  "edges": [
    {
      "id": 1,
      "sourcePersonId": 1,
      "targetPersonId": 2,
      "relationship": "같은 회사 동료",
      "strength": 3,
      "createdAt": "2026-04-10T09:00:00Z"
    }
  ],
  "totalNodes": 12,
  "totalEdges": 8
}
```

**strength**: 1 (약함) ~ 5 (강함), AI가 메모리 빈도 기반으로 자동 산출

### POST /api/people/map/link (v3.0)

두 인물 간 관계 연결 생성.

```json
// Request
{
  "sourcePersonId": 1,
  "targetPersonId": 2,
  "relationship": "같은 회사 동료"
}
// Response 201
{
  "id": 1,
  "sourcePersonId": 1,
  "targetPersonId": 2,
  "relationship": "같은 회사 동료",
  "strength": 1,
  "createdAt": "2026-04-21T10:00:00Z"
}
// Error 409
{ "error": "이미 연결된 관계입니다.", "code": "LINK_EXISTS" }
// Error 404
{ "error": "인물을 찾을 수 없습니다.", "code": "PERSON_NOT_FOUND" }
```

### DELETE /api/people/map/link/{id} (v3.0)
```json
// Response 204 (No Content)
// Error 404
{ "error": "관계 연결을 찾을 수 없습니다.", "code": "LINK_NOT_FOUND" }
```

---

## 5.22 Interaction Log (v3.1)

실제 만남·통화·메시지 등 상호작용을 수동으로 기록.
Relationship Timeline(v2.7)은 자동 수집이지만, Interaction Log는 사용자가 직접 기록.

### POST /api/people/{personId}/interactions (v3.1)

```json
// Request
{
  "type": "meeting",
  "title": "점심 식사",
  "note": "강남역 근처 일식집에서 만남. 이직 고민 상담.",
  "occurredAt": "2026-04-21T12:30:00Z",
  "duration": 90
}
// Response 201
{
  "id": 1,
  "personId": 5,
  "type": "meeting",
  "title": "점심 식사",
  "note": "강남역 근처 일식집에서 만남. 이직 고민 상담.",
  "occurredAt": "2026-04-21T12:30:00Z",
  "duration": 90,
  "createdAt": "2026-04-21T13:00:00Z"
}
// Error 404
{ "error": "인물을 찾을 수 없습니다.", "code": "PERSON_NOT_FOUND" }
```

**type enum**: `meeting` | `call` | `message` | `video_call` | `other`
**duration**: 분 단위 (nullable)

### GET /api/people/{personId}/interactions (v3.1)

```json
// Query: ?limit=20&offset=0&type=meeting
// Response 200
{
  "interactions": [
    {
      "id": 1,
      "personId": 5,
      "type": "meeting",
      "title": "점심 식사",
      "note": "강남역 근처 일식집에서 만남.",
      "occurredAt": "2026-04-21T12:30:00Z",
      "duration": 90,
      "createdAt": "2026-04-21T13:00:00Z"
    }
  ],
  "totalCount": 5,
  "hasMore": false
}
```

### DELETE /api/interactions/{id} (v3.1)
```json
// Response 204 (No Content)
// Error 404
{ "error": "상호작용 기록을 찾을 수 없습니다.", "code": "INTERACTION_NOT_FOUND" }
```

---

## 5.34 Onboarding Progress (v4.3)

첫 사용자의 핵심 기능 체험 진행률 추적. 온보딩 완료까지 UI 가이드 노출.

### GET /api/onboarding (v4.3)

```json
// Response 200
{
  "completed": false,
  "completedAt": null,
  "steps": [
    { "key": "first_chat", "title": "첫 대화하기", "completed": true, "completedAt": "2026-04-21T10:00:00Z" },
    { "key": "check_memory", "title": "기억된 내용 확인하기", "completed": false, "completedAt": null },
    { "key": "view_person", "title": "인물 프로필 보기", "completed": false, "completedAt": null },
    { "key": "give_feedback", "title": "기억에 피드백 주기", "completed": false, "completedAt": null },
    { "key": "explore_people", "title": "인물 탭 둘러보기", "completed": false, "completedAt": null }
  ],
  "progress": 20
}
```

**step key enum**: `first_chat` | `check_memory` | `view_person` | `give_feedback` | `explore_people`
- `progress`: 완료 비율 (0~100, 정수)
- `completed`: 모든 스텝 완료 시 true

### POST /api/onboarding/steps/{key}/complete (v4.3)

해당 온보딩 스텝을 완료 처리. 이미 완료된 스텝은 무시 (멱등).

```json
// Response 200
{
  "key": "check_memory",
  "completed": true,
  "completedAt": "2026-04-21T11:00:00Z",
  "totalProgress": 40
}
// Error 400
{ "error": "유효하지 않은 온보딩 단계입니다.", "code": "INVALID_ONBOARDING_STEP" }
```

### POST /api/onboarding/skip (v4.3)

온보딩 전체를 건너뛰기 (사용자가 "나중에" 선택 시).

```json
// Response 200
{ "completed": true, "skipped": true, "completedAt": "2026-04-21T11:00:00Z" }
```

---

## 5.35 Home Dashboard (v4.4)

메인 화면에서 한 번의 호출로 오늘의 브리핑, 추천, 관계 요약을 통합 조회.

### GET /api/dashboard (v4.4)

```json
// Response 200
{
  "greeting": "좋은 아침이에요, 민호님 ☀️",
  "date": "2026-04-21",
  "digest": {
    "newMemories": 3,
    "upcomingAnniversaries": [
      { "personName": "엄마", "title": "생신", "daysUntil": 2, "date": "2026-04-23" }
    ],
    "pendingNudges": 1
  },
  "suggestions": [
    {
      "type": "check_in",
      "text": "김민수에게 안부 연락해보는 건 어때요?",
      "personName": "김민수",
      "reason": "30일째 대화 없음"
    }
  ],
  "relationshipSummary": {
    "totalPeople": 15,
    "healthyCount": 10,
    "needsAttentionCount": 3,
    "newCount": 2
  },
  "recentHighlights": [
    {
      "memoryId": 42,
      "content": "박서연이 프로젝트 승진했다고 축하받았다",
      "personName": "박서연",
      "createdAt": "2026-04-20T18:00:00Z"
    }
  ],
  "onboarding": {
    "completed": false,
    "progress": 40
  }
}
```

**규칙:**
- `greeting`: 시간대별 자동 생성 (아침/점심/저녁/밤)
- `digest.upcomingAnniversaries`: 7일 이내 기념일만 (최대 3개)
- `suggestions`: 최대 3개 (check_in 우선)
- `recentHighlights`: 최근 24시간 핵심 메모리 (최대 3개)
- `onboarding`: 미완료 시에만 포함 (완료 후 null)

---

## 5.36 Memory Media Attachments (v4.5)

메모리에 이미지를 첨부. multipart/form-data 업로드, 메모리당 최대 3장.

### POST /api/memories/{memoryId}/media (v4.5)

```
Content-Type: multipart/form-data
- file: (binary, max 5MB, image/jpeg | image/png | image/webp)
```

```json
// Response 201
{
  "id": 1,
  "memoryId": 42,
  "url": "/api/media/abc123.jpg",
  "thumbnailUrl": "/api/media/abc123_thumb.jpg",
  "mimeType": "image/jpeg",
  "size": 245000,
  "createdAt": "2026-04-21T12:00:00Z"
}
// Error 400
{ "error": "지원하지 않는 파일 형식입니다.", "code": "INVALID_MEDIA_TYPE" }
// Error 400
{ "error": "메모리당 최대 3개의 미디어만 첨부할 수 있습니다.", "code": "MEDIA_LIMIT_EXCEEDED" }
// Error 400
{ "error": "파일 크기가 5MB를 초과합니다.", "code": "MEDIA_TOO_LARGE" }
```

### GET /api/memories/{memoryId}/media (v4.5)

```json
// Response 200
{
  "media": [
    {
      "id": 1,
      "memoryId": 42,
      "url": "/api/media/abc123.jpg",
      "thumbnailUrl": "/api/media/abc123_thumb.jpg",
      "mimeType": "image/jpeg",
      "size": 245000,
      "createdAt": "2026-04-21T12:00:00Z"
    }
  ],
  "totalCount": 1
}
```

### DELETE /api/memories/media/{mediaId} (v4.5)

```json
// Response 204 (No Content)
// Error 404
{ "error": "미디어를 찾을 수 없습니다.", "code": "MEDIA_NOT_FOUND" }
```

### GET /api/media/{filename} (v4.5)

이미지 파일 직접 서빙. 캐시 헤더 포함.

```
Response: binary (image/jpeg, image/png, image/webp)
Cache-Control: public, max-age=31536000
```

**기존 API 확장:**
- `GET /api/memories`, `GET /api/memories/{id}` 응답에 `mediaCount` 필드 추가 (정수, 0~3)
- `GET /api/memories/{id}` 응답에 `media` 배열 포함 (위 스키마와 동일)

---

## 5.37 User Avatar (v4.7)

프로필 사진 업로드/조회/삭제. Memory Media (v4.5) 패턴 재사용, 유저당 1장.

### POST /api/auth/avatar (v4.7)

```
Content-Type: multipart/form-data
- file: (binary, max 2MB, image/jpeg | image/png | image/webp)
```

```json
// Response 200
{
  "avatarUrl": "/api/auth/avatar/u_1_abc123.jpg",
  "thumbnailUrl": "/api/auth/avatar/u_1_abc123_thumb.jpg",
  "updatedAt": "2026-04-24T12:00:00Z"
}
// Error 400
{ "error": "지원하지 않는 파일 형식입니다.", "code": "INVALID_MEDIA_TYPE" }
// Error 400
{ "error": "파일 크기가 2MB를 초과합니다.", "code": "MEDIA_TOO_LARGE" }
```
- 기존 아바타가 있으면 교체 (이전 파일 삭제)
- 서버에서 200x200 썸네일 자동 생성

### GET /api/auth/avatar (v4.7)

```json
// Response 200
{
  "avatarUrl": "/api/auth/avatar/u_1_abc123.jpg",
  "thumbnailUrl": "/api/auth/avatar/u_1_abc123_thumb.jpg",
  "updatedAt": "2026-04-24T12:00:00Z"
}
// Response 200 (아바타 없음)
{
  "avatarUrl": null,
  "thumbnailUrl": null,
  "updatedAt": null
}
```

### DELETE /api/auth/avatar (v4.7)

```json
// Response 204 (No Content)
// Error 404
{ "error": "아바타가 설정되지 않았습니다.", "code": "AVATAR_NOT_FOUND" }
```

### GET /api/auth/avatar/{filename} (v4.7)

이미지 파일 직접 서빙.

```
Response: binary (image/jpeg, image/png, image/webp)
Cache-Control: public, max-age=31536000
```

**기존 API 확장:**
- `POST /api/auth/login`, `POST /api/auth/signup`, `POST /api/auth/refresh` 응답에 `avatarUrl` 필드 추가 (nullable string)

---

## 5.38 Advanced Search Filters (v4.8)

GET /api/search에 날짜 범위, 인물, 카테고리 필터 추가.

### GET /api/search (v4.8 확장)

```
// Query parameters (기존 q + 신규 필터)
?q=점심
&from=2026-04-01         (optional, ISO date)
&to=2026-04-24           (optional, ISO date)
&person=김팀장            (optional, normalizedName)
&category=finance         (optional, memory category)
&type=memories            (optional: chat | memories | people, 미지정 시 전체)
&sort=relevance           (optional: relevance | newest | oldest, default relevance)
&limit=20                 (optional, default 10, max 50)
&offset=0                 (optional, default 0)
```

```json
// Response 200
{
  "query": "점심",
  "filters": {
    "from": "2026-04-01",
    "to": "2026-04-24",
    "person": "김팀장",
    "category": "finance",
    "type": "memories",
    "sort": "relevance"
  },
  "results": {
    "chat": [],
    "memories": [
      {
        "id": 42,
        "category": "finance",
        "title": "점심 지출",
        "content": "12,000원 지출",
        "pinned": false,
        "personName": "김팀장",
        "createdAt": "2026-04-15T22:00:00Z"
      }
    ],
    "people": []
  },
  "counts": { "chat": 0, "memories": 1, "people": 0, "total": 1 },
  "pagination": { "offset": 0, "limit": 20, "hasMore": false }
}
```
- `from`/`to`: createdAt 범위 필터 (inclusive)
- `person`: Memory의 연관 인물 이름으로 필터 (normalizedName LIKE)
- `category`: Memory 카테고리 정확 일치
- `type`: 특정 타입만 검색 (미지정 시 전체)
- `sort`: relevance(기본, 키워드 매칭 우선), newest, oldest
- 기존 v0.6 응답과 하위 호환: 신규 필드는 optional, 기존 필드 유지
- `q`가 빈 문자열이면서 다른 필터가 있으면 필터만으로 검색 (browse 모드)
- `q`도 없고 필터도 없으면 400 VALIDATION_ERROR

---

## 5.39 Activity Heatmap (v4.9)

월간/연간 활동 히트맵 데이터. GitHub contributions 스타일.

### GET /api/activity/heatmap (v4.9)

```
// Query: ?year=2026&month=4 (optional, default 현재 연월)
// month 미지정 시 연간 데이터 반환
```

```json
// Response 200 (월간)
{
  "year": 2026,
  "month": 4,
  "days": [
    { "date": "2026-04-01", "chatCount": 3, "memoryCount": 5, "total": 8, "level": 2 },
    { "date": "2026-04-02", "chatCount": 0, "memoryCount": 0, "total": 0, "level": 0 },
    { "date": "2026-04-03", "chatCount": 7, "memoryCount": 12, "total": 19, "level": 4 }
  ],
  "summary": {
    "totalDays": 30,
    "activeDays": 22,
    "totalChats": 89,
    "totalMemories": 156,
    "maxDayTotal": 19,
    "currentStreak": 7,
    "longestStreak": 14
  }
}
```

```json
// Response 200 (연간, month 미지정)
{
  "year": 2026,
  "month": null,
  "days": [
    { "date": "2026-01-01", "chatCount": 2, "memoryCount": 3, "total": 5, "level": 1 }
  ],
  "summary": {
    "totalDays": 365,
    "activeDays": 180,
    "totalChats": 890,
    "totalMemories": 1560,
    "maxDayTotal": 25,
    "currentStreak": 7,
    "longestStreak": 30
  }
}
```
- `level`: 0~4 (0=비활동, 1=low, 2=medium, 3=high, 4=very high)
- level 기준: 0=0, 1=1~quartile1, 2=q1~median, 3=median~q3, 4=q3~max
- 연간 데이터: 해당 연도 1/1~12/31 (미래 날짜 제외)
- `currentStreak`: 오늘부터 역산 연속 활동일
- `longestStreak`: 해당 기간 내 최장 연속 활동일

---

## 5.40 Mood Tracking (v5.0)

대화 후 감정 태깅. 시간별 감정 트렌드 시각화 지원.

### POST /api/chat/{chatId}/mood (v5.0)

대화 메시지에 감정 태그 설정. 기존 값 덮어쓰기.

```json
// Request
{ "mood": "happy" }
// mood enum: "happy", "grateful", "neutral", "anxious", "sad", "angry", "excited", "lonely"

// Response 200
{
  "chatId": 1,
  "mood": "happy",
  "taggedAt": "2026-04-25T10:00:00"
}
// Error 404 MESSAGE_NOT_FOUND
// Error 400 INVALID_MOOD — 허용되지 않은 mood 값
```

### DELETE /api/chat/{chatId}/mood (v5.0)

감정 태그 제거.

```json
// Response 204 No Content
// Error 404 MESSAGE_NOT_FOUND
```

### GET /api/mood/trends (v5.0)

기간별 감정 분포 + 트렌드.

```json
// Query: ?period=week|month|year (기본: month)
// Response 200
{
  "period": "month",
  "from": "2026-03-25",
  "to": "2026-04-25",
  "distribution": {
    "happy": 12,
    "grateful": 8,
    "neutral": 15,
    "anxious": 3,
    "sad": 2,
    "angry": 0,
    "excited": 5,
    "lonely": 1
  },
  "totalTagged": 46,
  "dominantMood": "neutral",
  "trend": "improving",
  "weeklyBreakdown": [
    { "week": "2026-W13", "dominant": "neutral", "count": 10 },
    { "week": "2026-W14", "dominant": "happy", "count": 14 },
    { "week": "2026-W15", "dominant": "happy", "count": 12 },
    { "week": "2026-W16", "dominant": "grateful", "count": 10 }
  ]
}
```

- `trend`: "improving" | "stable" | "declining" — 최근 2주 vs 이전 2주 긍정 비율 비교
- 긍정: happy, grateful, excited / 부정: anxious, sad, angry, lonely / 중립: neutral

---

## 5.41 Contact Frequency Goals (v5.1)

인물별 연락 빈도 목표. 목표 미달 시 넛지 연동 가능.

### PUT /api/people/{personId}/frequency-goal (v5.1)

빈도 목표 설정/수정. Upsert.

```json
// Request
{
  "targetDays": 7,
  "reminderEnabled": true
}
// targetDays: 1~365 (N일에 1번 연락 목표)

// Response 200
{
  "personId": 1,
  "personName": "홍길동",
  "targetDays": 7,
  "reminderEnabled": true,
  "lastContactDate": "2026-04-20T14:30:00",
  "daysSinceContact": 5,
  "onTrack": true,
  "updatedAt": "2026-04-25T10:00:00"
}
// Error 404 PERSON_NOT_FOUND
// Error 400 VALIDATION_ERROR — targetDays 범위 초과
```

### DELETE /api/people/{personId}/frequency-goal (v5.1)

빈도 목표 삭제.

```json
// Response 204 No Content
// Error 404 PERSON_NOT_FOUND
```

### GET /api/frequency-goals (v5.1)

전체 빈도 목표 목록 + 달성 현황.

```json
// Response 200
{
  "goals": [
    {
      "personId": 1,
      "personName": "홍길동",
      "targetDays": 7,
      "reminderEnabled": true,
      "lastContactDate": "2026-04-20T14:30:00",
      "daysSinceContact": 5,
      "onTrack": true
    },
    {
      "personId": 2,
      "personName": "김영희",
      "targetDays": 14,
      "reminderEnabled": false,
      "lastContactDate": "2026-04-01T09:00:00",
      "daysSinceContact": 24,
      "onTrack": false
    }
  ],
  "summary": {
    "total": 2,
    "onTrack": 1,
    "overdue": 1
  }
}
```

---

## 5.42 Communication Quality Score (v5.2)

AI가 대화 패턴을 분석하여 소통 품질 종합 점수 제공.

### GET /api/insights/communication-quality (v5.2)

```json
// Query: ?period=week|month|year (기본: month)
// Response 200
{
  "period": "month",
  "overallScore": 78,
  "dimensions": {
    "consistency": 85,
    "depth": 72,
    "diversity": 65,
    "responsiveness": 90
  },
  "topPeople": [
    { "personId": 1, "personName": "홍길동", "score": 92 },
    { "personId": 2, "personName": "김영희", "score": 71 }
  ],
  "suggestions": [
    "김영희님과의 대화 깊이를 높여보세요. 최근 단답 위주입니다.",
    "새로운 주제로 대화를 시도해보세요."
  ],
  "previousScore": 74,
  "trend": "improving"
}
```

- `overallScore`: 0~100 (4개 차원 가중 평균)
- `consistency`: 꾸준한 소통 빈도 (연락 목표 달성률 기반)
- `depth`: 대화 길이 + 메모리 추출률
- `diversity`: 다양한 인물과의 소통
- `responsiveness`: 대화 시작 후 지속성
- `suggestions`: AI 생성 (2~3개, 한국어)
- `trend`: "improving" | "stable" | "declining"

---

## 5.43 Relationship Milestones (v5.3)

관계 이정표 자동 감지 + 수동 등록. 메모리/대화/기념일에서 자동 추출.

### GET /api/people/{personId}/milestones (v5.3)

인물별 이정표 목록.

```json
// Query: ?limit=20&offset=0
// Response 200
{
  "milestones": [
    {
      "id": 1,
      "type": "auto",
      "category": "first_chat",
      "title": "첫 대화",
      "description": "홍길동님과 처음 대화를 나눈 날",
      "date": "2026-03-15",
      "sourceType": "chat",
      "sourceId": 42,
      "celebrated": false,
      "createdAt": "2026-03-15T14:00:00"
    },
    {
      "id": 2,
      "type": "auto",
      "category": "memory_100",
      "title": "100번째 메모리",
      "description": "홍길동님에 대한 100번째 기억이 만들어졌습니다",
      "date": "2026-04-20",
      "sourceType": "memory",
      "sourceId": null,
      "celebrated": true,
      "createdAt": "2026-04-20T10:00:00"
    }
  ],
  "total": 5,
  "limit": 20,
  "offset": 0
}
```

- `type`: "auto" (AI 감지) | "manual" (사용자 등록)
- `category` auto 종류: "first_chat", "chat_10", "chat_50", "chat_100", "memory_10", "memory_50", "memory_100", "streak_7", "streak_30", "streak_100"
- `celebrated`: 사용자가 이정표를 확인/축하했는지

### POST /api/people/{personId}/milestones (v5.3)

수동 이정표 등록.

```json
// Request
{
  "title": "함께 여행",
  "description": "제주도 여행을 함께 했다",
  "date": "2026-04-15"
}
// Response 201
{
  "id": 3,
  "type": "manual",
  "category": "custom",
  "title": "함께 여행",
  "description": "제주도 여행을 함께 했다",
  "date": "2026-04-15",
  "sourceType": null,
  "sourceId": null,
  "celebrated": false,
  "createdAt": "2026-04-25T10:00:00"
}
// Error 404 PERSON_NOT_FOUND
// Error 400 VALIDATION_ERROR
```

### PATCH /api/milestones/{id}/celebrate (v5.3)

이정표 축하 토글.

```json
// Response 200
{
  "id": 1,
  "celebrated": true,
  "celebratedAt": "2026-04-25T10:00:00"
}
// Error 404 MILESTONE_NOT_FOUND
```

### DELETE /api/milestones/{id} (v5.3)

수동 이정표만 삭제 가능. auto 이정표는 삭제 불가.

```json
// Response 204 No Content
// Error 404 MILESTONE_NOT_FOUND
// Error 400 VALIDATION_ERROR — auto 타입 이정표 삭제 불가
```

---

## 5.44 Relationship Report (v5.4)

월간 관계 종합 리포트. 지정 기간 내 모든 관계 데이터(소통 빈도, 감정 트렌드, 품질 점수, 이정표)를 종합 분석하여 리포트 생성.

### GET /api/reports/relationship

```
Query: ?period=monthly|weekly&personId={optional}&date=2026-04
Headers: Authorization: Bearer {JWT}
```

```json
// Response 200
{
  "period": "monthly",
  "startDate": "2026-04-01",
  "endDate": "2026-04-30",
  "summary": {
    "totalConversations": 45,
    "totalPeople": 12,
    "averageMoodScore": 7.2,
    "averageQualityScore": 8.1
  },
  "topPeople": [
    {
      "personId": 1,
      "personName": "엄마",
      "conversationCount": 15,
      "moodTrend": "improving",
      "qualityScore": 8.5,
      "frequencyGoalMet": true,
      "milestoneCount": 2
    }
  ],
  "insights": [
    {
      "type": "POSITIVE_TREND",
      "message": "이번 달 엄마와의 대화 빈도가 30% 증가했어요.",
      "personId": 1
    }
  ],
  "actionItems": [
    {
      "type": "CONTACT_REMINDER",
      "message": "친구 민수에게 2주째 연락하지 않았어요.",
      "personId": 3,
      "priority": "HIGH"
    }
  ]
}
// Error 400 VALIDATION_ERROR — 잘못된 period/date 형식
```

### GET /api/reports/relationship/{personId}

특정 인물에 대한 상세 관계 리포트.

```
Query: ?period=monthly&date=2026-04
Headers: Authorization: Bearer {JWT}
```

```json
// Response 200
{
  "personId": 1,
  "personName": "엄마",
  "period": "monthly",
  "startDate": "2026-04-01",
  "endDate": "2026-04-30",
  "conversationCount": 15,
  "memoriesCreated": 8,
  "moodDistribution": { "HAPPY": 10, "NEUTRAL": 4, "SAD": 1 },
  "moodTrend": "improving",
  "qualityScore": 8.5,
  "qualityTrend": "stable",
  "frequencyGoal": { "target": 3, "actual": 4, "unit": "WEEKLY", "met": true },
  "milestones": [
    { "id": 1, "title": "첫 여행 계획", "date": "2026-04-15" }
  ],
  "topTopics": ["여행", "건강", "식사"],
  "insights": [
    { "type": "QUALITY_IMPROVEMENT", "message": "대화 깊이가 지난달 대비 향상되었어요." }
  ]
}
// Error 404 PERSON_NOT_FOUND
```

---

## 5.45 Smart Contact Reminders (v5.5)

AI가 대화 패턴/빈도 목표/마지막 연락일을 분석하여 능동적으로 연락 리마인더를 생성. 사용자 설정에 따라 자동/수동 모드.

### GET /api/reminders/smart

AI가 생성한 스마트 리마인더 목록 조회.

```
Query: ?status=pending|dismissed|completed&limit=20&offset=0
Headers: Authorization: Bearer {JWT}
```

```json
// Response 200
{
  "reminders": [
    {
      "id": 1,
      "personId": 3,
      "personName": "민수",
      "reason": "FREQUENCY_GAP",
      "message": "민수에게 마지막으로 연락한 지 12일이 지났어요. 안부를 물어보는 건 어떨까요?",
      "suggestedTopics": ["최근 이직 준비", "주말 계획"],
      "priority": "HIGH",
      "status": "pending",
      "createdAt": "2026-04-26T09:00:00Z",
      "dueDate": "2026-04-27T00:00:00Z"
    }
  ],
  "total": 5,
  "limit": 20,
  "offset": 0
}
```

### PATCH /api/reminders/smart/{id}

리마인더 상태 변경 (완료/무시).

```json
// Request
{ "status": "completed" | "dismissed" }
// Response 200
{
  "id": 1,
  "status": "completed",
  "updatedAt": "2026-04-26T10:30:00Z"
}
// Error 404 REMINDER_NOT_FOUND
// Error 400 VALIDATION_ERROR — 잘못된 status
```

### PUT /api/reminders/smart/settings

스마트 리마인더 설정.

```json
// Request
{
  "enabled": true,
  "maxRemindersPerDay": 5,
  "quietHoursStart": "22:00",
  "quietHoursEnd": "08:00",
  "minDaysBetweenReminders": 3
}
// Response 200 — 설정 그대로 반환
```

### GET /api/reminders/smart/settings

```json
// Response 200
{
  "enabled": true,
  "maxRemindersPerDay": 5,
  "quietHoursStart": "22:00",
  "quietHoursEnd": "08:00",
  "minDaysBetweenReminders": 3
}
```

**리마인더 생성 트리거 (서버 내부 로직)**:
- `FREQUENCY_GAP`: 빈도 목표 대비 연락 부족
- `MILESTONE_APPROACHING`: 기념일/이정표 접근
- `MOOD_DROP`: 최근 대화 감정 하락 감지
- `LONG_SILENCE`: 30일+ 무연락

---

## 5.46 Conversation Templates (v5.6)

상황별 대화 시작 템플릿. AI가 관계 맥락 + 최근 대화를 분석하여 인물별 맞춤 템플릿 제공.

### GET /api/templates/conversation

```
Query: ?personId={optional}&category=congratulation|comfort|gratitude|catchup|apology&limit=5
Headers: Authorization: Bearer {JWT}
```

```json
// Response 200
{
  "templates": [
    {
      "id": 1,
      "category": "catchup",
      "personId": 3,
      "personName": "민수",
      "title": "근황 물어보기",
      "message": "민수야, 요즘 이직 준비는 잘 되고 있어? 저번에 면접 본다고 했는데 결과 어떻게 됐어?",
      "context": "2주 전 이직 면접 이야기를 나눔",
      "confidence": 0.85
    }
  ],
  "categories": ["congratulation", "comfort", "gratitude", "catchup", "apology"]
}
```

### POST /api/templates/conversation/{id}/use

템플릿 사용 기록 (AI 추천 개선용).

```json
// Request
{ "used": true, "feedback": "helpful" | "not_relevant" | "too_formal" }
// Response 200
{ "id": 1, "usedAt": "2026-04-26T10:00:00Z" }
// Error 404 TEMPLATE_NOT_FOUND
```

---

## 5.47 People Comparison (v5.7)

두 관계인 간 소통 패턴 비교 인사이트. 대화 빈도, 감정, 토픽, 품질을 시각적으로 비교.

### GET /api/people/compare

```
Query: ?personId1={id}&personId2={id}&period=monthly&date=2026-04
Headers: Authorization: Bearer {JWT}
```

```json
// Response 200
{
  "period": "monthly",
  "startDate": "2026-04-01",
  "endDate": "2026-04-30",
  "person1": {
    "personId": 1,
    "personName": "엄마",
    "conversationCount": 15,
    "averageMoodScore": 8.2,
    "qualityScore": 8.5,
    "topTopics": ["건강", "여행", "식사"],
    "responseTime": "within_hours",
    "initiatedByMe": 60
  },
  "person2": {
    "personId": 3,
    "personName": "민수",
    "conversationCount": 8,
    "averageMoodScore": 7.0,
    "qualityScore": 7.2,
    "topTopics": ["이직", "게임", "운동"],
    "responseTime": "within_days",
    "initiatedByMe": 40
  },
  "comparison": {
    "moreFrequent": "person1",
    "higherMood": "person1",
    "higherQuality": "person1",
    "commonTopics": ["운동"],
    "insights": [
      {
        "type": "FREQUENCY_GAP",
        "message": "엄마와는 민수보다 2배 더 자주 대화해요."
      },
      {
        "type": "TOPIC_DIVERSITY",
        "message": "민수와는 대화 주제가 더 다양해요."
      }
    ]
  }
}
// Error 400 VALIDATION_ERROR — personId1 == personId2, 잘못된 period
// Error 404 PERSON_NOT_FOUND — personId1 또는 personId2 없음
```

---

## 5.48 Data Export (v5.8)

사용자의 전체 데이터를 JSON으로 내보내기 (GDPR data portability 대응).

### POST /api/account/export
데이터 내보내기 요청. 비동기 처리 후 다운로드 URL 반환.
```json
// Request
{
  "sections": ["people", "memories", "chats", "settings"]  // optional, 기본 전체
}
// Response 202
{
  "exportId": "exp_abc123",
  "status": "PROCESSING",
  "requestedAt": "2026-05-02T10:00:00Z"
}
// Error 429
{ "error": "이미 진행 중인 내보내기가 있습니다.", "code": "EXPORT_IN_PROGRESS" }
```

### GET /api/account/export/{exportId}
내보내기 상태 조회 + 다운로드.
```json
// Response 200 (진행 중)
{
  "exportId": "exp_abc123",
  "status": "PROCESSING",
  "progress": 65,
  "requestedAt": "2026-05-02T10:00:00Z"
}
// Response 200 (완료)
{
  "exportId": "exp_abc123",
  "status": "COMPLETED",
  "progress": 100,
  "requestedAt": "2026-05-02T10:00:00Z",
  "completedAt": "2026-05-02T10:00:15Z",
  "downloadUrl": "/api/account/export/exp_abc123/download",
  "expiresAt": "2026-05-02T11:00:00Z",
  "fileSizeBytes": 524288
}
```

### GET /api/account/export/{exportId}/download
실제 JSON 파일 다운로드.
```json
// Response 200 (Content-Type: application/json, Content-Disposition: attachment)
{
  "exportedAt": "2026-05-02T10:00:15Z",
  "user": { "userId": 1, "email": "...", "nickname": "..." },
  "people": [ { "id": 1, "name": "...", "relationship": "...", ... } ],
  "memories": [ { "id": 1, "content": "...", "category": "...", ... } ],
  "chats": [ { "id": 1, "userMessage": "...", "aiResponse": "...", ... } ],
  "settings": { "theme": "...", "language": "...", ... }
}
// Error 404
{ "error": "내보내기를 찾을 수 없습니다.", "code": "EXPORT_NOT_FOUND" }
// Error 410
{ "error": "다운로드 기한이 만료되었습니다.", "code": "EXPORT_EXPIRED" }
```

---

## 5.49 Contact Import (v5.9)

전화번호부 연락처를 People로 일괄 등록. 중복 감지 포함.

### POST /api/people/import
```json
// Request
{
  "contacts": [
    {
      "name": "김철수",
      "phone": "010-1234-5678",
      "email": "cs@example.com",
      "relationship": "친구",
      "note": "대학 동기"
    },
    {
      "name": "이영희",
      "phone": "010-9876-5432"
    }
  ]
}
// Response 200
{
  "total": 2,
  "created": 1,
  "skipped": 1,
  "results": [
    { "name": "김철수", "status": "CREATED", "personId": 15 },
    { "name": "이영희", "status": "SKIPPED", "reason": "DUPLICATE_NAME", "existingPersonId": 3 }
  ]
}
// Error 400
{ "error": "연락처 목록이 비어있습니다.", "code": "EMPTY_CONTACTS" }
{ "error": "한 번에 최대 100명까지 등록 가능합니다.", "code": "IMPORT_LIMIT_EXCEEDED" }
```

**중복 판정 기준**: name이 기존 People과 정확히 일치하면 SKIPPED. phone/email 일치도 SKIPPED.

### POST /api/people/import/preview
등록 전 미리보기 (중복 확인). body 필요하므로 POST 사용.
```json
// Request (same body as POST /api/people/import)
// Response 200
{
  "total": 2,
  "wouldCreate": 1,
  "wouldSkip": 1,
  "preview": [
    { "name": "김철수", "action": "CREATE" },
    { "name": "이영희", "action": "SKIP", "reason": "DUPLICATE_NAME", "existingPersonId": 3 }
  ]
}
```

---

## 5.50 Calendar Integration (v6.0)

기념일, 스마트 리마인더를 .ics (iCalendar) 형식으로 내보내기.

### GET /api/calendar/export
```
// Response 200 (Content-Type: text/calendar; charset=utf-8)
// Content-Disposition: attachment; filename="aidy-calendar.ics"
BEGIN:VCALENDAR
VERSION:2.0
PRODID:-//Aidy//Calendar//KO
...
END:VCALENDAR
```

### GET /api/calendar/events
JSON으로 캘린더 이벤트 목록 조회.
```json
// Query: ?from=2026-05-01&to=2026-06-01&type=anniversary,reminder
// Response 200
{
  "events": [
    {
      "id": "evt_1",
      "type": "ANNIVERSARY",
      "title": "김철수 생일",
      "date": "2026-05-15",
      "recurring": true,
      "personId": 1,
      "personName": "김철수",
      "sourceId": 5,
      "sourceType": "anniversary_reminder"
    },
    {
      "id": "evt_2",
      "type": "REMINDER",
      "title": "이영희에게 연락하기",
      "date": "2026-05-10",
      "recurring": false,
      "personId": 3,
      "personName": "이영희",
      "sourceId": 12,
      "sourceType": "smart_reminder"
    }
  ],
  "total": 2
}
// Error 400
{ "error": "날짜 범위가 올바르지 않습니다.", "code": "INVALID_DATE_RANGE" }
```

### POST /api/calendar/subscribe
캘린더 구독 URL 생성 (토큰 기반, 외부 캘린더 앱에서 구독).
```json
// Response 201
{
  "subscriptionUrl": "/api/calendar/feed/{feedToken}",
  "feedToken": "feed_xyz789",
  "createdAt": "2026-05-02T10:00:00Z"
}
```

### GET /api/calendar/feed/{feedToken}
외부 캘린더 앱용 .ics 피드 (인증 불필요, 토큰으로 접근).
```
// Response 200 (Content-Type: text/calendar)
// 인증 헤더 불필요 — feedToken이 인증 역할
BEGIN:VCALENDAR
...
END:VCALENDAR
```

### DELETE /api/calendar/subscribe
구독 URL 무효화.
```json
// Response 204 (No Content)
// Error 404
{ "error": "구독 정보가 없습니다.", "code": "SUBSCRIPTION_NOT_FOUND" }
```

---

## 5.51 Favorite People (v6.1)

인물 즐겨찾기 마킹 + 즐겨찾기 필터링.

### POST /api/people/{personId}/favorite
즐겨찾기 토글.
```json
// Response 200
{
  "personId": 1,
  "favorited": true
}
```

### GET /api/people/favorites
즐겨찾기 인물 목록.
```json
// Response 200
{
  "favorites": [
    {
      "personId": 1,
      "name": "김철수",
      "relationship": "친구",
      "favoritedAt": "2026-05-02T10:00:00Z"
    }
  ],
  "total": 1
}
```

### DELETE /api/people/{personId}/favorite
즐겨찾기 해제.
```json
// Response 204 (No Content)
// Error 404
{ "error": "즐겨찾기가 설정되지 않았습니다.", "code": "FAVORITE_NOT_FOUND" }
```

---

## 5.52 Conversation Summary (v6.2)

대화 자동 요약 생성 + 조회. AI가 최근 대화를 분석하여 핵심 요약 생성.

### POST /api/chat/summary
현재까지의 대화 요약 생성 요청.
```json
// Request
{
  "messageCount": 20  // optional, 기본 최근 20개 메시지
}
// Response 201
{
  "summaryId": 1,
  "summary": "김철수와의 생일 선물 논의. 운동 취미 관련 대화. 주말 약속 확인.",
  "messageRange": {
    "from": "2026-04-28T09:00:00Z",
    "to": "2026-05-02T10:00:00Z",
    "count": 20
  },
  "createdAt": "2026-05-02T10:00:00Z"
}
```

### GET /api/chat/summaries
요약 목록 조회.
```json
// Query: ?limit=10&offset=0
// Response 200
{
  "summaries": [
    {
      "summaryId": 1,
      "summary": "김철수와의 생일 선물 논의...",
      "messageRange": {
        "from": "2026-04-28T09:00:00Z",
        "to": "2026-05-02T10:00:00Z",
        "count": 20
      },
      "createdAt": "2026-05-02T10:00:00Z"
    }
  ],
  "total": 5
}
```

### DELETE /api/chat/summaries/{summaryId}
요약 삭제.
```json
// Response 204 (No Content)
// Error 404
{ "error": "요약을 찾을 수 없습니다.", "code": "SUMMARY_NOT_FOUND" }
```

---

## 5.53 Push Notification Delivery (v7.0)

실제 푸시 알림 발송 파이프라인. 등록된 디바이스 토큰(v1.1)으로 FCM/APNs 발송.

### POST /api/notifications/send
관리자/시스템용 — 특정 사용자에게 푸시 발송 (내부 이벤트 트리거).
```json
// Request
{
  "userId": 1,
  "title": "Aidy 알림",
  "body": "엄마에게 연락한 지 7일이 지났어요",
  "type": "NUDGE",           // NUDGE | REMINDER | DIGEST | ANNIVERSARY | GOAL
  "data": {                  // 딥링크 페이로드 (선택)
    "screen": "person_detail",
    "personId": 5
  }
}
// Response 200
{
  "notificationId": "uuid-string",
  "delivered": true,
  "platform": "FCM"          // FCM | APNS
}
// Error 404
{ "error": "디바이스 토큰이 등록되지 않았습니다.", "code": "NO_DEVICE_TOKEN" }
```

### GET /api/notifications/history
발송 이력 조회.
```json
// Query: ?page=0&size=20&type=NUDGE (선택)
// Response 200
{
  "notifications": [
    {
      "id": "uuid-string",
      "title": "Aidy 알림",
      "body": "엄마에게 연락한 지 7일이 지났어요",
      "type": "NUDGE",
      "delivered": true,
      "read": false,
      "createdAt": "2026-05-05T10:00:00Z"
    }
  ],
  "page": 0,
  "totalPages": 3,
  "totalElements": 52
}
```

### PATCH /api/notifications/{notificationId}/read
알림 읽음 처리.
```json
// Response 200
{ "id": "uuid-string", "read": true }
// Error 404
{ "error": "알림을 찾을 수 없습니다.", "code": "NOTIFICATION_NOT_FOUND" }
```

### POST /api/notifications/test
디바이스 토큰 유효성 테스트 푸시 발송.
```json
// Response 200
{ "success": true, "message": "테스트 알림이 발송되었습니다." }
// Error 400
{ "error": "디바이스 토큰이 유효하지 않습니다.", "code": "INVALID_DEVICE_TOKEN" }
```

---

## 5.54 Relationship Goals (v7.1)

인물별 커스텀 관계 목표 설정 + 진척 추적. (빈도 목표 v5.1 확장)

### POST /api/people/{personId}/goals
```json
// Request
{
  "title": "매주 전화하기",
  "description": "일요일마다 안부 전화",
  "type": "RECURRING",          // RECURRING | ONE_TIME | MILESTONE
  "frequency": "WEEKLY",        // DAILY | WEEKLY | MONTHLY (RECURRING만)
  "targetDate": "2026-06-01",   // ONE_TIME/MILESTONE만
  "reminderEnabled": true
}
// Response 201
{
  "id": 1,
  "personId": 5,
  "title": "매주 전화하기",
  "description": "일요일마다 안부 전화",
  "type": "RECURRING",
  "frequency": "WEEKLY",
  "targetDate": null,
  "reminderEnabled": true,
  "streak": 0,
  "completedCount": 0,
  "lastCompletedAt": null,
  "createdAt": "2026-05-05T10:00:00Z"
}
// Error 404
{ "error": "인물을 찾을 수 없습니다.", "code": "PERSON_NOT_FOUND" }
```

### GET /api/people/{personId}/goals
```json
// Response 200
{
  "goals": [
    {
      "id": 1,
      "title": "매주 전화하기",
      "type": "RECURRING",
      "frequency": "WEEKLY",
      "streak": 3,
      "completedCount": 12,
      "lastCompletedAt": "2026-05-04T18:00:00Z",
      "isOverdue": false
    }
  ]
}
```

### POST /api/people/{personId}/goals/{goalId}/complete
목표 달성 기록.
```json
// Request (선택)
{ "note": "30분 통화, 건강 이야기" }
// Response 200
{
  "id": 1,
  "streak": 4,
  "completedCount": 13,
  "lastCompletedAt": "2026-05-05T18:00:00Z",
  "nextDueAt": "2026-05-12T00:00:00Z"
}
// Error 400
{ "error": "이미 오늘 완료된 목표입니다.", "code": "GOAL_ALREADY_COMPLETED_TODAY" }
```

### DELETE /api/people/{personId}/goals/{goalId}
```json
// Response 204 (No Content)
// Error 404
{ "error": "목표를 찾을 수 없습니다.", "code": "GOAL_NOT_FOUND" }
```

### GET /api/goals/summary
전체 목표 현황 대시보드.
```json
// Response 200
{
  "totalGoals": 8,
  "activeGoals": 6,
  "overdueGoals": 2,
  "totalStreak": 15,
  "topStreaks": [
    { "goalId": 1, "personName": "엄마", "title": "매주 전화하기", "streak": 12 }
  ],
  "overdueList": [
    { "goalId": 3, "personName": "민수", "title": "월 1회 만남", "overdueDays": 5 }
  ]
}
```

---

## 5.55 Memory Emotions (v7.2)

메모리에 감정 태깅 (AI 자동 + 수동 수정). 감정별 필터 + 트렌드 분석.

### GET /api/memories?emotion={emotion}
기존 memories 엔드포인트에 emotion 필터 추가.
```
감정 enum: JOY | GRATITUDE | LOVE | SADNESS | ANGER | ANXIETY | SURPRISE | NEUTRAL
```

### PATCH /api/memories/{id}/emotion
수동 감정 수정.
```json
// Request
{ "emotion": "GRATITUDE" }
// Response 200
{
  "id": 1,
  "emotion": "GRATITUDE",
  "previousEmotion": "JOY",
  "updatedAt": "2026-05-05T10:00:00Z"
}
// Error 400
{ "error": "유효하지 않은 감정입니다.", "code": "INVALID_EMOTION" }
```

### GET /api/memories/emotions/trend
감정 트렌드 분석.
```json
// Query: ?period=MONTHLY&months=6 (기본 6개월)
// Response 200
{
  "period": "MONTHLY",
  "trends": [
    {
      "month": "2026-05",
      "emotions": {
        "JOY": 12,
        "GRATITUDE": 8,
        "LOVE": 5,
        "SADNESS": 2,
        "NEUTRAL": 15
      },
      "dominantEmotion": "NEUTRAL",
      "totalMemories": 42
    }
  ],
  "overallDominant": "JOY",
  "emotionDiversity": 0.78
}
```

### GET /api/people/{personId}/emotions
인물별 감정 분포.
```json
// Response 200
{
  "personId": 5,
  "personName": "엄마",
  "emotions": {
    "LOVE": 25,
    "GRATITUDE": 18,
    "JOY": 15,
    "ANXIETY": 3
  },
  "dominantEmotion": "LOVE",
  "recentTrend": "POSITIVE"    // POSITIVE | NEGATIVE | STABLE
}
```

---

## 5.56 AI Chat Personas (v7.3)

인물별 AI 대화 스타일 설정. AI가 다른 톤으로 응답.

### GET /api/personas
사용 가능한 페르소나 목록.
```json
// Response 200
{
  "personas": [
    {
      "id": "empathetic",
      "name": "공감형 리스너",
      "description": "감정에 집중하며 공감적으로 대화합니다",
      "traits": ["공감", "경청", "위로"]
    },
    {
      "id": "analytical",
      "name": "분석형 조언자",
      "description": "객관적으로 상황을 분석하고 해결책을 제시합니다",
      "traits": ["논리적", "직접적", "솔루션"]
    },
    {
      "id": "cheerful",
      "name": "밝은 응원단",
      "description": "긍정적 에너지로 격려하며 대화합니다",
      "traits": ["긍정", "격려", "유머"]
    },
    {
      "id": "reflective",
      "name": "성찰 가이드",
      "description": "깊은 질문으로 자기 성찰을 돕습니다",
      "traits": ["질문", "성찰", "깊이"]
    },
    {
      "id": "default",
      "name": "기본",
      "description": "균형 잡힌 기본 대화 스타일",
      "traits": ["균형", "자연스러움"]
    }
  ]
}
```

### PUT /api/chat/persona
전체 기본 페르소나 설정.
```json
// Request
{ "personaId": "empathetic" }
// Response 200
{ "personaId": "empathetic", "name": "공감형 리스너" }
// Error 400
{ "error": "존재하지 않는 페르소나입니다.", "code": "INVALID_PERSONA" }
```

### PUT /api/people/{personId}/persona
인물별 페르소나 오버라이드.
```json
// Request
{ "personaId": "analytical" }
// Response 200
{
  "personId": 5,
  "personName": "엄마",
  "personaId": "analytical",
  "personaName": "분석형 조언자"
}
```

### DELETE /api/people/{personId}/persona
인물별 오버라이드 제거 (기본으로 복귀).
```json
// Response 204 (No Content)
```

---

## 5.57 Recurring Events (v7.4)

기념일 시스템 확장 — 반복 이벤트 (매주/격주/매월/매년) CRUD + 리마인더 연동.

### POST /api/people/{personId}/events
```json
// Request
{
  "title": "가족 저녁",
  "description": "매주 일요일 가족 모임",
  "recurrence": "WEEKLY",       // WEEKLY | BIWEEKLY | MONTHLY | YEARLY | ONCE
  "dayOfWeek": "SUNDAY",        // WEEKLY/BIWEEKLY만 (MONDAY~SUNDAY)
  "dayOfMonth": null,           // MONTHLY만 (1~31)
  "date": null,                 // YEARLY/ONCE만 (MM-DD 또는 YYYY-MM-DD)
  "time": "18:00",              // HH:mm (선택)
  "reminderMinutes": 60,        // 이벤트 전 알림 (분, 선택)
  "color": "#4CAF50"            // 캘린더 색상 (선택)
}
// Response 201
{
  "id": 1,
  "personId": 5,
  "title": "가족 저녁",
  "description": "매주 일요일 가족 모임",
  "recurrence": "WEEKLY",
  "dayOfWeek": "SUNDAY",
  "dayOfMonth": null,
  "date": null,
  "time": "18:00",
  "reminderMinutes": 60,
  "color": "#4CAF50",
  "nextOccurrence": "2026-05-11T18:00:00Z",
  "createdAt": "2026-05-07T10:00:00Z"
}
// Error 404
{ "error": "인물을 찾을 수 없습니다.", "code": "PERSON_NOT_FOUND" }
```

### GET /api/people/{personId}/events
```json
// Response 200
{
  "events": [
    {
      "id": 1,
      "title": "가족 저녁",
      "recurrence": "WEEKLY",
      "nextOccurrence": "2026-05-11T18:00:00Z",
      "reminderMinutes": 60,
      "color": "#4CAF50"
    }
  ]
}
```

### GET /api/events/upcoming
전체 인물 대상 다가오는 이벤트 (7일 내).
```json
// Query: ?days=7 (기본 7)
// Response 200
{
  "events": [
    {
      "id": 1,
      "personId": 5,
      "personName": "엄마",
      "title": "가족 저녁",
      "occurrence": "2026-05-11T18:00:00Z",
      "recurrence": "WEEKLY",
      "color": "#4CAF50"
    }
  ]
}
```

### PUT /api/people/{personId}/events/{eventId}
```json
// Request — POST와 동일 구조
// Response 200 — POST 응답과 동일
// Error 404
{ "error": "이벤트를 찾을 수 없습니다.", "code": "EVENT_NOT_FOUND" }
```

### DELETE /api/people/{personId}/events/{eventId}
```json
// Response 204 (No Content)
```

---

## 5.58 Life Events (v7.5)

인물별 주요 생애 이벤트 기록. AI 대화 시 맥락으로 제공.

### POST /api/people/{personId}/life-events
```json
// Request
{
  "title": "이직",
  "description": "네이버에서 카카오로 이직",
  "category": "CAREER",         // CAREER | EDUCATION | FAMILY | HEALTH | RESIDENCE | RELATIONSHIP | OTHER
  "date": "2026-04-15",
  "impact": "POSITIVE"          // POSITIVE | NEGATIVE | NEUTRAL
}
// Response 201
{
  "id": 1,
  "personId": 5,
  "title": "이직",
  "description": "네이버에서 카카오로 이직",
  "category": "CAREER",
  "date": "2026-04-15",
  "impact": "POSITIVE",
  "createdAt": "2026-05-07T10:00:00Z"
}
```

### GET /api/people/{personId}/life-events
```json
// Query: ?category=CAREER (선택)
// Response 200
{
  "lifeEvents": [
    {
      "id": 1,
      "title": "이직",
      "category": "CAREER",
      "date": "2026-04-15",
      "impact": "POSITIVE"
    }
  ]
}
```

### PUT /api/people/{personId}/life-events/{eventId}
```json
// Request — POST와 동일
// Response 200
// Error 404
{ "error": "생애 이벤트를 찾을 수 없습니다.", "code": "LIFE_EVENT_NOT_FOUND" }
```

### DELETE /api/people/{personId}/life-events/{eventId}
```json
// Response 204 (No Content)
```

---

## 5.59 Conversation Coaching (v7.6)

채팅 중 AI가 대화 팁을 실시간 제안. 인물의 선호, 최근 이벤트, 감정 트렌드 기반.

### GET /api/chat/coaching/{personId}
해당 인물과의 대화에 활용할 코칭 팁.
```json
// Response 200
{
  "personId": 5,
  "personName": "엄마",
  "tips": [
    {
      "type": "TOPIC_SUGGEST",       // TOPIC_SUGGEST | TONE_ADVICE | AVOID_TOPIC | FOLLOW_UP | LIFE_EVENT
      "content": "최근 이직한 이야기를 물어보세요",
      "reason": "2주 전 카카오 이직 기록",
      "priority": "HIGH"            // HIGH | MEDIUM | LOW
    },
    {
      "type": "TONE_ADVICE",
      "content": "최근 불안감이 감지되었습니다. 공감적 톤으로 대화하세요",
      "reason": "최근 3개 메모리 감정: ANXIETY",
      "priority": "HIGH"
    },
    {
      "type": "FOLLOW_UP",
      "content": "지난주 '건강검진 예약' 이야기의 후속을 물어보세요",
      "reason": "미완료 메모리 감지",
      "priority": "MEDIUM"
    }
  ],
  "overallAdvice": "공감형 톤 추천, 최근 변화가 많은 시기",
  "generatedAt": "2026-05-07T10:00:00Z"
}
```

### POST /api/chat/coaching/{personId}/feedback
코칭 팁 유용성 피드백.
```json
// Request
{
  "tipType": "TOPIC_SUGGEST",
  "helpful": true
}
// Response 200
{ "recorded": true }
```

---

## 5.60 Relationship Forecast (v7.7)

AI가 현재 트렌드를 분석해 향후 30일 관계 건강 예측.

### GET /api/people/{personId}/forecast
```json
// Response 200
{
  "personId": 5,
  "personName": "엄마",
  "currentScore": 85,
  "forecastScore": 78,
  "trend": "DECLINING",           // IMPROVING | STABLE | DECLINING
  "confidence": 0.72,             // 0~1
  "factors": [
    {
      "factor": "연락 빈도 감소",
      "impact": -5,
      "suggestion": "이번 주 안에 전화하세요"
    },
    {
      "factor": "최근 긍정적 감정 메모리 증가",
      "impact": +3,
      "suggestion": null
    }
  ],
  "riskLevel": "LOW",             // LOW | MEDIUM | HIGH | CRITICAL
  "nextCheckDate": "2026-05-14",
  "generatedAt": "2026-05-07T10:00:00Z"
}
```

### GET /api/forecast/summary
전체 인물 예측 요약.
```json
// Response 200
{
  "forecasts": [
    {
      "personId": 5,
      "personName": "엄마",
      "currentScore": 85,
      "forecastScore": 78,
      "trend": "DECLINING",
      "riskLevel": "LOW"
    }
  ],
  "atRiskCount": 2,
  "improvingCount": 5,
  "stableCount": 8
}
```

---

## 8. Test Account (v4.6)

UI 테스트 전용 어드민 계정. 서버 시작 시 자동 시딩 (없으면 생성, 있으면 스킵).

### 테스트 계정 정보

```
email:    uitest@aidy.com
password: AidyTest2026!
nickname: Aidy 테스터
```

### 서버 시딩 조건
- `application.yml`의 `aidy.test-account.enabled: true` (기본 false, 테스트 프로파일에서만 true)
- 서버 시작 시 `ApplicationRunner`로 계정 존재 여부 확인 → 없으면 signup 로직 호출
- 프로덕션에서는 절대 시딩하지 않음

### 클라이언트 UITest 사용
- iOS: `UITestHelper`에서 이 계정으로 로그인
- Android: `UITestBase`에서 이 계정으로 로그인
- 하드코딩 OK (테스트 전용, 환경변수 불필요)

---

## 9. Health

### GET /api/health
```json
// Response 200
{ "status": "ok", "service": "aidy-server", "version": "1.0.0" }
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
| NO_DEVICE_TOKEN | 404 | 디바이스 토큰 미등록 | — |
| INVALID_DEVICE_TOKEN | 400 | 디바이스 토큰 유효하지 않음 | — |
| NOTIFICATION_NOT_FOUND | 404 | 알림 없음 | — |
| GOAL_NOT_FOUND | 404 | 목표 없음 | — |
| GOAL_ALREADY_COMPLETED_TODAY | 400 | 오늘 이미 완료된 목표 | — |
| INVALID_EMOTION | 400 | 유효하지 않은 감정 값 | — |
| INVALID_PERSONA | 400 | 존재하지 않는 페르소나 | — |
| EVENT_NOT_FOUND | 404 | 반복 이벤트 없음 | — |
| LIFE_EVENT_NOT_FOUND | 404 | 생애 이벤트 없음 | — |
| AI_TIMEOUT | 504 | AI 응답 시간 초과 | ✅ |
| CONNECTION_NOT_FOUND | 404 | 메모리 연결 없음 | — |
| CONNECTION_EXISTS | 409 | 메모리 연결 이미 존재 | — |
| ANNIVERSARY_NOT_FOUND | 404 | 기념일 없음 | — |
| NUDGE_NOT_FOUND | 404 | 넛지 없음 | — |
| NOTIFICATION_NOT_FOUND | 404 | 스마트 알림 없음 | — |
| LINK_EXISTS | 409 | 관계 연결 이미 존재 | — |
| LINK_NOT_FOUND | 404 | 관계 연결 없음 | — |
| INTERACTION_NOT_FOUND | 404 | 상호작용 기록 없음 | — |
| SHARE_NOT_FOUND | 404 | 공유 링크 없음/만료 | — |
| TAG_EXISTS | 409 | 태그 이름 중복 | — |
| TAG_NOT_FOUND | 404 | 태그 없음 | — |
| TAG_LIMIT_EXCEEDED | 400 | 메모리당 태그 5개 초과 | — |
| GROUP_EXISTS | 409 | 그룹 이름 중복 | — |
| GROUP_NOT_FOUND | 404 | 그룹 없음 | — |
| INVALID_EMOJI | 400 | 허용되지 않은 이모지 | — |
| REACTION_NOT_FOUND | 404 | 반응 없음 | — |
| HIGHLIGHT_NOT_FOUND | 404 | 하이라이트 없음 | — |
| NOT_ARCHIVED | 400 | 아카이브 상태가 아닌 메모리 | — |
| SUGGESTION_NOT_FOUND | 404 | 병합 제안 없음 | — |
| INVALID_KEEP_PERSON | 400 | keepPersonId가 제안에 속하지 않음 | — |
| INVALID_ONBOARDING_STEP | 400 | 유효하지 않은 온보딩 단계 | — |
| INVALID_MEDIA_TYPE | 400 | 지원하지 않는 미디어 파일 형식 | — |
| MEDIA_LIMIT_EXCEEDED | 400 | 메모리당 미디어 3개 초과 | — |
| MEDIA_TOO_LARGE | 400 | 파일 크기 5MB 초과 | — |
| MEDIA_NOT_FOUND | 404 | 미디어 없음 | — |
| INVALID_MOOD | 400 | 허용되지 않은 감정 값 | — |
| MILESTONE_NOT_FOUND | 404 | 이정표 없음 | — |
| EXPORT_IN_PROGRESS | 429 | 이미 진행 중인 내보내기 존재 | — |
| EXPORT_NOT_FOUND | 404 | 내보내기 없음 | — |
| EXPORT_EXPIRED | 410 | 다운로드 기한 만료 | — |
| EMPTY_CONTACTS | 400 | 연락처 목록 비어있음 | — |
| IMPORT_LIMIT_EXCEEDED | 400 | 일괄 등록 100명 초과 | — |
| INVALID_DATE_RANGE | 400 | 날짜 범위 오류 | — |
| SUBSCRIPTION_NOT_FOUND | 404 | 캘린더 구독 없음 | — |
| FAVORITE_NOT_FOUND | 404 | 즐겨찾기 없음 | — |
| SUMMARY_NOT_FOUND | 404 | 대화 요약 없음 | — |

**클라이언트 처리 규칙**:
- Retryable 코드(✅): 재시도 버튼 노출 권장 (사용자 재시도 허용)
- 401 UNAUTHORIZED: 자동 로그아웃 + 로그인 화면 이동 (ADR-006)
- 4xx NON_RETRYABLE: 토스트/알림만, 재시도 UI 감춤
- 5xx NON_RETRYABLE (INTERNAL_ERROR): 토스트 + 재시도 버튼은 선택적

---

## Rate Limit 헤더 (v0.9)

모든 rate-limited 응답에 다음 헤더를 포함:

```
X-RateLimit-Limit: 20          // 분당 최대 요청 수
X-RateLimit-Remaining: 15      // 남은 요청 수
X-RateLimit-Reset: 1714420800  // 리셋 Unix timestamp (초)
```

429 응답 시 추가:
```
Retry-After: 30                // 재시도까지 대기 초
```

**버킷별 제한:**
| 버킷 | RPM | 적용 엔드포인트 |
|-------|-----|-----------------|
| chat | 20 | /api/chat, /api/chat/stream |
| auth | 10 | /api/auth/* |

**클라이언트 처리:**
- 429 수신 시: `Retry-After` 초만큼 대기 후 재시도 버튼 활성화
- 남은 요청 0 접근 시: 선제적 UI 경고 (선택)

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
| v0.4.0 | 2026-04-17 | PATCH /api/auth/profile + POST /api/memories/{id}/pin 핀 토글 (autoceo-s13-R1) |
| v0.5.0 | 2026-04-17 | POST /api/memories/batch 일괄 작업 + GET /api/chat/stats 통계 (autoceo-s15-R1) |
| v0.6.0 | 2026-04-17 | GET /api/search 통합 검색 + PUT memories category 변경 허용 (autoceo-s16-R1) |
| v0.7.0 | 2026-04-17 | GET/PUT /api/settings + PUT /api/auth/password + DELETE /api/auth/account (autoceo-s17-R1~R2) |
| v0.8.0 | 2026-04-17 | Chat pagination + 전체 삭제 + Memory Insights (autoceo-s17-R3~R4) |
| v0.9.0 | 2026-04-18 | Rate limit 헤더 + Memory import + Chat summary (autoceo-s18-R2~R4) |
| v1.0.0 | 2026-04-18 | Memory timeline + Quick actions + 공유 + 알림 + App config + Tags (autoceo-s19) |
| v1.1.0 | 2026-04-18 | Notification token 등록/해제 (autoceo-s21-R4) |
| v1.2.0 | 2026-04-19 | People list + merge + edit (autoceo-s22-R1) |
| v1.3.0 | 2026-04-19 | Chat grouped history + User dashboard (autoceo-s22-R5) |
| v1.4.0 | 2026-04-19 | Chat bookmarks + AI feedback (autoceo-s23-R1) |
| v1.5.0 | 2026-04-19 | Chat topics + Chat export (autoceo-s23-R5) |
| v1.6.0 | 2026-04-19 | Memory smart review suggestions (autoceo-s24-R1) |
| v1.7.0 | 2026-04-19 | Chat sentiment tracking (autoceo-s24-R1) |
| v1.8.0 | 2026-04-19 | Weekly Summary report (autoceo-s24-R4) |
| v1.9.0 | 2026-04-19 | Memory Connections (autoceo-s24-R7) |
| v2.0.0 | 2026-04-19 | Relationship Health Score — 인물별 관계 건강 점수 (autoceo-s25-R1) |
| v2.1.0 | 2026-04-19 | Daily Digest — 일일 브리핑 (autoceo-s25-R1) |
| v2.2.0 | 2026-04-19 | Conversation Starters — 인물별 대화 주제 추천 (autoceo-s26-R1) |
| v2.3.0 | 2026-04-19 | Anniversary Reminders — 기념일 자동 감지 + CRUD (autoceo-s26-R1) |
| v2.4.0 | 2026-04-19 | Notification Preferences — 알림 유형별 세분화 설정 (autoceo-s26-R3) |
| v2.5.0 | 2026-04-19 | Relationship Nudges — AI 연락 제안 (autoceo-s26-R5) |
| v2.6.0 | 2026-04-19 | Gift Suggestions — AI 선물 추천 (autoceo-s26-R7) |
| v2.7.0 | 2026-04-19 | Relationship Timeline — 인물별 상호작용 통합 타임라인 (autoceo-s27-R1) |
| v2.8.0 | 2026-04-19 | Quick Notes — 채팅 없이 직접 메모리 생성 (autoceo-s27-R1) |
| v2.9.0 | 2026-04-21 | Smart Notifications — AI 스마트 알림 생성/조회/무시 (autoceo-s28-R1) |
| v3.0.0 | 2026-04-21 | Relationship Map — 인물 간 관계 그래프 (autoceo-s28-R1) |
| v3.1.0 | 2026-04-21 | Interaction Log — 수동 상호작용 기록 (autoceo-s28-R1) |
| v3.2.0 | 2026-04-21 | Shared Memories — 공유 링크로 메모리 외부 공유 (autoceo-s29-R1) |
| v3.3.0 | 2026-04-21 | Memory Tags — 사용자 정의 태그 분류 (autoceo-s29-R1) |
| v3.4.0 | 2026-04-21 | AI Chat Suggestions — 맥락 기반 대화 주제 추천 (autoceo-s29-R1) |
| v3.5.0 | 2026-04-21 | Memory Deduplication — AI 중복 메모리 탐지 + 병합 (autoceo-s30-R1) |
| v3.6.0 | 2026-04-21 | Chat Reactions — 메시지 이모지 반응 (autoceo-s30-R1) |
| v3.7.0 | 2026-04-21 | People Groups — 인물 그룹 분류 + AI 추천 (autoceo-s30-R1) |
| v3.8.0 | 2026-04-21 | Memory Highlights — AI 기간별 핵심 메모리 선별 (autoceo-s30-R1) |
| v3.9.0 | 2026-04-21 | Chat Context Memory — 대화 맥락 자동 요약 + 주입 (autoceo-s31-R1) |
| v4.0.0 | 2026-04-21 | Memory Archive — 오래된 메모리 아카이브 + 복원 (autoceo-s31-R1) |
| v4.1.0 | 2026-04-21 | People Merge Suggestions — AI 중복 인물 탐지 + 병합 (autoceo-s31-R1) |
| v4.2.0 | 2026-04-21 | Chat Export — 대화 내역 텍스트/JSON 내보내기 (autoceo-s31-R1) |
| v4.3.0 | 2026-04-21 | Onboarding Progress — 첫 사용자 튜토리얼 진행률 추적 (autoceo-s32-R1) |
| v4.4.0 | 2026-04-21 | Home Dashboard — 메인 화면 통합 브리핑 (autoceo-s32-R1) |
| v4.5.0 | 2026-04-21 | Memory Media — 메모리 이미지 첨부 (autoceo-s32-R1) |
| v4.6.0 | 2026-04-22 | Test Account — UI 테스트 전용 어드민 계정 시딩 (ingest) |
| v4.7.0 | 2026-04-24 | User Avatar — 프로필 사진 업로드/조회/삭제 (autoceo-s34-R1) |
| v4.8.0 | 2026-04-24 | Advanced Search Filters — 날짜/인물/카테고리/타입 복합 필터 (autoceo-s34-R1) |
| v4.9.0 | 2026-04-24 | Activity Heatmap — 월간/연간 활동 히트맵 데이터 (autoceo-s34-R1) |
| v5.0.0 | 2026-04-25 | Mood Tracking — 대화 감정 태깅 + 트렌드 (autoceo-s35-R1) |
| v5.1.0 | 2026-04-25 | Contact Frequency Goals — 연락 빈도 목표 + 달성 현황 (autoceo-s35-R1) |
| v5.2.0 | 2026-04-25 | Communication Quality Score — AI 소통 품질 분석 (autoceo-s35-R1) |
| v5.3.0 | 2026-04-25 | Relationship Milestones — 관계 이정표 자동 감지 (autoceo-s35-R1) |
| v5.4.0 | 2026-04-26 | Relationship Report — 월간/주간 관계 종합 리포트 (autoceo-s36-R1) |
| v5.5.0 | 2026-04-26 | Smart Contact Reminders — AI 능동적 연락 리마인더 (autoceo-s36-R1) |
| v5.6.0 | 2026-04-26 | Conversation Templates — 상황별 맞춤 대화 시작 템플릿 (autoceo-s36-R1) |
| v5.7.0 | 2026-04-26 | People Comparison — 두 관계인 소통 패턴 비교 인사이트 (autoceo-s36-R1) |
| v5.8.0 | 2026-05-02 | Data Export — 전체 사용자 데이터 JSON 내보내기 (autoceo-s37-R1) |
| v5.9.0 | 2026-05-02 | Contact Import — 전화번호부 일괄 People 등록 (autoceo-s37-R1) |
| v6.0.0 | 2026-05-02 | Calendar Integration — 기념일/리마인더 .ics 캘린더 내보내기+구독 (autoceo-s37-R1) |
| v6.1.0 | 2026-05-02 | Favorite People — 인물 즐겨찾기 마킹+필터링 (autoceo-s38-R1) |
| v6.2.0 | 2026-05-02 | Conversation Summary — AI 대화 자동 요약 생성+조회 (autoceo-s38-R1) |
| v7.0.0 | 2026-05-05 | Push Notification Delivery — 실제 푸시 발송 파이프라인 + 이력 (autoceo-s40-R1) |
| v7.1.0 | 2026-05-05 | Relationship Goals — 인물별 커스텀 목표 + 진척 추적 (autoceo-s40-R1) |
| v7.2.0 | 2026-05-05 | Memory Emotions — 감정 태깅 + 트렌드 분석 (autoceo-s40-R1) |
| v7.3.0 | 2026-05-05 | AI Chat Personas — 인물별 AI 대화 스타일 설정 (autoceo-s40-R1) |
| v7.4.0 | 2026-05-07 | Recurring Events — 반복 이벤트 CRUD + 리마인더 (autoceo-s41-R1) |
| v7.5.0 | 2026-05-07 | Life Events — 인물별 생애 이벤트 추적 (autoceo-s41-R1) |
| v7.6.0 | 2026-05-07 | Conversation Coaching — AI 실시간 대화 코칭 팁 (autoceo-s41-R1) |
| v7.7.0 | 2026-05-07 | Relationship Forecast — AI 관계 건강 예측 (autoceo-s41-R1) |
