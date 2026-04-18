# Gate 1 검증: WO-052 iOS People 관리 UI (스펙 준수)

**검증일**: 2026-04-19  
**검증자**: Architect  
**대상**: aidy-ios (People v1.2)  
**상태**: **PASS** ✅

---

## 1. 엔드포인트 URL + 메서드 검증

### 1.1 GET /api/memories/people/list (v1.2)

| 항목 | 스펙 | iOS 구현 | 일치 |
|------|------|---------|------|
| **URL** | `/api/memories/people/list` | `/api/memories/people/list` (L679) | ✅ |
| **메서드** | GET | GET (authorizedRequest) | ✅ |
| **인증** | Authorization Bearer | O (authorizedRequest) | ✅ |

**코드 위치**: `/Users/jominho/Develop/aidy-ios/Projects/App/Sources/Core/Network/APIClient.swift:678-682`

```swift
fetchPeopleList: {
    let request = Self.authorizedRequest(url: Self.url("/api/memories/people/list"))
    let (data, response) = try await URLSession.shared.data(for: request)
    try Self.checkResponse(data: data, response: response)
    return try JSONDecoder().decode(PeopleListResponse.self, from: data)
}
```

**검증**: ✅ PASS

---

### 1.2 POST /api/memories/people/merge (v1.2)

| 항목 | 스펙 | iOS 구현 | 일치 |
|------|------|---------|------|
| **URL** | `/api/memories/people/merge` | `/api/memories/people/merge` (L686) | ✅ |
| **메서드** | POST | POST (method: "POST") | ✅ |
| **인증** | Authorization Bearer | O (authorizedRequest) | ✅ |

**코드 위치**: `/Users/jominho/Develop/aidy-ios/Projects/App/Sources/Core/Network/APIClient.swift:684-690`

```swift
mergePeople: { sourcePersonId, targetPersonId in
    struct MergeRequest: Encodable { let sourcePersonId: Int64; let targetPersonId: Int64 }
    var request = Self.authorizedRequest(url: Self.url("/api/memories/people/merge"), method: "POST")
    request.httpBody = try JSONEncoder().encode(MergeRequest(sourcePersonId: sourcePersonId, targetPersonId: targetPersonId))
    let (data, response) = try await URLSession.shared.data(for: request)
    try Self.checkResponse(data: data, response: response)
    return try JSONDecoder().decode(PeopleMergeResponse.self, from: data)
}
```

**검증**: ✅ PASS

---

### 1.3 PATCH /api/memories/people/{id} (v1.2)

| 항목 | 스펙 | iOS 구현 | 일치 |
|------|------|---------|------|
| **URL** | `/api/memories/people/{id}` | `/api/memories/people/{id}` (L694) | ✅ |
| **메서드** | PATCH | PATCH (method: "PATCH") | ✅ |
| **인증** | Authorization Bearer | O (authorizedRequest) | ✅ |

**코드 위치**: `/Users/jominho/Develop/aidy-ios/Projects/App/Sources/Core/Network/APIClient.swift:692-699`

```swift
editPerson: { id, relationship, displayName in
    struct EditRequest: Encodable { let relationship: String?; let displayName: String? }
    var request = Self.authorizedRequest(url: Self.url("/api/memories/people/\(id)"), method: "PATCH")
    request.httpBody = try JSONEncoder().encode(EditRequest(relationship: relationship, displayName: displayName))
    let (data, response) = try await URLSession.shared.data(for: request)
    try Self.checkResponse(data: data, response: response)
    return try JSONDecoder().decode(PersonEditResult.self, from: data)
}
```

**검증**: ✅ PASS

---

## 2. Request Body 필드 검증

### 2.1 POST /api/memories/people/merge Request

**스펙** (Line 642-645):
```json
{
  "sourcePersonId": 2,
  "targetPersonId": 1
}
```

**iOS 구현** (L685):
```swift
struct MergeRequest: Encodable { 
    let sourcePersonId: Int64
    let targetPersonId: Int64 
}
```

| 필드 | 스펙 | iOS | 타입 | 일치 |
|------|------|-----|------|------|
| `sourcePersonId` | Int | Int64 | 번호 ID | ✅ |
| `targetPersonId` | Int | Int64 | 번호 ID | ✅ |

**검증**: ✅ PASS - 필드명 정확, 타입 호환

---

