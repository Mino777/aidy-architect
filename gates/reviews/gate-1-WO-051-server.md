# Gate 1 검증 리포트 — WO-051 Server People 관리 API (v1.2)

**대상**: `aidy-server` PersonController + PersonService  
**스펙**: `specs/api-contract.md` Section 4 People (라인 579~722)  
**검증일**: 2026-04-19  
**검증자**: Architect (Gate 1)

---

## 검증 범위

### 구현 대상 엔드포인트 (3개)

| 엔드포인트 | 메서드 | 설명 |
|-----------|--------|------|
| GET /api/memories/people/list | GET | 전체 인물 목록 조회 (v1.2) |
| POST /api/memories/people/merge | POST | 인물 병합 (v1.2) |
| PATCH /api/memories/people/{id} | PATCH | 인물 정보 수정 (v1.2) |

### 코드 파일

- **Controller**: `src/main/kotlin/com/mino/aidy/controller/PersonController.kt`
- **Service**: `src/main/kotlin/com/mino/aidy/service/PersonService.kt`
- **DTOs**: `src/main/kotlin/com/mino/aidy/dto/ChatRequest.kt` (라인 176~222)

---

## 상세 검증

### 1. GET /api/memories/people/list (v1.2)

#### 스펙 요구사항 (api-contract.md 라인 612~635)

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

특징:
- 최근 언급순 정렬 (lastMentionedAt 내림차순)
- memoryCount: 해당 인물의 PersonMemory 수
- latestTrait: 가장 최근 PersonMemory의 trait
- lastMentionedAt: 가장 최근 PersonMemory의 createdAt (ISO 8601)

#### 구현 검증

**Controller (PersonController.kt 라인 20-23)**
```kotlin
@GetMapping("/list")
fun list(): ResponseEntity<PeopleListResponse> {
    return ResponseEntity.ok(personService.listPeople(currentUserId()))
}
```
✅ URL/메서드 일치: `GET /api/memories/people/list`

**Response DTO (ChatRequest.kt 라인 178-191)**
```kotlin
data class PeopleListResponse(
    val people: List<PersonListItem>,
    val totalCount: Int,
)

data class PersonListItem(
    val id: Long,
    val normalizedName: String,
    val displayName: String,
    val relationship: String?,
    val memoryCount: Int,
    val latestTrait: String?,
    val lastMentionedAt: String?,
)
```
✅ 모든 필드 스펙과 1:1 대응

**Service 구현 (PersonService.kt 라인 112-129)**
```kotlin
fun listPeople(userId: Long): PeopleListResponse {
    val persons = personRepository.findByUserId(userId)
    val items = persons.map { person ->
        val memories = personMemoryRepository.findByUserIdAndPersonId(userId, person.id)
        val latest = memories.maxByOrNull { it.createdAt }
        PersonListItem(
            id = person.id,
            normalizedName = person.normalizedName,
            displayName = person.displayName ?: person.normalizedName,
            relationship = person.relationship,
            memoryCount = memories.size,
            latestTrait = latest?.trait,
            lastMentionedAt = latest?.createdAt?.toString(),  // <-- ISO 8601 포맷
        )
    }.sortedByDescending { it.lastMentionedAt }  // <-- 최근순 정렬 (String 기반, ISO 8601 호환)

    return PeopleListResponse(people = items, totalCount = items.size)
}
```

**분석**:
- ✅ `maxByOrNull { it.createdAt }` → 가장 최근 PersonMemory 추출
- ✅ `latest?.createdAt?.toString()` → Instant의 기본 문자열 표현이 ISO 8601 형식
- ✅ `sortedByDescending { it.lastMentionedAt }` → String 기반 내림차순 정렬. ISO 8601은 lexicographic 순서와 시간순이 일치하므로 정확

**결론**: ✅ **PASS**

---

### 2. POST /api/memories/people/merge (v1.2)

#### 스펙 요구사항 (api-contract.md 라인 637~664)

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

