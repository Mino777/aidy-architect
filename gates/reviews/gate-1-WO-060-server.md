# Gate 1 검증: WO-060 Chat Topics + Export (v1.5)

**대상**: aidy-server  
**검증 일시**: 2026-04-19  
**최근 커밋**: e52d1dc [R6-server] feat: Chat Topics + Export (v1.5)

---

## 1. API 엔드포인트 검증

### GET /api/chat/topics (v1.5)

**스펙 (api-contract.md:420-444)**:
```
Method: GET
Path: /api/chat/topics
Query: ?days=7 (optional, default 7, max 30)
Response 200:
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

**구현** (ChatController.kt:139-145):
```kotlin
@GetMapping("/topics")
fun topics(
    @RequestParam(required = false, defaultValue = "7") days: Int,
): ResponseEntity<ChatTopicsResponse> {
    if (days <= 0 || days > 30) throw ApiException(ErrorCode.VALIDATION_ERROR)
    return ResponseEntity.ok(chatTopicsService.getTopics(currentUserId(), days))
}
```

**검증**:
- ✅ 엔드포인트 경로: `/api/chat/topics`
- ✅ HTTP method: GET
- ✅ Query parameter: `days` (required=false, defaultValue="7")
- ✅ Validation: `days <= 0 || days > 30` → 400 VALIDATION_ERROR
- ✅ Response body: ChatTopicsResponse (days, topics[], totalMessages)

**DTO 필드 대조** (ChatRequest.kt:244-257):
```kotlin
data class ChatTopicsResponse(
    val days: Int,
    val topics: List<ChatTopicItem>,
    val totalMessages: Int,
)

data class ChatTopicItem(
    val title: String,
    val messageCount: Int,
    val firstMessageAt: String?,
    val lastMessageAt: String?,
    val keywords: List<String>,
    val sampleMessageId: Long?,
)
```

- ✅ 모든 필드명/타입 스펙과 일치
- ✅ keywords는 최대 3개 (AiService.kt:506에서 `take(3)`)
- ✅ sampleMessageId는 Long (메시지 ID 참조)

**서비스 로직 분석** (ChatTopicsService.kt:23-66):

```kotlin
// Line 31-32: 조건 기간 내 메시지 조회
val since = Instant.now().minus(Duration.ofDays(days.toLong()))
val messages = chatMessageRepository.findByUserIdAndCreatedAtAfterOrderByCreatedAtAsc(userId, since)

// Line 47-56: Topic 응답 생성
val topicItems = aiResult.topics.map { topic ->
    val sampleMsg = topic.sampleMessageId?.let { messagesByTime[it] }
    ChatTopicItem(
        title = topic.title,
        messageCount = topic.messageCount,
        firstMessageAt = sampleMsg?.createdAt?.toString(),
        lastMessageAt = sampleMsg?.createdAt?.toString(),  // <- ISSUE
        keywords = topic.keywords,
        sampleMessageId = topic.sampleMessageId,
    )
}
```

**발견 사항**:
- 🔴 **Critical**: Line 52-53에서 firstMessageAt과 lastMessageAt이 동일한 sampleMsg의 createdAt을 사용
  - 스펙: firstMessageAt은 주제 범위의 최소 시각, lastMessageAt은 최대 시각
  - 구현: 둘 다 sampleMessageId 1개의 시각만 사용 → 항상 같은 값
  - 예: firstMessageAt="2026-04-15T09:00:00Z", lastMessageAt="2026-04-15T09:00:00Z" (같음)
  - 스펙 예시: firstMessageAt="2026-04-15T09:00:00Z", lastMessageAt="2026-04-19T14:00:00Z" (범위)

**근본 원인**:
- AiService.extractTopics()에서 반환하는 TopicItem(AiService.kt:452-461)이 firstMessageAt/lastMessageAt을 포함하지 않음
- ChatTopicsService는 AI 응답을 받은 후 topic.messageIds 정보 없이 sampleMessageId 1개로만 시간 범위 계산 불가능

---

### GET /api/chat/export (v1.5)

**스펙 (api-contract.md:446-477)**:
```
Method: GET
Path: /api/chat/export
Query: ?format=text|json (default "text"), ?days=30 (default 30, max 365)
Response 200 (text):
  Content-Type: text/plain; charset=utf-8
  Content-Disposition: attachment; filename="aidy-chat-export-2026-04-19.txt"
  [2026-04-19 10:00] 나: 오늘 점심 뭐 먹었어
  [2026-04-19 10:00] Aidy: 점심 기록을 도와드릴게요!

