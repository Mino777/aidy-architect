# autoceo Session 9 — UI Test Automation Sprint

**날짜**: 2026-04-17
**라운드**: 5 (R1 deferred, R2-R4 실행, R5 compound)
**WO 처리**: WO-018 (iOS XCUITest), WO-019 (Android Compose UI Test)

## 라운드 요약

| Round | 작업 | 결과 |
|-------|------|------|
| R1 | WO-016 billing 정상 시나리오 검증 | DEFERRED — billing 미복구, fallback 정상 작동 확인 |
| R2 | WO-018 (iOS) + WO-019 (Android) dispatch | iOS 4커밋 42테스트, Android 3커밋 35테스트 |
| R3 | Gate-1 검증 | iOS: CONDITIONAL PASS (1건 fix), Android: PASS 8/8 |
| R4 | QA 에이전트 ui 모드 추가 | iOS + Android qa-tester.md 에 `ui` 모드 추가 |
| R5 | Compound 문서화 | 본 문서 |

## 주요 결과

### WO-018: iOS XCUITest 전체 화면 자동화
- **Tuist 타겟**: `AidyUITests` (.uiTests product)
- **Accessibility Identifier**: 전 화면 전수 추가 (네이밍: `{screen}_{element}_{type}`)
- **테스트 42건**: Auth(6), PasswordReset(4), Chat(7), Memory(7), People(6), Settings(8), Navigation(4)
- **입력값**: 실제 email/password/메시지 사용
- **실행 스크립트**: `scripts/run-ui-tests.sh` → JUnit XML 변환
- **Gate-1 수정**: `chatRetryButton` → `chat_retry_button` (네이밍 컨벤션 위반 1건)

### WO-019: Android Compose UI Test 전체 화면 자동화
- **TestTags.kt**: 86개 상수 정의 (전 화면)
- **의존성**: compose-ui-test-junit4, espresso-core, mockk-android
- **테스트 35건**: Auth(5), PasswordReset(4), Chat(5), Memory(5), People(5), Settings(7), Navigation(4)
- **입력값**: 실제 email/password/메시지 사용
- **실행 스크립트**: `scripts/run-ui-tests.sh` → 에뮬레이터 자동 부팅 + JUnit XML 수집

### QA 에이전트 연동
- iOS/Android qa-tester에 `ui` 모드 추가
- UI 테스트 실행 + JUnit XML 파싱 + 화면별 통과율 보고
- `@qa-tester ui` 명령으로 QA 검증 자동화 가능

## 비차단 관찰 (향후 개선)

1. **iOS**: 시뮬레이터 기본값 `iPhone 17 Pro / OS 26.3.1` — 현재 Xcode에 없을 수 ���음 (env var override 가능)
2. **Android**: `CHAT_STREAMING_INDICATOR` testTag가 ChatScreen에 미적용
3. **Android**: PeopleUITest가 빈 mock으로 vacuous pass 가능
4. **Android**: NavigationShell에 Memory 탭 누락 → 네비게이션 테스트 불완전
5. **Billing**: server/android primary (github-hosted) 여전히 실패, fallback으로 동작 중

## 커밋 현황

| 워커 | 커밋 수 | 주요 커밋 |
|------|---------|----------|
| iOS | 5 | identifier 전수 + 42건 테스트 + 스크립트 + fix + QA 모드 |
| Android | 4 | testTag + 35건 테스트 + 스크립트 + QA 모드 |
| Server | 0 | 미참여 |

## 토큰 경제성

- 2-way 병렬 (3-way 축소 정책 준수)
- 5분 폴링 간격 (공격적 2분 → 보수적 5분)
- 10라운드 → 5라운드 제한 (burst 방지)
- Server idle 유지 (불필요한 토큰 소비 방지)

## 다음 할 일

1. **실제 시뮬레이터/에뮬레이터에서 UI 테스트 실행** → green 확인
2. **WO-016 billing 복구 시 정상 시나리오 검증**
3. **WO-011 (Swift 6 Sendable)** — iOS backlog
4. **WO-013 (워크플로 통합)** — iOS backlog
5. **비차단 관찰 수정** — streaming indicator tag, People mock, Memory tab