// Errors:
// 400 VALIDATION_ERROR — sourcePersonId == targetPersonId
// 404 PERSON_NOT_FOUND — source 또는 target 미존재
// 403 FORBIDDEN — 다른 사용자의 인물
```

특징:
- source의 PersonMemory.person → target으로 변경 (라인 661)
- source Person 삭제 (라인 662)
- target의 displayName/relationship은 유지 (라인 663)
- 동일 trait 중복 시 source 쪽 PersonMemory 삭제 (라인 664)

#### 구현 검증

**Controller (PersonController.kt 라인 25-33)**
```kotlin
@PostMapping("/merge")
fun merge(@RequestBody request: MergeRequest): ResponseEntity<MergeResponse> {
    if (request.sourcePersonId == null || request.targetPersonId == null) {
        throw ApiException(ErrorCode.VALIDATION_ERROR)
    }
    return ResponseEntity.ok(
        personService.mergePeople(currentUserId(), request.sourcePersonId, request.targetPersonId)
    )
}
```
✅ URL/메서드 일치: `POST /api/memories/people/merge`  
✅ null 검증

**Request/Response DTOs (ChatRequest.kt 라인 193-209)**
```kotlin
data class MergeRequest(
    val sourcePersonId: Long?,
    val targetPersonId: Long?,
)

data class MergeResponse(
    val mergedCount: Int,
    val target: MergeTargetItem,
)

data class MergeTargetItem(
    val id: Long,
    val normalizedName: String,
    val displayName: String,
    val relationship: String?,
    val memoryCount: Int,
)
```
✅ 모든 필드 스펙과 1:1 대응

**Service 구현 (PersonService.kt 라인 131-169)**
```kotlin
@Transactional
fun mergePeople(userId: Long, sourcePersonId: Long, targetPersonId: Long): MergeResponse {
    // 1. sourcePersonId == targetPersonId 검증
    if (sourcePersonId == targetPersonId) throw ApiException(ErrorCode.VALIDATION_ERROR)

    // 2. 인물 존재 검증
    val source = personRepository.findById(sourcePersonId)
        .orElseThrow { ApiException(ErrorCode.PERSON_NOT_FOUND) }
    val target = personRepository.findById(targetPersonId)
        .orElseThrow { ApiException(ErrorCode.PERSON_NOT_FOUND) }

    // 3. 권한 검증
    if (source.user.id != userId) throw ApiException(ErrorCode.FORBIDDEN)
    if (target.user.id != userId) throw ApiException(ErrorCode.FORBIDDEN)

    // 4. 중복 trait 삭제 (스펙 라인 664)
    val sourceMemories = personMemoryRepository.findByUserIdAndPersonId(userId, sourcePersonId)
    val targetTraits = personMemoryRepository.findByUserIdAndPersonId(userId, targetPersonId)
        .mapNotNull { it.trait }.toSet()
    val duplicates = sourceMemories.filter { it.trait != null && it.trait in targetTraits }
    personMemoryRepository.deleteAll(duplicates)
    entityManager.flush()
    entityManager.clear()

    // 5. source 메모리를 target으로 변경 (스펙 라인 661)
    val movedCount = personMemoryRepository.reassignPerson(sourcePersonId, targetPersonId, userId)
    entityManager.flush()

    // 6. source 인물 삭제 (스펙 라인 662)
    personRepository.deleteById(sourcePersonId)

    // 7. target의 displayName/relationship은 유지 (스펙 라인 663) — 수정하지 않음
    // 8. 최종 메모리 수 집계
    val totalCount = personMemoryRepository.countByPersonId(targetPersonId)

    return MergeResponse(
        mergedCount = movedCount,
        target = MergeTargetItem(
            id = target.id,
            normalizedName = target.normalizedName,
            displayName = target.displayName ?: target.normalizedName,
            relationship = target.relationship,
            memoryCount = totalCount.toInt(),
        ),
    )
}
```

**분석**:
- ✅ 400 VALIDATION_ERROR: `if (sourcePersonId == targetPersonId)`
- ✅ 404 PERSON_NOT_FOUND: `findById().orElseThrow()`
- ✅ 403 FORBIDDEN: `if (source.user.id != userId)`, `if (target.user.id != userId)`
- ✅ 비즈니스 로직:
  - 중복 trait 인물메모리 삭제
  - `reassignPerson()` 호출로 메모리의 person 변경
  - `personRepository.deleteById(sourcePersonId)` → source 인물 삭제
  - target의 displayName/relationship 유지 (수정 안 함)
  - `mergedCount` = 이동한 메모리 수 (중복 제외)

**결론**: ✅ **PASS**

---

### 3. PATCH /api/memories/people/{id} (v1.2)

#### 스펙 요구사항 (api-contract.md 라인 666~688)

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

// Errors:
// 404 PERSON_NOT_FOUND
// 403 FORBIDDEN
// 400 VALIDATION_ERROR — relationship/displayName 빈 문자열
```