Response 200 (json):
  Content-Type: application/json
  {
    "exportedAt": "2026-04-19T12:00:00Z",
    "days": 30,
    "messageCount": 128,
    "messages": [...]
  }
```

**구현** (ChatController.kt:147-174):
```kotlin
@GetMapping("/export")
fun export(
    @RequestParam(required = false, defaultValue = "text") format: String,
    @RequestParam(required = false, defaultValue = "30") days: Int,
): ResponseEntity<*> {
    if (days <= 0 || days > 365) throw ApiException(ErrorCode.VALIDATION_ERROR)
    if (format !in listOf("text", "json")) throw ApiException(ErrorCode.VALIDATION_ERROR)

    val userId = currentUserId()
    val today = java.time.LocalDate.now(java.time.ZoneOffset.UTC).toString()

    return when (format) {
        "json" -> {
            val result = chatExportService.exportAsJson(userId, days)
            ResponseEntity.ok()
                .contentType(MediaType.APPLICATION_JSON)
                .header("Content-Disposition", "attachment; filename=\"aidy-chat-export-$today.json\"")
                .body(result)
        }
        else -> {
            val text = chatExportService.exportAsText(userId, days)
            ResponseEntity.ok()
                .contentType(MediaType.parseMediaType("text/plain; charset=utf-8"))
                .header("Content-Disposition", "attachment; filename=\"aidy-chat-export-$today.txt\"")
                .body(text)
        }
    }
}
```

**검증**:
- ✅ 엔드포인트 경로: `/api/chat/export`
- ✅ HTTP method: GET
- ✅ Query parameters: `format` (default="text"), `days` (default="30")
- ✅ Validation: `days <= 0 || days > 365` → 400 VALIDATION_ERROR
- ✅ Validation: `format !in listOf("text", "json")` → 400 VALIDATION_ERROR
- ✅ Content-Type (text): `text/plain; charset=utf-8`
- ✅ Content-Type (json): `application/json`
- ✅ Content-Disposition: `attachment; filename="aidy-chat-export-{YYYY-MM-DD}.{ext}"`

**DTO** (ChatRequest.kt:259-270):
```kotlin
data class ChatExportJsonResponse(
    val exportedAt: String,
    val days: Int,
    val messageCount: Int,
    val messages: List<ChatExportMessage>,
)

data class ChatExportMessage(
    val role: String,
    val content: String,
    val createdAt: String,
)
```

- ✅ JSON 필드명/타입 스펙과 일치

**서비스 로직** (ChatExportService.kt:20-49):
```kotlin
fun exportAsText(userId: Long, days: Int): String {
    val messages = getMessages(userId, days)
    if (messages.isEmpty()) return ""
    return messages.joinToString("\n") { msg ->
        val ts = displayFormatter.format(msg.createdAt)
        val role = if (msg.role == ChatMessage.Role.USER) "나" else "Aidy"
        "[$ts] $role: ${msg.content}"
    }
}