### 2.2 PATCH /api/memories/people/{id} Request

**스펙** (Line 671-674):
```json
{
  "relationship": "친한 친구",
  "displayName": "김철수 팀장"
}
```

**iOS 구현** (L693):
```swift
struct EditRequest: Encodable { 
    let relationship: String?
    let displayName: String? 
}
```

| 필드 | 스펙 | iOS | 선택성 | 일치 |
|------|------|-----|--------|------|
| `relationship` | String | String? | partial update (선택) | ✅ |
| `displayName` | String | String? | partial update (선택) | ✅ |

**검증**: ✅ PASS - 스펙 "partial update" 정확 구현

**호출 코드** (PersonDetailFeature.swift, L138-144):
```swift
try await apiClient.editPerson(
    personId,
    relationship.isEmpty ? nil : relationship,
    displayName.isEmpty ? nil : displayName
)
```
→ 빈 문자열을 nil로 전환: ✅ PASS (VALIDATION_ERROR 방지)

---

## 3. Response Body 필드 검증

### 3.1 GET /api/memories/people/list Response

**스펙** (Line 617-630):
```json
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

**iOS 모델** (`Person.swift`, L76-89):
```swift
struct PeopleListResponse: Equatable, Codable {
    let people: [PersonListItem]
    let totalCount: Int
}

struct PersonListItem: Equatable, Codable, Identifiable {
    let id: Int64
    let normalizedName: String
    let displayName: String
    let relationship: String
    let memoryCount: Int
    let latestTrait: String
    let lastMentionedAt: String
}
```

| 필드 | 스펙 | iOS | 타입 | 일치 |
|------|------|-----|------|------|
| `people[].id` | number | Int64 | ID | ✅ |
| `people[].normalizedName` | string | String | 정규화된 이름 | ✅ |
| `people[].displayName` | string | String | 표시명 | ✅ |
| `people[].relationship` | string | String | 관계 | ✅ |
| `people[].memoryCount` | number | Int | 메모리 수 | ✅ |
| `people[].latestTrait` | string | String | 최신 특성 | ✅ |
| `people[].lastMentionedAt` | ISO8601 | String | 타임스탬프 | ✅ |
| `totalCount` | number | Int | 전체 수 | ✅ |

**검증**: ✅ PASS - 필드명, 타입, 구조 완벽 일치

---

### 3.2 POST /api/memories/people/merge Response

**스펙** (Line 647-656):
```json
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
```

**iOS 모델** (`Person.swift`, L93-106):
```swift
struct PeopleMergeResponse: Equatable, Codable {
    let mergedCount: Int
    let target: PersonEditResult
}

struct PersonEditResult: Equatable, Codable {
    let id: Int64
    let normalizedName: String
    let displayName: String
    let relationship: String
    let memoryCount: Int
}
```

| 필드 | 스펙 | iOS | 타입 | 일치 |
|------|------|-----|------|------|
| `mergedCount` | number | Int | 병합된 메모리 수 | ✅ |
| `target.id` | number | Int64 | 대상 ID | ✅ |
| `target.normalizedName` | string | String | 정규화명 | ✅ |
| `target.displayName` | string | String | 표시명 | ✅ |
| `target.relationship` | string | String | 관계 | ✅ |
| `target.memoryCount` | number | Int | 메모리 수 | ✅ |

**검증**: ✅ PASS - 완벽 일치

---

### 3.3 PATCH /api/memories/people/{id} Response

**스펙** (Line 676-682):
```json
{
  "id": 1,
  "normalizedName": "김팀장",
  "displayName": "김철수 팀장",
  "relationship": "친한 친구",
  "memoryCount": 8
}
```

**iOS 모델** (`Person.swift`, L100-106):
```swift
struct PersonEditResult: Equatable, Codable {
    let id: Int64
    let normalizedName: String
    let displayName: String
    let relationship: String
    let memoryCount: Int
}
```

| 필드 | 스펙 | iOS | 타입 | 일치 |
|------|------|-----|------|------|
| `id` | number | Int64 | ID | ✅ |
| `normalizedName` | string | String | 정규화명 | ✅ |
| `displayName` | string | String | 표시명 | ✅ |
| `relationship` | string | String | 관계 | ✅ |
| `memoryCount` | number | Int | 메모리 수 | ✅ |

**검증**: ✅ PASS - 완벽 일치

---

## 4. 에러 코드 검증

**스펙** (Line 657-659):
```
Error 400 VALIDATION_ERROR — sourcePersonId == targetPersonId
Error 404 PERSON_NOT_FOUND — source 또는 target 미존재
Error 403 FORBIDDEN — 다른 사용자의 인물
```

**스펙** (Line 683-685):
```
Error 404 PERSON_NOT_FOUND
Error 403 FORBIDDEN
Error 400 VALIDATION_ERROR — relationship/displayName 빈 문자열
```

**iOS 에러 처리** (`APIClient.swift`, L7-33):
```swift
struct APIErrorResponse: Equatable, Codable {
    let error: String
    let code: String
}

