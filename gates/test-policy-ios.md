# iOS (Swift/TCA) — 테스트 정책

> [test-policy.md](./test-policy.md) 의 하위 문서.

## 스택
- XCTest (Xcode 기본)
- Tuist 6+ (프로젝트 생성 + `tuist test`)
- swift-composable-architecture `TestStore`
- `@Dependency` + `DependencyKey` 로 모든 I/O 의존성 주입

## 원칙

### 1. Feature (Reducer) 테스트 = 필수
모든 `@Reducer` 에 대해 대응하는 `*FeatureTests.swift` 가 존재한다.

**구조**:
```swift
@MainActor
final class ChatFeatureTests: XCTestCase {
  func test_sendMessage_happyPath() async {
    let store = TestStore(initialState: ChatFeature.State()) {
      ChatFeature()
    } withDependencies: {
      $0.apiClient.sendChat = { _ in
        ChatResponse(reply: "hi", memoriesExtracted: [])
      }
    }

    await store.send(.inputChanged("hello")) {
      $0.input = "hello"
    }
    await store.send(.sendTapped) {
      $0.isSending = true
    }
    await store.receive(.chatResponse(.success(...))) {
      $0.messages.append(...)
      $0.isSending = false
    }
  }
}
```

**필수 커버리지**:
- 액션 하나당 최소 1 테스트 (전송/수신 쌍 포함)
- 에러 경로 — `apiClient` 가 throw 하는 케이스
- `isLoading`, `errorMessage` 등 State 전이 검증

### 2. APIClient 테스트
- `URLSession` 을 실제로 쓰지 않는다. `MockURLProtocol` 또는 의존성으로 대체
- 엔드포인트별 request 구성 검증 (URL, method, headers, body)

### 3. View (SwiftUI) 테스트
- **원칙**: View는 Reducer에 state/action만 위임. 스냅샷/XCUI 테스트는 선택.
- View의 로직 (조건부 렌더링, computed properties)이 복잡하면 헬퍼 struct로 추출해 단위 테스트.
- 스냅샷 테스트 도입 시 반드시 단일 기기 + 단일 iOS 버전 기준 (flakiness 방지).

## Dependency 주입 규칙
- 모든 I/O (APIClient, Keychain, UserDefaults, 시계, UUID 등) → `@Dependency`
- 새 I/O 추가 시 `DependencyKey` + `testValue` 기본 구현 필수
- `testValue` 는 `unimplemented()` 로 기본 (테스트에서 명시적 주입 요구)

## Scheme + 실행 규칙

### Tuist 구성 (Project.swift)
```swift
.target(
  name: "AidyTests",
  destinations: .iOS,
  product: .unitTests,
  bundleId: "com.mino.aidy.tests",
  sources: ["Projects/App/Tests/**"],
  dependencies: [.target(name: "Aidy")]
)
```

### Tuist/Package.swift
외부 SPM 의존성은 `PackageSettings.productTypes` 에 **명시적으로 framework 선언** (resource bundle copy 이슈 방지):
```swift
let packageSettings = PackageSettings(
  productTypes: [
    "ComposableArchitecture": .framework,
    "Sharing": .framework,
    // 필요한 것 모두
  ]
)
```
**이 설정 없이 xcodebuild test 실행 시 resource bundle copy 실패한다.**

### 테스트 실행
```bash
# 1) 프로젝트 재생성 (의존성 변경 시)
tuist clean && tuist install && tuist generate --no-open

# 2) 실행 — 반드시 -workspace 사용 (Aidy.xcworkspace). -project 사용 시 SPM 모듈 해석 실패
xcodebuild test \
  -workspace Aidy.xcworkspace \
  -scheme Aidy \
  -destination 'platform=iOS Simulator,name=iPhone 17,OS=latest'

# 또는 tuist CLI (tuist 6+)
tuist test --no-selective-testing

# 3) 실행 증거 확인 — "Test Suite 'All tests' passed" + NN tests 표시 필수
```

## 실행 증거 캡처 — 필수
`xcodebuild test` 출력에서 다음을 반드시 확인하고 커밋 메시지/inbox에 기록:
- `Test Suite 'All tests' passed` (또는 failed 면 즉시 수정)
- `Executed NN tests, with 0 failures` — 숫자 노출
- `no tests to run` 이 나오면 **테스트가 실제로 안 돈 것** — 심각한 버그

## 커밋 전 필수 확인
- `xcodebuild test` → BUILD SUCCEEDED + TEST SUCCEEDED
- `** TEST SUCCEEDED **` 문구 확인
- 커밋 메시지에 `테스트: NN passed / 0 failed` 포함

## 금지
- `$0.apiClient.sendChat = .unimplemented` 상태로 production 경로 커버 — 반드시 success + failure stub
- Feature 없이 View에만 로직 집어넣기 (테스트 불가 구조)
- `.dependency(\.apiClient, liveValue)` 로 실호출
- Snapshot 테스트를 여러 기기/OS에 걸쳐 돌리기 (flakiness의 원천)

## 회귀 안전장치
- 테스트 파일이 **Aidy.xcscheme** 의 TestAction.Testables 에 포함되었는지 PR 전 확인
- Scheme 파일이 shared (`xcshareddata/xcschemes/`) 아래 있는지 확인
