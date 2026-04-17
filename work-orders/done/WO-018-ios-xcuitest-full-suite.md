# WO-018: iOS XCUITest 전체 화면 UI 자동화

**담당**: ios
**우선순위**: P1-높음 (유저 직접 요청)
**상태**: backlog
**의존**: 없음

## 목표
실제 시뮬레이터에서 모든 화면, 모든 기능, 모든 입력값을 자동 검증하는 XCUITest 스위트를 구현한다.
QA 에이전트(@qa-tester)가 테스트 결과를 파싱하여 추가 검증할 수 있도록 JUnit XML 출력을 지원한다.

## 구현 요구사항

### Phase 1: 인프라 세팅
1. **Tuist에 XCUITest 타겟 추가** — `AidyUITests` 타겟
2. **Launch Arguments/Environment** 설정 — 테스트 서버 URL, 테스트 유저 정보 전달
3. **테스트 헬퍼 작성**:
   - `XCUIApplication` launch helper (launch arguments 주입)
   - 공통 wait/tap/type 헬퍼 (timeout 10초)
   - 스크린샷 캡처 헬퍼 (실패 시 자동 첨부)

### Phase 2: Accessibility Identifier 전수 추가
모든 인터랙티브 요소에 `.accessibilityIdentifier()` 추가. 네이밍 규칙: `{screen}_{element}_{type}`

**Auth 화면:**
- `auth_email_textfield`
- `auth_password_textfield`
- `auth_nickname_textfield`
- `auth_submit_button`
- `auth_mode_picker` (Login/Signup 토글)
- `auth_forgot_password_button`
- `auth_error_text`

**Password Reset 화면:**
- `reset_email_textfield`
- `reset_token_textfield`
- `reset_password_textfield`
- `reset_submit_button` (각 스텝 공통)
- `reset_close_button`
- `reset_success_login_button`
- `reset_error_text`

**Chat 화면:**
- `chat_message_input`
- `chat_send_button`
- `chat_search_toggle`
- `chat_search_textfield`
- `chat_message_list`
- `chat_bubble_{index}`
- `chat_retry_button` (기존)
- `chat_draft_banner`
- `chat_new_message_fab`
- `chat_people_confirm_correct`
- `chat_people_confirm_wrong`

**Memory 화면:**
- `memory_search_textfield`
- `memory_category_{name}` (전체, finance, schedule, ...)
- `memory_list`
- `memory_item_{index}`
- `memory_empty_chat_button`

**People 화면:**
- `people_list`
- `people_item_{index}`
- `people_empty_chat_button`

**Person Detail 화면:**
- `person_back_button`
- `person_name_text`
- `person_relationship_text`
- `person_memory_{index}_correct`
- `person_memory_{index}_wrong`

**Settings 화면:**
- `settings_nickname_textfield`
- `settings_server_url_textfield`
- `settings_save_button`
- `settings_haptics_toggle`
- `settings_biometric_toggle`
- `settings_clear_drafts_button`
- `settings_clear_errors_button`
- `settings_logout_button`
- `settings_server_stats_section`

### Phase 3: 화면별 테스트 케이스

모든 테스트는 실제 입력값을 사용한다. 서버 미연동 시 Mock 서버 또는 Launch Arguments로 stub.

#### 1. AuthUITests
```
- testLoginSuccess: email="test@aidy.com", password="Test1234!" → 채팅 탭 도착
- testLoginFailure: email="wrong@aidy.com", password="wrong" → 에러 메시지 확인
- testSignupSuccess: email="new@aidy.com", password="New12345!", nickname="테스트유저" → 성공
- testSignupDuplicateEmail: 중복 이메일 → DUPLICATE_EMAIL 에러
- testModeToggle: Login ↔ Signup 전환 확인
- testEmptyFieldValidation: 빈 필드 제출 → 에러
```