enum APIError: Error, Equatable {
    case server(message: String, code: String)
    case network(String)
    case unauthorized
    case rateLimited(retryAfter: Int)
    
    var isRetryable: Bool { ... }
    static let retryableCodes: Set<String> = ["RATE_LIMITED", "AI_TIMEOUT", "AI_UNAVAILABLE"]
}
```

**검증**: ✅ PASS
- APIErrorResponse 구조로 `code` 필드 캡처: ✅
- 스펙의 에러 코드들(VALIDATION_ERROR, PERSON_NOT_FOUND, FORBIDDEN) 모두 server(_:code:)로 처리 가능: ✅
- HTTP 상태 코드별 매핑:
  - 400 VALIDATION_ERROR: line 764 (일반 4xx 처리)
  - 403 FORBIDDEN: line 764
  - 404 PERSON_NOT_FOUND: line 764
  - checkResponse() 함수로 체계적 처리: ✅

---

## 5. HTTP 상태 코드 검증

**스펙** (명시 상태):
- GET /api/memories/people/list: 200
- POST /api/memories/people/merge: 200
- PATCH /api/memories/people/{id}: 200

**iOS 구현** (`APIClient.swift`, L764):
```swift
guard (200...299).contains(httpResponse.statusCode) else {
    // 에러 처리
}
```

**검증**: ✅ PASS - 2xx 범위 모두 성공으로 처리

---

## 6. 기능 동작 검증

### 6.1 fetchPeopleList 통합

**Feature** (`PeopleFeature.swift`, L46-51):
```swift
case .onAppear:
    state.isLoading = true
    return .run { send in
        await send(.peopleLoaded(Result {
            try await apiClient.fetchPeopleList()
        }))
    }
```

→ API 호출 정확: ✅

### 6.2 mergePeople 통합

**Feature** (`PeopleFeature.swift`, L107-116):
```swift
case .alert(.presented(.confirmMerge)):
    let ids = Array(state.mergeSelection).sorted()
    let sourceId = ids[0]
    let targetId = ids[1]
    state.isMerging = true
    return .run { send in
        await send(.mergeResult(Result {
            try await apiClient.mergePeople(sourceId, targetId)
        }))
    }
```

→ Request 필드 `sourcePersonId`, `targetPersonId` 정확: ✅
→ 스펙 "source 인물의 모든 메모리를 target으로 이동" 처리: ✅

### 6.3 editPerson 통합

**Feature** (`PersonDetailFeature.swift`, L131-145):
```swift
case .editSaveTapped:
    guard let personId = state.personId else { return .none }
    let displayName = state.editDisplayName.trimmingCharacters(in: .whitespaces)
    let relationship = state.editRelationship.trimmingCharacters(in: .whitespaces)
    guard !displayName.isEmpty || !relationship.isEmpty else { return .none }
    state.isSaving = true
    return .run { send in
        await send(.editResult(Result {
            try await apiClient.editPerson(
                personId,
                relationship.isEmpty ? nil : relationship,
                displayName.isEmpty ? nil : displayName
            )
        }))
    }
