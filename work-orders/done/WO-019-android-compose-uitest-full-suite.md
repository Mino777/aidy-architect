# WO-019: Android Compose UI Test 전체 화면 자동화

**담당**: android
**우선순위**: P1-높음 (유저 직접 요청)
**상태**: backlog
**의존**: 없음

## 목표
실제 에뮬레이터에서 모든 화면, 모든 기능, 모든 입력값을 자동 검증하는 Compose UI Test 스위트를 구현한다.
QA 에이전트(@qa-tester)가 테스트 결과를 파싱하여 추가 검증할 수 있도록 JUnit XML 출력을 지원한다.

## 구현 요구사항

### Phase 1: 인프라 세팅
1. **androidTest 디렉토리 구성**: `app/src/androidTest/java/com/mino/aidy/`
2. **의존성 추가** (build.gradle.kts):
   - `androidTestImplementation("androidx.compose.ui:ui-test-junit4")`
   - `androidTestImplementation("androidx.test.ext:junit:1.1.5")`
   - `androidTestImplementation("androidx.test.espresso:espresso-core:3.5.1")`
   - `debugImplementation("androidx.compose.ui:ui-test-manifest")`
3. **테스트 헬퍼 작성**:
   - `ComposeTestRule` extension functions (waitUntilExists, typeTextAndClose 등)
   - 공통 wait helper (timeout 10초)
   - 스크린샷 캡처 (UiDevice takeScreenshot, 실패 시 자동)

### Phase 2: TestTag 전수 추가
모든 인터랙티브 요소에 `Modifier.testTag()` 추가. 네이밍 규칙: `{screen}_{element}_{type}`

**Auth 화면:**
- `auth_email_textfield`
- `auth_password_textfield`
- `auth_nickname_textfield`
- `auth_submit_button`
- `auth_toggle_button`
- `auth_forgot_password_button`
- `auth_error_text`

**Password Reset 화면:**
- `reset_email_textfield`
- `reset_token_textfield`
- `reset_password_textfield`
- `reset_submit_button`
- `reset_back_button`
- `reset_success_login_button`
- `reset_error_text`

**Chat 화면:**
- `chat_message_input`
- `chat_send_button`
- `chat_filter_toggle`
- `chat_filter_textfield`
- `chat_message_list`
- `chat_bubble_{index}`
- `chat_draft_banner`
- `chat_new_message_fab`
- `chat_copy_menu`
- `chat_streaming_indicator`

**Memory 화면:**
- `memory_search_textfield`
- `memory_category_{name}`
- `memory_list`
- `memory_item_{index}`
- `memory_empty_chat_button`
- `memory_detail_dialog`

**People 화면:**
- `people_list`
- `people_item_{index}`
- `people_empty_chat_button`

**Person Detail:**
- `person_back_button`
- `person_name_text`
- `person_relationship_text`
- `person_memory_{index}_correct`
- `person_memory_{index}_wrong`
- `person_delete_confirm`

**Settings 화면:**
- `settings_nickname_textfield`
- `settings_server_url_textfield`
- `settings_save_button`
- `settings_haptics_toggle`
- `settings_lock_toggle`
- `settings_clear_drafts_button`
- `settings_clear_errors_button`
- `settings_logout_button`
- `settings_refresh_stats_button`

### Phase 3: 화면별 테스트 케이스

모든 테스트는 실제 입력값을 사용. ViewModel을 직접 주입하여 서버 의존성 제거.

#### 1. AuthUITest
```
- testLoginSuccess: email="test@aidy.com", password="Test1234!" → 채팅 화면 도착
- testLoginFailure: email="wrong@aidy.com", password="wrong" → 에러 메시지 확인
- testSignupSuccess: email="new@aidy.com", password="New12345!", nickname="테스트유저" → 성공
- testSignupDuplicateEmail: → DUPLICATE_EMAIL 에러
- testModeToggle: Login ↔ Signup 전환
- testEmptyFieldValidation: 빈 필드 → 에러
```

#### 2. PasswordResetUITest
```
- testFullResetFlow: email → token → newPassword → 성공 → 로그인 복귀
- testInvalidToken: 잘못된 토큰 → 에러
- testShortPassword: 8자 미만 → 검증 에러
- testBackButton: 뒤로가기 → Auth 복귀
```

#### 3. ChatUITest
```
- testSendMessage: "오늘 점심 12000원 썼어" 입력 → 전송 → 응답 대기
- testMessageFilter: 필터 토글 → "점심" → 결과 확인
- testCharacterLimit: 200자 초과 제한
- testCopyMessage: 롱프레스 → 복사 메뉴 → 복사
- testScrollToBottom: 스크롤 업 → FAB → 하단 복귀
- testEmptyMessage: 빈 입력 → 전송 버튼 비활성
- testDraftBanner: 미전송 배너 표시 + 탭 재시도
```

#### 4. MemoryUITest
```
- testCategoryFilter: "금융" 칩 → 필터 → "전체" 복귀
- testSearch: "점심" → 결과 + 하이라이트
- testRecentSearch: 검색 후 포커스 → 최근 검색어
- testSwipeToDelete: 스와이프 → 삭제
- testSwipeToDetail: 반대 스와이프 → 상세 다이얼로그
- testEmptyState: 빈 상태 화면 + "채팅 시작하기"
- testPagination: 스크롤 → 추가 로딩
```

#### 5. PeopleUITest
```
- testPeopleList: 목록 로드 + 이름/관계 확인
- testPersonDetail: 인물 탭 → 상세 → 타임라인
- testFeedbackCorrect: "맞아" → 성공
- testFeedbackWrong: "틀려" → 확인 다이얼로그 → 삭제
- testBackNavigation: 상세 → 목록
- testEmptyState: 빈 화면
```

#### 6. SettingsUITest
```
- testNicknameChange: "새닉네임" → 저장
- testServerUrlChange: "http://localhost:8080" → 저장 + 메시지
- testHapticsToggle: ON/OFF
- testLockToggle: ON/OFF
- testClearDrafts: 초기화
- testClearErrors: 에러 로그 초기화
- testLogout: 로그아웃 → Auth 화면
- testServerStats: 통계 새로고침 확인
```

#### 7. NavigationUITest
```
- testTabNavigation: 채팅 → 피플 → 메모리 → 설정
- testDeepNavigation: People → Detail → Back
- testAuthToMain: 로그인 → 메인
- testLogoutToAuth: 로그아웃 → Auth
```

### Phase 4: QA 에이전트 연동
1. **JUnit XML 출력**: `./gradlew connectedAndroidTest` 기본 JUnit XML 생성
2. **결과 파일 경로**: `app/build/reports/androidTests/connected/`
3. **스크린샷 자동 저장**: 실패 시 `/sdcard/Pictures/` → pull to `test-results/screenshots/`
4. **실행 스크립트**: `scripts/run-ui-tests.sh` — 에뮬레이터 부팅 + 테스트 + 결과 수집

## 검증 기준
- [ ] `./gradlew connectedAndroidTest` 전체 통과
- [ ] 모든 화면에 testTag 추가됨
- [ ] 테스트 케이스 30건 이상
- [ ] QA 에이전트가 JUnit XML 파싱하여 검증 가능
- [ ] 기존 135 unit tests 통과 유지
