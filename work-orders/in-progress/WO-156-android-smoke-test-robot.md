# WO-156: Android Smoke Test + Robot Pattern 리팩터링

**담당**: android
**우선순위**: P2
**상태**: in-progress

## 배경
뱅크샐러드 iOS팀의 통합 UI 테스트 전략을 Android에도 동일하게 적용. Robot Pattern + Compose UI Test + 핵심 Smoke Test.

## 구현 요구사항

### 1. Robot Pattern 기반 클래스 구조
`app/src/androidTest/java/com/mino/aidy/robots/` 디렉토리에:
- `BaseRobot.kt` — 공통 (waitForNode, tapNode, typeInNode, assertDisplayed)
  - `ComposeTestRule` 기반
- `LoginRobot.kt` — 로그인 플로우 (email/password 입력 → 로그인 버튼)
- `ChatRobot.kt` — 메시지 전송, AI 응답 대기, 메모리 확인
- `PeopleRobot.kt` — 인물 탭 이동, 인물 선택, 프로필 확인
- `MemoryRobot.kt` — 메모리 탭, 메모리 상세 진입

### 2. 테스트 계정
- `uitest@aidy.com` / `AidyTest2026!` 하드코딩 (§8 Test Account)
- `LoginRobot`에서 사용

### 3. Smoke Test Suite
`app/src/androidTest/java/com/mino/aidy/smoke/` 디렉토리에:
- `SmokeTest_CoreFlow.kt` — 핵심 유저 플로우:
  1. 로그인
  2. 채팅에서 메시지 전송 ("오늘 김민수와 점심 먹었어")
  3. AI 응답 수신 확인
  4. 기억 확인 카드 표시 확인
  5. 인물 탭에서 "김민수" 존재 확인
  6. 인물 프로필 진입 → 메모리 존재 확인
- `createAndroidComposeRule<MainActivity>()` 사용 (실제 Activity 기반)

### 4. 기존 UITest 리팩터링
- `ChatUITest`, `PeopleUITest` 등에서 반복되는 로그인/setup → `LoginRobot` 사용
- 기존 테스트 깨지지 않게 유지

## 완료 기준
- [ ] ./gradlew testDebugUnitTest PASS + 숫자 보고
- [ ] Robot 클래스 5개 생성
- [ ] SmokeTest_CoreFlow 작성 (에뮬레이터에서 실행 가능)
- [ ] 기존 UITest가 Robot 사용으로 리팩터링됨