fun exportAsJson(userId: Long, days: Int): ChatExportJsonResponse {
    val messages = getMessages(userId, days)
    return ChatExportJsonResponse(
        exportedAt = Instant.now().toString(),
        days = days,
        messageCount = messages.size,
        messages = messages.map { msg ->
            ChatExportMessage(
                role = msg.role.name.lowercase(),
                content = msg.content,
                createdAt = msg.createdAt.toString(),
            )
        },
    )
}
```

**검증**:
- ✅ Text 포맷: `[yyyy-MM-dd HH:mm] 나/Aidy: content` (displayFormatter Line 17)
- ✅ JSON 포맷: exportedAt(ISO 8601), days, messageCount, messages[]
- ✅ Role 변환: USER → "user", ASSISTANT → "assistant" (lowercase)
- ✅ 메시지 없으면: text는 "", json은 empty messages[]
- ✅ 모든 필드명/타입 스펙과 정확히 일치

---

## 2. 에러 처리 검증

**스펙 에러 코드** (api-contract.md:1195-1216):
```
VALIDATION_ERROR | 400 — 요청 필드 검증 실패
UNAUTHORIZED    | 401 — 인증 필요 / 토큰 만료
```

**구현**:
- ✅ days <= 0 || days > 30: VALIDATION_ERROR (topics)
- ✅ days <= 0 || days > 365: VALIDATION_ERROR (export)
- ✅ format not in ["text", "json"]: VALIDATION_ERROR (export)
- ✅ 인증 없음: UNAUTHORIZED (currentUserId() check)

---

## 3. 테스트 검증

**테스트 파일 & 커버리지**:

**ChatControllerTest** (lines 889-987):
- ✅ `GET /api/chat/topics - 정상 조회 200`
- ✅ `GET /api/chat/topics - days 0 이하 400`
- ✅ `GET /api/chat/topics - days 31 이상 400`
- ✅ `GET /api/chat/topics - 인증 없음 401`
- ✅ `GET /api/chat/export - text 기본 포맷 200`
- ✅ `GET /api/chat/export - json 포맷 200`
- ✅ `GET /api/chat/export - 잘못된 format 400`

**ChatTopicsServiceTest** (99 lines):
- ✅ `getTopics - 메시지 없으면 빈 topics 반환`
- ✅ `getTopics - AI 주제 추출 성공`
- ✅ `getTopics - 캐시 동작 확인 (같은 요청 시 AI 1회만 호출)`

**ChatExportServiceTest** (93 lines):
- ✅ `exportAsText - 메시지 없으면 빈 문자열`
- ✅ `exportAsText - 올바른 포맷으로 출력`
- ✅ `exportAsJson - 메시지 없으면 빈 배열`
- ✅ `exportAsJson - 메시지 포함 응답`

**테스트 실행 결과**:
```
Total test suites: 40+
Total tests executed: 582
Failures: 0
Errors: 0
Build: BUILD SUCCESSFUL ✅
```

- ✅ 신규 테스트 포함 전체 통과

**테스트 품질 평가**:
- ✅ Happy path (정상 조회) 테스트
- ✅ Boundary 테스트 (days=0, days=31, days=366 등)
- ✅ Auth 테스트 (인증 없음)
- ✅ Service layer 단위 테스트
- ⚠️ 문제점: firstMessageAt < lastMessageAt 검증 테스트 없음 (스펙 위반 미감지)

---

## 4. 보안 검증

**환경변수 검사**:
- ✅ API 키는 @Value("${aidy.ai.api-key}")로 주입 (default 없음, 필수)
- ✅ 에러 메시지에 내부 정보 노출 없음

**인증**:
- ✅ currentUserId() 체크 → UNAUTHORIZED
- ✅ 토큰 검증 (SecurityContextHolder)
- ✅ 권한 검증: 자신의 데이터만 접근 가능

---

## 5. 네이밍 & 컨벤션

**필드명 검증**:
- ✅ GET /api/chat/topics (camelCase: days)
- ✅ GET /api/chat/export (camelCase: format, days)
- ✅ DTO: ChatTopicsResponse, ChatTopicItem, ChatExportJsonResponse, ChatExportMessage (PascalCase)
- ✅ 필드: days, topics, totalMessages, messageCount, exportedAt (camelCase)

**Git 커밋**:
- ⚠️ 메시지: "[R6-server] feat: Chat Topics + Export (v1.5)" (한글 아님) - CLAUDE.md 규칙상 한글 권장

---

## 6. 상세 문제 분석

### Critical Issue: firstMessageAt/lastMessageAt 스펙 위반

**스펙 요구 (api-contract.md:429-436)**:
```json
{
  "firstMessageAt": "2026-04-15T09:00:00Z",  // 주제의 첫 메시지 시각
  "lastMessageAt": "2026-04-19T14:00:00Z",   // 주제의 마지막 메시지 시각
  "sampleMessageId": 42                       // 대표 메시지 ID
}
```

**의도**:
- firstMessageAt/lastMessageAt: 주제의 시간 범위를 나타냄
- sampleMessageId: 그 주제의 대표 메시지 (클라이언트가 스크롤링용으로 사용)

**현재 구현** (ChatTopicsService.kt:52-53):
```kotlin
val sampleMsg = topic.sampleMessageId?.let { messagesByTime[it] }
firstMessageAt = sampleMsg?.createdAt?.toString(),
lastMessageAt = sampleMsg?.createdAt?.toString(),  // 문제: 둘 다 같은 값
```

**결과**:
- API 응답: `firstMessageAt="2026-04-15T09:00:00Z"`, `lastMessageAt="2026-04-15T09:00:00Z"` (동일)
- 클라이언트: 주제의 시간 범위를 정확히 알 수 없음
- 스펙 위반: API 응답이 스펙 예시와 다름

**근본 원인**:
- AiService.extractTopics()의 반환 타입(TopicItem)에 firstMessageAt/lastMessageAt 필드 없음
- AI 응답으로부터 주제별 메시지 범위를 추출할 수 없음
- ChatTopicsService는 sampleMessageId 1개만 알고 있어 시간 범위 계산 불가능

**해결 방안** (워커 선택):
1. **Option A (권장)**: AI 프롬프트 개선
   - AI가 각 주제의 messageIds (범위) 또는 firstMessageId/lastMessageId 반환
   - ChatTopicsService에서 해당 메시지들의 createdAt 조회 후 min/max 계산

2. **Option B**: 로컬 범위 계산
   - AI는 sampleMessageId만 반환 (현재와 동일)
   - ChatTopicsService에서 messagesByTime 맵을 순회하여 해당 주제에 속한 첫/마지막 메시지 추정

3. **Option C (임시)**: firstMessageAt/lastMessageAt 제거
   - 스펙 수정 (권장하지 않음, API 계약 위반)

---

## 판정 테이블

| 항목 | 결과 | 근거 |
|------|------|------|
| 엔드포인트 URL | ✅ PASS | `/api/chat/topics`, `/api/chat/export` 정확 |
| HTTP Method | ✅ PASS | GET 정확 |
| 쿼리 파라미터 | ✅ PASS | days, format 정확 |
| Response 스키마 (export) | ✅ PASS | 모든 필드명/타입 정확 |
| Response 스키마 (topics) | 🔴 FAIL | firstMessageAt/lastMessageAt 값 오류 |
| 에러 코드 | ✅ PASS | VALIDATION_ERROR, UNAUTHORIZED 정확 |
| 에러 처리 | ✅ PASS | Boundary validation 정확 |
| 테스트 전체 | ✅ PASS | 582건 통과 |
| 테스트 커버리지 | ⚠️ PARTIAL | firstMessageAt < lastMessageAt 검증 없음 |
| 보안 | ✅ PASS | API 키, 인증, 권한 검증 정확 |
| 컨벤션 | ✅ PASS (네이밍), ⚠️ (커밋 메시지) | |

---

## 최종 판정

### **FAIL** 🔴

**판정 사유**:

GET /api/chat/topics의 Response body 필드값이 스펙과 불일치:
- **스펙**: `firstMessageAt`과 `lastMessageAt`이 다른 값 (주제의 시간 범위)
- **구현**: 둘 다 동일한 값 (sampleMessageId 1개의 시각)

**스펙 위반 심각도**: **High**
- API 계약 위반 (JSON 응답이 스펙 예시와 다름)
- 클라이언트가 주제의 시간 범위를 파악할 수 없음
- 추후 클라이언트 구현 시 혼란 야기

**필수 수정 사항**:
1. AiService.extractTopics()의 TopicItem 구조 변경
   - messageIds 리스트 또는 firstMessageId/lastMessageId 포함

2. ChatTopicsService.getTopics()의 topic 변환 로직 수정
   - AI 응답에서 주제 범위 메시지 추출
   - firstMessageAt: min(createdAt), lastMessageAt: max(createdAt)

3. 테스트 추가
   ```kotlin
   @Test
   fun `getTopics - firstMessageAt < lastMessageAt 검증`()
   ```

**다음 액션**:
- 워커에게 수정 지시 (필수)
- 수정 후 Gate 1 재검증
- Gate 2로 진행 불가

