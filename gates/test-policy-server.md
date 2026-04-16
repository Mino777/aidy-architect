# 서버 (Kotlin/Spring Boot) — 테스트 정책

> [test-policy.md](./test-policy.md) 의 하위 문서. 공통 P1~P6 원칙 위에 서버 전용 규정.

## 스택
- JUnit 5 + kotlin-test
- MockK (서비스/레포지토리 Mock)
- Spring Boot Test (@SpringBootTest, @WebMvcTest, @DataJpaTest)
- H2 인메모리 DB (테스트 프로파일)
- MockMvc (컨트롤러 통합)

## 테스트 계층

### 1. 단위 테스트 (Service/Util)
**대상**: 비즈니스 로직을 가진 Service, Util, Validator
**규칙**:
- MockK로 의존성 격리 (`@MockK val repo: MemoryRepository`)
- Given-When-Then 또는 Arrange-Act-Assert 구조
- 한 테스트 = 하나의 assertion 주제
- **모든 public 메서드 = 최소 1 happy + 1 failure 테스트**

예시 필수 커버리지:
- `AiService.chat` — 정상 응답 / 타임아웃 / 검증 실패 / CB OPEN
- `AiCircuitBreaker` — 상태 전이 전수 (R2에서 완료)
- `AiResponseValidator` — 유효/무효 레이어별

### 2. Repository 테스트 (@DataJpaTest)
**대상**: `@Query`, 커스텀 쿼리가 있는 Repository 메서드
**규칙**:
- `@DataJpaTest` + H2 자동 설정
- SpringBatchTestExecutionListener 불필요
- 트랜잭션 자동 롤백으로 테스트 격리
- **커스텀 쿼리 = 반드시 테스트**

### 3. 컨트롤러 테스트 (@WebMvcTest)
**대상**: `@RestController` 의 모든 엔드포인트
**규칙**:
- MockMvc로 HTTP layer 검증
- 서비스는 `@MockkBean`
- **모든 엔드포인트 = 200 happy + 4xx/5xx 최소 1 + 인증 필요 엔드포인트는 401 케이스**

예시 필수 커버리지:
- `/api/auth/signup` — 201 / 400(validation) / 409(duplicate)
- `/api/auth/login` — 200 / 401(invalid) / 400(validation)
- `/api/chat` — 200 / 401(no token) / 400(empty) / 504(timeout) / 503(ai unavailable)
- `/api/memories` — 200 / 401 / 404

### 4. 통합 테스트 (@SpringBootTest)
**대상**: E2E 시나리오, Rate Limit, 전체 Auth 플로우
**규칙**:
- `webEnvironment = RANDOM_PORT` 또는 `MOCK` (MockMvc)
- 전체 Spring 컨텍스트 실제 로딩
- AI API는 `@MockkBean AiService` 로 stub
- DB는 H2 + Flyway
- **큰 기능 1개 = 1 E2E 시나리오 필수** (signup → login → 주요 기능 사용)

## Error Code 커버리지 규칙

`specs/api-contract.md` 의 Error Codes 표에 있는 모든 code에 대해 **최소 1개 테스트**가 이를 생성하고 검증해야 한다.

| Code | 테스트 위치 (예시) |
|------|------------------|
| EMPTY_MESSAGE | ChatControllerTest |
| VALIDATION_ERROR | GlobalExceptionHandlerTest + AuthControllerTest |
| INVALID_CREDENTIALS | AuthControllerTest |
| UNAUTHORIZED | (모든 보호 컨트롤러 @WebMvcTest) |
| FORBIDDEN | MemoryControllerTest |
| MEMORY_NOT_FOUND | MemoryControllerTest |
| PERSON_NOT_FOUND | PeopleControllerTest |
| DUPLICATE_EMAIL | AuthControllerTest |
| RATE_LIMITED | RateLimitInterceptorIntegrationTest |
| AI_TIMEOUT | AiServiceTest (또는 ChatControllerTest에서 Mockk timeout stub) |
| AI_UNAVAILABLE | AiCircuitBreakerTest + (통합) |
| INTERNAL_ERROR | GlobalExceptionHandlerTest |

## DTO Validation 테스트 규칙

`@field:NotBlank`, `@field:Email`, `@field:Size` 등 모든 validation 어노테이션:
- 실패 케이스 테스트 필수 (입력 → 400 + VALIDATION_ERROR)
- 메시지 한국어 노출 확인 (R8에서 정립)

## 실행 규칙

```bash
# 기본: 전체
./gradlew test

# 변경 부분만 빠르게
./gradlew test --tests "*ChatController*"

# 강제 재실행 (캐시 무시, 릴리즈 전 1회)
./gradlew test --rerun-tasks

# 테스트 리포트
open build/reports/tests/test/index.html
```

## 커밋 전 필수 확인
- `./gradlew test` — BUILD SUCCESSFUL
- `build/test-results/test/TEST-*.xml` — failures="0" errors="0"
- 커밋 메시지에 `테스트: NN passed, 0 failed` 포함

## 금지
- 실제 Anthropic API 호출 — 반드시 `@MockkBean`
- 실제 PostgreSQL — 테스트는 H2 전용
- `@Disabled` 사용 (극히 예외적일 때만 이유 주석 + TODO 코멘트)
- `Thread.sleep()` 으로 비동기 대기 — `Awaitility` 또는 deterministic clock 주입
- 테스트 삭제 (리팩터로 대체할 땐 등가 커버리지 보존)