```

→ **스펙 준수 검증**:
  - `partial update`: "relationship, displayName 중 하나만 전달해도 됨" → nil 전환으로 구현: ✅
  - 빈 문자열 검증: `VALIDATION_ERROR — relationship/displayName 빈 문자열` → 호출 전 guard로 방어: ✅
  - 응답 처리 (L147-152):
    ```swift
    case let .editResult(.success(result)):
        state.isSaving = false
        state.isEditing = false
        state.person?.relationship = result.relationship
        return .send(.delegate(.personEdited))
    ```
    → 서버 응답의 `relationship` 필드 정확히 매핑: ✅

---

## 7. 인증 헤더 검증

**스펙** (API Contract Line 10-11):
```
Authorization: Bearer {JWT_TOKEN} (v0.2+)
```

**iOS 구현** (`APIClient.swift`, L719-725):
```swift
private static func authorizedRequest(url: URL, method: String = "GET") -> URLRequest {
    var request = Self.request(url: url, method: method)
    if let token = loadTokenFromKeychain() {
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    }
    return request
}
```

→ "Bearer {JWT}" 형식 정확: ✅
→ 3개 엔드포인트 모두 authorizedRequest 사용: ✅

---

## 8. 데이터 타입 호환성 검증

| 항목 | 스펙 | iOS | 호환성 |
|------|------|-----|---------|
| 인물 ID (id) | number | Int64 | ✅ 호환 |
| 메모리 수 (memoryCount) | number | Int | ✅ 호환 |
| 타임스탬프 (lastMentionedAt) | ISO8601 | String | ✅ 호환 (후처리 가능) |

---

## 9. 네이밍 컨벤션 검증

| 항목 | 스펙 | iOS | 준수 |
|------|------|-----|------|
| struct 이름 | PeopleListResponse | PeopleListResponse | ✅ |
| 필드: camelCase | sourcePersonId | sourcePersonId | ✅ |
| 필드: camelCase | targetPersonId | targetPersonId | ✅ |
| 필드: camelCase | displayName | displayName | ✅ |
| 필드: camelCase | normalizedName | normalizedName | ✅ |
| 필드: camelCase | lastMentionedAt | lastMentionedAt | ✅ |
| 메서드: lowerCamelCase | fetchPeopleList | fetchPeopleList | ✅ |
| 메서드: lowerCamelCase | mergePeople | mergePeople | ✅ |
| 메서드: lowerCamelCase | editPerson | editPerson | ✅ |

**검증**: ✅ PASS - Swift camelCase 컨벤션 정확 준수

---

## 10. 보안 검증

**api-contract.md 기준 (Line 10-12)**:
- Authorization Bearer header: ✅ (L722)
- Content-Type: application/json: ✅ (L715)
- 토큰 보안 저장 (Keychain): ✅ (L727-739)

**security-hardening-checklist.md 항목**:
- HTTP 401 처리: ✅ (L747, Notification 발송)
- HTTP 429 Rate Limit: ✅ (L753, Retry-After 파싱)
- 에러 로깅 (민감정보 제외): ✅ (L757-773, errorLog 사용)

---

## 최종 판정

### PASS ✅

**사유**:
1. ✅ 3개 엔드포인트(list, merge, edit) URL/메서드 정확 일치
2. ✅ Request body 필드명/타입 정확 일치
3. ✅ Response body 필드명/타입/구조 정확 일치
4. ✅ Partial update (editPerson) 올바르게 구현
5. ✅ 에러 코드 처리 체계 정상
6. ✅ HTTP 상태 코드 범위 정상
7. ✅ 인증 헤더 (Authorization Bearer) 정상
8. ✅ 데이터 타입 호환성 정상
9. ✅ 네이밍 컨벤션 정확
10. ✅ 보안 (Keychain 저장, 401 처리, 에러 로깅) 정상

**누락 없음** — 스펙의 모든 필드, 메서드, 에러 코드가 iOS 구현에 포함됨.

---

## 파일 체크리스트

- `/Users/jominho/Develop/aidy-ios/Projects/App/Sources/Core/Network/APIClient.swift` (L184-187, L678-699): People 3개 메서드 정의 + 구현
- `/Users/jominho/Develop/aidy-ios/Projects/App/Sources/Core/Model/Person.swift` (L76-106): 5개 Response 구조체
- `/Users/jominho/Develop/aidy-ios/Projects/App/Sources/Feature/People/PeopleFeature.swift`: fetchPeopleList, mergePeople 호출
- `/Users/jominho/Develop/aidy-ios/Projects/App/Sources/Feature/People/PersonDetailFeature.swift`: editPerson 호출

---

## Gate 2 이행 조건

Gate 2에서 확인할 항목:
1. 빌드 통과 (Tuist + Xcode)
2. 테스트 통과 (Unit + UI)
3. 서버 통합 테스트 (실제 BE 응답)
4. 교차 검증 (Android/Server 필드 일치)