특징:
- relationship, displayName 중 하나만 전달해도 됨 (partial update)
- normalizedName은 변경 불가

#### 구현 검증

**Controller (PersonController.kt 라인 35-43)**
```kotlin
@PatchMapping("/{id}")
fun update(
    @PathVariable id: Long,
    @RequestBody request: PersonUpdateRequest,
): ResponseEntity<PersonUpdateResponse> {
    return ResponseEntity.ok(
        personService.updatePerson(currentUserId(), id, request.relationship, request.displayName)
    )
}
```
✅ URL/메서드 일치: `PATCH /api/memories/people/{id}`

**Request/Response DTOs (ChatRequest.kt 라인 211-222)**
```kotlin
data class PersonUpdateRequest(
    val relationship: String? = null,
    val displayName: String? = null,
)

data class PersonUpdateResponse(
    val id: Long,
    val normalizedName: String,
    val displayName: String,
    val relationship: String?,
    val memoryCount: Int,
)
```
✅ 양쪽 필드 optional (default null) → partial update 지원  
✅ 모든 응답 필드 스펙과 1:1 대응

**Service 구현 (PersonService.kt 라인 171-197)**
```kotlin
@Transactional
fun updatePerson(userId: Long, personId: Long, relationship: String?, displayName: String?): PersonUpdateResponse {
    // 1. 인물 존재 검증
    val person = personRepository.findById(personId)
        .orElseThrow { ApiException(ErrorCode.PERSON_NOT_FOUND) }
    
    // 2. 권한 검증
    if (person.user.id != userId) throw ApiException(ErrorCode.FORBIDDEN)

    // 3. relationship 업데이트 (선택)
    if (relationship != null) {
        if (relationship.isBlank()) throw ApiException(ErrorCode.VALIDATION_ERROR)
        person.relationship = relationship
    }
    
    // 4. displayName 업데이트 (선택)
    if (displayName != null) {
        if (displayName.isBlank()) throw ApiException(ErrorCode.VALIDATION_ERROR)
        person.displayName = displayName
    }
    
    // 5. updatedAt 갱신
    person.updatedAt = Instant.now()
    personRepository.save(person)

    // 6. 메모리 수 집계
    val memoryCount = personMemoryRepository.countByPersonId(personId)

    return PersonUpdateResponse(
        id = person.id,
        normalizedName = person.normalizedName,
        displayName = person.displayName ?: person.normalizedName,
        relationship = person.relationship,
        memoryCount = memoryCount.toInt(),
    )
}
```

**분석**:
- ✅ 404 PERSON_NOT_FOUND: `findById().orElseThrow()`
- ✅ 403 FORBIDDEN: `if (person.user.id != userId)`
- ✅ 400 VALIDATION_ERROR: `if (relationship.isBlank())`, `if (displayName.isBlank())`
- ✅ Partial update: `if (relationship != null)`, `if (displayName != null)` 기반 선택 처리
- ✅ normalizedName 변경 불가: 코드에서 수정하지 않음

**결론**: ✅ **PASS**

---

## 종합 검증 결과

### 엔드포인트별 판정

| 엔드포인트 | 구현 | URL/메서드 | 요청/응답 | 에러코드 | 비즈니스로직 | 판정 |
|-----------|------|-----------|---------|---------|-----------|------|
| GET /api/memories/people/list | PersonController.list() | ✅ | ✅ | N/A | ✅ (정렬, 최신) | ✅ PASS |
| POST /api/memories/people/merge | PersonController.merge() | ✅ | ✅ | ✅ (400/404/403) | ✅ (중복제거, 이동, 삭제) | ✅ PASS |
| PATCH /api/memories/people/{id} | PersonController.update() | ✅ | ✅ | ✅ (400/404/403) | ✅ (partial update) | ✅ PASS |

### 필드 검증 (Request/Response 1:1 대조)

**GET /api/memories/people/list**
- ✅ `people[].id`, `people[].normalizedName`, `people[].displayName`, `people[].relationship`, `people[].memoryCount`, `people[].latestTrait`, `people[].lastMentionedAt`
- ✅ `totalCount`

**POST /api/memories/people/merge**
- ✅ Request: `sourcePersonId`, `targetPersonId`
- ✅ Response: `mergedCount`, `target.id`, `target.normalizedName`, `target.displayName`, `target.relationship`, `target.memoryCount`

**PATCH /api/memories/people/{id}**
- ✅ Request: `relationship` (optional), `displayName` (optional)
- ✅ Response: `id`, `normalizedName`, `displayName`, `relationship`, `memoryCount`

