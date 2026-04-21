# WO-155: iOS Smoke Test + Robot Pattern 리팩터링

**담당**: ios
**우선순위**: P2
**상태**: backlog

## 배경
뱅크샐러드 iOS팀의 통합 UI 테스트 전략 참고. Robot Pattern으로 화면별 재사용 가능한 테스트 헬퍼 구축 + 핵심 플로우 Smoke Test.

## 구현 요구사항

### 1. Robot Pattern 기반 클래스 구조
`Projects/App/UITests/Robots/` 디렉토리에:
- `BaseRobot.swift` — 공통 (waitForElement, tap, typeText, assertExists)
- `LoginRobot.swift` — 로그인 플로우 (email/password 입력 → 로그인)
- `ChatRobot.swift` — 메시지 전송, AI 응답 대기, 메모리 확인 카드 상호작용
- `PeopleRobot.swift` — 인물 탭 이동, 인물 선택, 프로필 확인
- `MemoryRobot.swift` — 메모리 탭, 메모리 상세 진입, 피드백

### 2. 테스트 계정
- `uitest@aidy.com` / `AidyTest2026!` 하드코딩 (§8 Test Account)
- `LoginRobot`에서 사용

### 3. Smoke Test Suite
`Projects/App/UITests/SmokeTests/` 디렉토리에:
- `SmokeTest_CoreFlow.swift` — 핵심 유저 플로우:
  1. 로그인
  2. 채팅에서 메시지 전송 ("오늘 김민수와 점심 먹었어")
  3. AI 응답 수신 확인
  4. 기억 확인 카드 표시 확인
  5. 인물 탭에서 "김민수" 존재 확인
  6. 인물 프로필 진입 → 메모리 존재 확인

### 4. 기존 UITest 리팩터링
- `ChatUITests`, `PeopleUITests` 등에서 `loginIfNeeded()` 중복 → `LoginRobot` 사용으로 교체
- 기존 테스트 깨지지 않게 유지

## 완료 기준
- [ ] tuist build PASS
- [ ] Robot 클래스 5개 생성
- [ ] SmokeTest_CoreFlow 작성 (시뮬레이터에서 실행 가능)
- [ ] 기존 UITest가 Robot 사용으로 리팩터링됨
