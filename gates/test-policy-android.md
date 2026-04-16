# Android (Kotlin/Compose/MVVM) — 테스트 정책

> [test-policy.md](./test-policy.md) 의 하위 문서.

## 스택
- JUnit 4 (기본) + Kotlin
- kotlinx.coroutines.test — `runTest`, `TestDispatcher`
- Turbine (Flow 검증) — 이미 있으면 사용, 없으면 `collect { }` 수동
- MockK (또는 기존 Mock 라이브러리)
- Compose UI Test (선택) — 필요 시 도입

## 테스트 계층

### 1. ViewModel 단위 테스트 = 필수
모든 `ViewModel` 은 대응하는 `*ViewModelTest.kt` 를 가진다.

**구조**:
```kotlin
@ExperimentalCoroutinesApi
class ChatViewModelTest {
  private lateinit var vm: ChatViewModel
  private val dispatcher = StandardTestDispatcher()

  @Before fun setUp() {
    Dispatchers.setMain(dispatcher)
    vm = ChatViewModel(fakeRepo, fakeAuthStore)
  }

  @After fun tearDown() = Dispatchers.resetMain()

  @Test fun `메시지 전송 성공 시 리스트에 추가된다`() = runTest {
    vm.send("hello")
    advanceUntilIdle()
    assertEquals(2, vm.messages.value.size) // user + reply
  }
}
```

**필수 커버리지**:
- ViewModel의 모든 public 메서드 = 최소 1 테스트
- 에러 경로 — repository/API throw 시
- `isLoading`, `errorMessage`, 상태 플로우 전이

### 2. Repository 테스트
- Retrofit API 를 MockK 로 stub
- 또는 MockWebServer 로 실제 HTTP 동작 테스트
- `ApiException` 매핑 정확성 검증

### 3. Compose UI 테스트 (선택)
- `createComposeRule()` 사용
- 주요 화면 smoke test — "Auth → Chat → 메시지 전송 → 결과 표시"
- 매 커밋 실행 대신 CI nightly 또는 주 1회 충분
- **ViewModelTest를 대체하지 않는다** (UI 테스트 ≠ 단위 테스트)

## Coroutine / Flow 규칙
- `viewModelScope` 의 동작은 `StandardTestDispatcher` + `Dispatchers.setMain`
- `MutableStateFlow` 의 emit 검증은 `advanceUntilIdle()` 후 `value` 확인
- Turbine 사용 시:
  ```kotlin
  vm.uiState.test {
    awaitItem() // 초기값
    vm.load()
    assertEquals(Loading, awaitItem())
    assertEquals(Success(data), awaitItem())
  }
  ```

## ApiException 매핑 커버리지
`specs/api-contract.md` Error Codes 표의 모든 code 가 클라이언트에서 구분되는지 테스트:
- `ApiExceptionTest` — isRetryable 분류
- ViewModel → `errorMessage` 한국어 매핑 검증

## 실행 규칙

```bash
# 기본
./gradlew testDebugUnitTest

# 빠른 루프 (캐시 사용)
./gradlew testDebugUnitTest --tests "com.mino.aidy.ui.chat.*"

# 강제 재실행
./gradlew testDebugUnitTest --rerun-tasks

# 전체 검증 (빌드 + 테스트)
./gradlew clean testDebugUnitTest assembleDebug

# 리포트
open app/build/reports/tests/testDebugUnitTest/index.html
```

## Deprecation / Warning 정책
- `w: ... is deprecated` 경고 → 커밋 내 해결 (예: `Icons.AutoMirrored.Filled.Chat`)
- `w: Condition is always 'true'` → 로직 검토 후 수정
- Warning-free 기본 — 경고 남기면 회고에 이유 명시

## 커밋 전 필수 확인
- `./gradlew testDebugUnitTest` — BUILD SUCCESSFUL
- `app/build/test-results/testDebugUnitTest/TEST-*.xml` — 총합 failures=0 errors=0
- 커밋 메시지에 `테스트: NN passed, 0 failed` 포함

## 금지
- 실제 Anthropic/서버 호출
- `GlobalScope.launch` — ViewModel scope만 사용
- `Thread.sleep()` → `advanceTimeBy(...)` 또는 `advanceUntilIdle()`
- Hilt 의존성 실제 주입 — 테스트에서는 직접 생성자 주입 또는 Hilt Test module
- `@Ignore` 사용 (극히 예외만, 주석 + TODO)

## Hilt 테스트 (해당 시)
- `@HiltAndroidTest` + `HiltAndroidRule` 사용
- 또는 단위 테스트는 Hilt 우회 (직접 의존성 주입)
- `@TestInstallIn` 으로 테스트 전용 모듈 교체