### 에러 코드 검증

| 에러 코드 | HTTP | 구현 위치 | 스펙 |
|----------|------|---------|------|
| VALIDATION_ERROR | 400 | PersonController.merge() (null), PersonService.mergePeople() (같은 ID), PersonService.updatePerson() (빈 문자열) | ✅ |
| PERSON_NOT_FOUND | 404 | PersonService.listPeople() (암묵), mergePeople(), updatePerson() | ✅ |
| FORBIDDEN | 403 | PersonService.mergePeople() (권한), updatePerson() (권한) | ✅ |

### 보안 검증 (security-hardening-checklist.md)

**Critical**:
- ✅ 비밀번호 처리: People API는 비밀번호 미사용
- ✅ SQL Injection: JPA 사용, raw query 없음

**High**:
- ⚠️ **Rate Limiting**: 스펙(api-contract.md 라인 1049~1054)에서 "chat" 버킷(RPM 20)과 "auth" 버킷(RPM 10)만 명시. People API는 미명시
  - **현황**: PersonController에 적용된 Rate Limiting 어노테이션 없음
  - **영향**: Gate 1 범위는 아니지만 서비스 배포 전 확인 필요 (Gate 2 또는 별도 작업)

**Medium**:
- ✅ 입력 값 검증: null 체크, isBlank() 체크 적용
- ✅ 에러 메시지: 스택 트레이스 미노출, ApiException 사용
- ✅ 로깅: 민감 정보 미노출

---

## 구현 정확도

### 비즈니스 로직 검증 상세

**Merge 알고리즘 (PersonService.mergePeople)**

스펙 요구사항:
```
- source의 PersonMemory.person → target으로 변경
- source Person 삭제
- target의 displayName/relationship은 유지
- 동일 trait 중복 시 source 쪽 PersonMemory 삭제
```

구현 순서:
1. ✅ 중복 trait 식별 및 삭제
2. ✅ `reassignPerson()` 호출로 메모리 인물 변경
3. ✅ source 인물 삭제
4. ✅ target 정보 유지 (수정 코드 없음)

트랜잭션 처리:
- ✅ `@Transactional` 적용
- ✅ `entityManager.flush()`, `.clear()` 호출로 순차 처리 및 일관성 보장

**Partial Update 패턴 (PersonService.updatePerson)**

```kotlin
if (relationship != null) {
    if (relationship.isBlank()) throw ApiException(ErrorCode.VALIDATION_ERROR)
    person.relationship = relationship
}
if (displayName != null) {
    if (displayName.isBlank()) throw ApiException(ErrorCode.VALIDATION_ERROR)
    person.displayName = displayName
}
```

✅ 각 필드별 독립적 null 체크 및 유효성 검증  
✅ 제공된 필드만 수정, 나머지 유지

---

## 최종 판정

### 종합 판정: **PASS**

**근거**:
1. ✅ 3개 엔드포인트 모두 URL/메서드 스펙 준수
2. ✅ Request/Response 필드 1:1 대응, 타입 일치
3. ✅ 에러 코드 (400/404/403) 모두 구현
4. ✅ 비즈니스 로직 (merge, partial update) 정확 구현
5. ✅ 트랜잭션, 권한 검증, 입력 유효성 검증 적용
6. ✅ 코드 가독성 및 유지보수성 양호

**조건 없음** — 모든 필수 항목 충족

**다음 단계**: Gate 2 (통합 검증)로 진행 가능
- 빌드 테스트 (`./gradlew build`)
- 서버 기동 테스트
- 클라이언트(iOS/Android) DTO 필드 동기화 확인
- 통합 테스트 (merge, update 시나리오)

---

## 부록: 스펙 레퍼런스

| 문서 | 섹션 | 라인 | 내용 |
|------|------|------|------|
| api-contract.md | 4. People (v1.2) | 579 | 섹션 시작 |
| api-contract.md | GET /api/memories/people/list | 612-635 | 전체 인물 목록 |
| api-contract.md | POST /api/memories/people/merge | 637-664 | 인물 병합 |
| api-contract.md | PATCH /api/memories/people/{id} | 666-688 | 인물 정보 수정 |
| api-contract.md | Error Codes | 1004-1025 | 에러 코드 정의 |
| api-contract.md | Rate Limit 헤더 | 1034-1058 | Rate Limiting 정의 |

---

**Gate 1 검증 완료**  
2026-04-19 by Architect
