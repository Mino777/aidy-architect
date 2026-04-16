# iOS 테스트가 "통과" 하지만 실제로는 한 번도 실행되지 않은 함정

## 증상
- 10라운드 동안 iOS 워커가 매 라운드마다 "tuist build 통과" + "테스트 PASS" 보고
- 실제로는 `tuist test` 가 `The scheme Aidy's test action has no tests to run, finishing early.` 로 조용히 종료
- `xcodebuild test -project Aidy.xcodeproj -scheme Aidy` 는 resource bundle copy 에러로 실패
  - `swift-sharing_Sharing.bundle: No such file or directory`
  - `swift-composable-architecture_ComposableArchitecture.bundle: No such file or directory`
- 테스트 파일 (`*FeatureTests.swift`)은 컴파일은 됐지만 런타임에서 한 번도 실행된 적 없음

## 근본 원인 (2가지가 겹침)

### 원인 A — Tuist + SPM 리소스 번들 불일치
Tuist가 SPM 패키지를 기본 **static library** 로 변환 → 의존성 내부 리소스 (`Sharing.bundle`, `ComposableArchitecture.bundle`) 경로가 앱 번들 안쪽으로 복사되도록 생성되는데, 실제로는 그 경로에 파일이 없음. 빌드 실패 → 테스트 실행 불가.

### 원인 B — `xcodebuild` 에 `-project` 사용
Tuist가 SPM 패키지를 `Tuist/.build/tuist-derived/Projects/*.xcodeproj` 로 생성해서 `Aidy.xcworkspace` 로 묶어 둔다. `xcodebuild ... -project Aidy.xcodeproj` 로 실행하면 그 SPM xcodeproj들을 못 봐서 `Unable to find module dependency: 'ComposableArchitecture'` 발생.

## 해결

### 1. `Tuist/Package.swift` 의 `PackageSettings.productTypes` 에 `.framework` 명시
```swift
let packageSettings = PackageSettings(
    productTypes: [
        "ComposableArchitecture": .framework,
        "Sharing": .framework,
        "Perception": .framework,
        "Dependencies": .framework,
        "CasePaths": .framework,
    ]
)
```
→ 리소스 번들이 framework 내부에 포함되어 경로 불일치 해소.

### 2. 재생성 절차
```bash
rm -rf ~/Library/Developer/Xcode/DerivedData/Aidy-*
cd ~/Develop/aidy-ios
tuist clean && tuist install && tuist generate --no-open
```

### 3. 테스트 실행 — 반드시 `-workspace`
```bash
# OK
xcodebuild test -workspace Aidy.xcworkspace -scheme Aidy \
  -destination 'platform=iOS Simulator,name=iPhone 17,OS=latest'

# 또는 (tuist 6+)
tuist test --no-selective-testing

# ❌ -project 사용 금지 (SPM 모듈 해석 실패)
```

## 결과
- 46 tests in 5 suites: AuthFeatureTests(9) / ChatFeatureTests(16) / MemoryFeatureTests(11) / PeopleFeatureTests(5) / PersonDetailFeatureTests(5)
- `Test Suite 'All tests' passed` + `** TEST SUCCEEDED **` 실제 확인

## 일반화된 검증 프로토콜 (재발 방지)

테스트 통과 주장을 받을 때 **반드시 다음 증거**를 요구한다:

### Stage 1 — "실행됐다" 증거
- `Test run with NN tests in M suites passed` — 숫자가 실제로 보여야 함
- `** TEST SUCCEEDED **` 문구
- `no tests to run, finishing early` 면 **실행 안 된 것** — RED

### Stage 2 — "숫자가 맞다" 증거
- `find build/test-results -name "TEST-*.xml" | wc -l` — 실제 리포트 파일 수
- XML 내부 `tests="NN" failures="0" errors="0"` 합계 확인

### Stage 3 — "scheme 포함되어 있다" 증거
- iOS: `Aidy.xcodeproj/xcshareddata/xcschemes/Aidy.xcscheme` 의 `<TestAction><Testables>` 에 테스트 타겟 있는지
- Android: `app/build/test-results/testDebugUnitTest/` 에 TEST XML 존재

## 체크리스트 (다음 세션용)

새 클라이언트 프로젝트 셋업 시:
- [ ] Tuist + SPM 의존성 있으면 `productTypes` 에 리소스 가진 패키지 `.framework` 명시
- [ ] `xcodebuild` 는 항상 `-workspace` (절대 `-project` 아님)
- [ ] `tuist test` 출력에서 "no tests to run" 나오면 즉시 실패로 간주
- [ ] CI 스크립트는 반드시 `tests="NN"` 숫자를 파싱해서 grep, 비어있으면 fail
- [ ] 워커 프롬프트에 "실행 증거 (숫자) 제출" 요구 고정

## 정책 박제
- [`gates/test-policy.md`](../../gates/test-policy.md) P2 — "실행 증거 제출"
- [`gates/test-policy-ios.md`](../../gates/test-policy-ios.md) — `-workspace` + `productTypes` 규칙 필수