#### 2. PasswordResetUITests
```
- testFullResetFlow: email → token → newPassword → 성공 화면 → 로그인 복귀
- testInvalidToken: 잘못된 토큰 입력 → 에러 메시지
- testShortPassword: 8자 미만 비밀번호 → 검증 에러
- testCloseButton: 각 스텝에서 닫기 → Auth 화면 복귀
```

#### 3. ChatUITests
```
- testSendMessage: "오늘 점심 12000원 썼어" 입력 → 전송 → AI 응답 수신 대기
- testMessageFilter: 검색 토글 → "점심" 입력 → 필터 결과 확인
- testCharacterLimit: 200자 초과 입력 시도 → 제한 확인
- testCharacterWarning: 150자 이상 → 카운터 표시
- testCopyMessage: 메시지 롱프레스 → 복사 메뉴
- testScrollToBottom: 스크롤 업 → FAB 표시 → 탭 → 하단 복귀
- testEmptyMessage: 빈 메시지 전송 버튼 비활성 확인
```

#### 4. MemoryUITests
```
- testCategoryFilter: "금융" 칩 탭 → 필터 적용 → "전체" 복귀
- testSearch: "점심" 검색 → 결과 확인
- testRecentSearch: 검색 후 포커스 → 최근 검색어 표시
- testSwipeToDelete: 메모리 항목 스와이프 → 삭제 확인
- testEmptyState: 메모리 없을 때 "채팅 시작하기" 버튼 확인
- testPullToRefresh: 당겨서 새로고침
- testPagination: 스크롤 → 추가 로딩 확인
```

#### 5. PeopleUITests
```
- testPeopleList: 인물 목록 로드 + 이름/관계 표시 확인
- testPersonDetail: 인물 탭 → 상세 화면 → 타임라인 확인
- testFeedbackCorrect: "맞아" 버튼 → 성공 확인
- testFeedbackWrong: "틀려" 버튼 → 삭제 확인 다이얼로그 → 확인
- testBackNavigation: 상세 → 목록 복귀
- testEmptyState: 인물 없을 때 빈 화면 + "채팅 시작하기"
```

#### 6. SettingsUITests
```
- testNicknameChange: "새닉네임" 입력 → 저장
- testServerUrlChange: "http://localhost:8080" 입력 → 저장
- testHapticsToggle: 토글 ON/OFF
- testBiometricToggle: 토글 시도 (시뮬레이터 제약 확인)
- testClearDrafts: 드래프트 초기화 → 확인
- testClearErrors: 에러 로그 초기화 → 확인
- testLogout: 로그아웃 → Auth 화면 이동
- testServerStats: 서버 통계 섹션 표시 확인
```

#### 7. NavigationUITests
```
- testTabNavigation: 채팅 → 피플 → 메모리 → 설정 탭 전환
- testDeepNavigation: People → PersonDetail → Back
- testAuthToMain: 로그인 → 메인 화면 전환
- testLogoutToAuth: 설정 → 로그아웃 → Auth 화면
```

### Phase 4: QA 에이전트 연동
1. **JUnit XML 출력**: `xcodebuild test` 결과를 `xcresulttool`로 JUnit XML 변환
2. **테스트 결과 파일**: `~/Develop/aidy-ios/test-results/ui-test-results.xml`
3. **스크린샷 자동 첨부**: 실패 시 `XCTAttachment`로 스크린샷 저장
4. **실행 스크립트**: `scripts/run-ui-tests.sh` — 시뮬레이터 부팅 + 테스트 실행 + 결과 변환

## 검증 기준
- [ ] `xcodebuild test -scheme Aidy -destination 'platform=iOS Simulator,...'` 전체 통과
- [ ] 모든 화면에 accessibility identifier 추가됨
- [ ] 테스트 케이스 30건 이상
- [ ] QA 에이전트가 test-results XML을 파싱하여 검증 가능
- [ ] 기존 124 unit tests 통과 유지
