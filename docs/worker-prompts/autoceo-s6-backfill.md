# 워커 프롬프트 로그 — autoceo-s6 (백필)

> 2026-04-16 autoceo 6차 스프린트 R1~R9의 dispatch 프롬프트 원문 (architect 컨텍스트에서 복원).
> R9는 토큰 리밋 리셋 직후 429로 유실 — 재전송 프롬프트만 기록. 실제 동작 완료 여부 별도 확인 필요.
> R10 이후는 `architect-cli.sh tmux_send` 자동 로깅이 `YYYY-MM-DD.md` 에 실시간 기록.

---

## R1 — tmux flush 자동화 + UX 폴리시

### server
```
[R1-server-s6] 작업 지시: 테스트 실행 시간 측정 + 리포트
1. test-policy-server.md 재확인
2. 기존 테스트들에 @Timeout(value=5, unit=TimeUnit.SECONDS) 추가 (단위 테스트 전체) — 플레이키 방지
3. ./gradlew test 실행 후 build/reports/tests/test/index.html 존재 확인 (이미 자동 생성)
4. ThroughputBenchmarkTest 측정 결과를 stdout에 추가 로깅 (p50/p95/p99)
5. 실행 증거: ./gradlew test — 170+ tests · 0 failures

금지: 프로덕션 코드 로직 수정. 새 dependency.
커밋: [R1-server] test: 테스트 timeout + 벤치마크 로깅 강화 (파일 5개 이하)
테스트 숫자 커밋 메시지에 포함.
```

### ios
```
[R1-ios-s6] 작업 지시: 채팅 메시지 복사 기능
1. test-policy-ios.md 재확인
2. Chat 메시지 버블을 길게 누르면 Context Menu 노출 — '복사' 버튼 (UIPasteboard.general.string)
3. ChatView의 메시지 Row에 .contextMenu { Button('복사') { ... } }
4. TestStore 테스트: 액션 전달 + pasteboard 의존성 주입으로 검증
5. 실행 증거: xcodebuild test -workspace Aidy.xcworkspace -scheme Aidy ... 89+ tests

금지: 새 3rd party. Info.plist 대거 수정.
커밋: [R1-ios] feat: 채팅 메시지 복사 (파일 4개 이하)
테스트 숫자 커밋 메시지에 포함.
```

### android
```
[R1-android-s6] 작업 지시: 채팅 메시지 복사 기능
1. test-policy-android.md 재확인
2. 채팅 버블 long-press → DropdownMenu or ModalBottomSheet 노출, '복사' 항목
3. ClipboardManager (androidx.compose.ui.platform.LocalClipboardManager)로 텍스트 복사
4. ViewModel 변경 없이 UI 레벨 처리 가능 — 선택 시 Snackbar로 '복사됨'
5. UI 로직 단위 테스트 2건 이상 (복사 액션의 상태 변화)
6. 실행 증거: ./gradlew testDebugUnitTest 85+ tests

금지: 새 dependency (LocalClipboardManager는 Compose 기본).
커밋: [R1-android] feat: 채팅 메시지 복사 (파일 4개 이하)
테스트 숫자 커밋 메시지에 포함.
```

---

## R2 — SSE Phase 2 Anthropic streaming

### server
```
[R2-server-s6] 작업 지시: SSE Phase 2 — Anthropic streaming 실연동
1. ADR-008 재확인
2. AiService에 새 메서드 chatStream(user, history, memories, userMessage, onToken: (String)->Unit, onDone: (AiReply)->Unit, onError: (Throwable)->Unit)
   - 기존 callAndParse/executeWithRetry 흐름 유지 + 요청 body에 stream: true 추가
   - OkHttp response body 의 source()로 라인 단위 읽기 (event: ..., data: {...})
   - Anthropic API SSE 이벤트 타입: 'content_block_delta' (text_delta type) 처리, 'message_stop' 에서 종료
   - Circuit Breaker 래핑 유지 (OPEN 시 즉시 onError로 AI_UNAVAILABLE)
3. ChatController.chatStream 엔드포인트를 fake-stream → 실제 streaming 로 교체
   - SseEmitter.send(token), memory 있으면 send(memory), 완료 시 send(done)
4. 기존 non-stream chat() 메서드 무변경 (공존)
5. 테스트:
   - MockMvc로 stream 엔드포인트 호출 + asyncDispatch로 이벤트 검증 (기존 테스트 업데이트 또는 새 테스트)
   - AiService stream을 mock (AiService 전체를 MockBean) — 실제 Anthropic 호출 금지
6. 실행 증거: ./gradlew test 170+ tests 유지

금지: 새 dependency. 기존 chat() 파괴.
커밋: [R2-server] feat: SSE Phase 2 Anthropic streaming 실연동 (파일 8개 이하)
테스트 숫자 커밋 메시지에 포함.
```

### ios
```
[R2-ios-s6] 작업 지시: 대화 히스토리 필터/검색 개선
1. Chat 화면의 히스토리가 길어지면 scroll 위치 관리 개선 — 새 메시지 수신 시 바닥 고정, 사용자가 스크롤 중이면 고정 해제 + '새 메시지' 플로팅 버튼
2. 채팅 히스토리에 간단한 키워드 필터 (상단 검색창 토글)
3. TestStore 테스트 3건
4. 실행 증거: xcodebuild test ... 92+ tests

금지: SSE 구독 (R3 예정). 히스토리 파싱 변경.
커밋: [R2-ios] feat: 채팅 스크롤 고정 개선 + 히스토리 필터 (파일 5개 이하)
테스트 숫자 커밋 메시지에 포함.
```

### android
```
[R2-android-s6] 작업 지시: 대화 히스토리 필터/검색 개선
1. 채팅 LazyColumn에 새 메시지 수신 시 바닥 고정 로직 개선 — derivedStateOf로 사용자 스크롤 상태 감지, 필요 시 '새 메시지' FAB
2. 채팅 화면 상단에 간단 필터 TextField (토글 가능) — messages를 필터링해 표시
3. ViewModel 테스트 3건 이상 (필터 로직 단위 검증)
4. 실행 증거: ./gradlew testDebugUnitTest 92+ tests

금지: 새 dependency.
커밋: [R2-android] feat: 채팅 스크롤 개선 + 필터 (파일 4개 이하)
테스트 숫자 커밋 메시지에 포함.
```

---

## R3 — iOS SSE 구독 + 서버 SSE 테스트 + Android 메모리 상세

### ios
```
[R3-ios-s6] 작업 지시: SSE 스트리밍 채팅 구독
1. ADR-008 + specs/api-contract.md 의 /api/chat/stream 확인
2. SSEClient 의존성 (@DependencyClient) 신규:
   - stream(message: String, token: String) -> AsyncThrowingStream<SSEEvent, Error>
   - URLSession.shared.bytes(for: URLRequest) 로 line-by-line 읽기
   - 'event: token/memory/done/error' 파싱 + data 디코드
   - enum SSEEvent { case token(String), memory(...), done(messageId: Int64), error(code: String, message: String) }
3. ChatFeature: 기존 send() 에 옵션 useStreaming (기본 true) — true면 SSEClient.stream 사용, for await 루프에서 token 수신 시 message.content 점진 업데이트
4. ChatView: 스트리밍 중 현재 응답에 커서/점점점 애니메이션 (3개 점 시퀀스)
5. 에러 발생 시 기존 ApiError 흐름으로 복귀 (isRetryable 검사)
6. TestStore 테스트: 스트리밍 성공 (3 tokens 순차) / error 이벤트 / done
7. 실행 증거: xcodebuild test ... 96+ tests

금지: URLSession 외 새 네트워크 라이브러리. 기존 POST 엔드포인트 제거.
커밋: [R3-ios] feat: SSE 스트리밍 채팅 구독 (파일 6개 이하)
테스트 숫자 커밋 메시지에 포함.
```

### server
```
[R3-server-s6] 작업 지시: SSE 엔드포인트 회귀 테스트 강화
1. 기존 ChatControllerTest에 SSE 시나리오 보강:
   - Anthropic 클라이언트 mock → token 3건 + memory 1건 + done 순차 emit 시나리오
   - error 시나리오 (Circuit Breaker OPEN → error 이벤트)
   - validation 실패 (빈 메시지) → error 400 응답
2. AsyncContext timeout 기본 30s 확인 (SseEmitter)
3. 실행 증거: ./gradlew test 175+ tests

금지: AiService.chatStream 구현 변경.
커밋: [R3-server] test: SSE 엔드포인트 시나리오 테스트 강화 (파일 2개 이하)
테스트 숫자 커밋 메시지에 포함.
```

### android
```
[R3-android-s6] 작업 지시: 메모리 스와이프 액션 확장 (편집)
1. MemoryScreen SwipeToDismissBox: 기존 endToStart(삭제)에 추가로 startToEnd 방향 '편집' 액션 제스처
   실제 편집 다이얼로그는 이번 라운드에서 간단한 EditableMemoryDialog (title/content만) 구현
   PUT /api/memories/{id} 엔드포인트는 아직 없음 — 클라에서만 제스처 + 다이얼로그 구현, '저장' 시 현재 api에 맞춰 일단 안내 토스트
   (이 작업은 UI만. 서버 엔드포인트는 다음 스프린트)
2. 또는 더 안전하게: 편집 대신 '상세보기' 액션 — 메모리 상세 다이얼로그 표시
3. ViewModel 테스트 2건
4. 실행 증거: ./gradlew testDebugUnitTest 96+ tests

금지: 서버 엔드포인트 없이 PUT 호출. 새 dependency.
커밋: [R3-android] feat: 메모리 스와이프 상세보기 액션 추가 (파일 4개 이하)
테스트 숫자 커밋 메시지에 포함.
```

---

## R4 — Android SSE 구독 + 서버 since 파라미터 + iOS 입력창

### android
```
[R4-android-s6] 작업 지시: SSE 스트리밍 채팅 구독
1. ADR-008 + specs/api-contract.md /api/chat/stream 확인
2. SSEClient 신규 (클래스 또는 Repository):
   - fun stream(message: String, token: String): Flow<SseEvent>
   - OkHttp (기존 사용 중 retrofit 내부 — 직접 OkHttpClient 사용) 으로 line-by-line 읽기 (BufferedSource.readUtf8Line)
   - 이벤트 파싱: 'event: token/memory/done/error' + data JSON
   - sealed class SseEvent { data class Token(val text: String); data class Memory(...); data class Done(val messageId: Long); data class Error(val code: String, val message: String) }
3. ChatViewModel: useStreaming 플래그 (기본 true) — true면 sseClient.stream collect, token append로 현재 message 업데이트
4. ChatScreen: 스트리밍 중 마지막 메시지에 점점점 인디케이터 (AnimatedContent or infinite animation)
5. 에러는 기존 ApiException 흐름으로 매핑 (isRetryable)
6. 테스트: SSEClient 단위 (fake BufferedSource) + ViewModel 스트리밍 플로우
7. 실행 증거: ./gradlew testDebugUnitTest 100+ tests

금지: 새 SSE 라이브러리 (OkHttp는 기존). okhttp-sse 포함 모듈 사용 금지 — 수동 파싱만.
커밋: [R4-android] feat: SSE 스트리밍 채팅 구독 (파일 7개 이하)
테스트 숫자 커밋 메시지에 포함.
```

### server
```
[R4-server-s6] 작업 지시: 채팅 이력 관리 개선
1. GET /api/chat/history 쿼리 파라미터 추가: ?since=ISO timestamp (optional) — 이 시각 이후 메시지만 반환
2. since 없으면 기존 동작 (최근 20건)
3. since 있으면 해당 시각 이후 오름차순 (createdAt ASC)
4. validation: since가 올바른 ISO 8601 아니면 400 VALIDATION_ERROR
5. 테스트 컨트롤러 4건 이상
6. 실행 증거: ./gradlew test 179+ tests

금지: api-contract.md 수정 (architect가 처리). 기존 응답 스키마 변경.
커밋: [R4-server] feat: /api/chat/history since 쿼리 파라미터 (파일 5개 이하)
테스트 숫자 커밋 메시지에 포함.
inbox/chat-history-since-preview.md 에 스펙 초안 남김.
```

### ios
```
[R4-ios-s6] 작업 지시: 입력창 자동 스크롤 조정 + 키보드 안전 영역
1. ChatView: 키보드 올라올 때 입력창/스크롤 뷰 위치 안정화
2. 멀티라인 입력 지원 (최대 4줄까지 자동 확장)
3. 입력창 characters counter (200자 제한, 150+에서 노란색, 200 초과 시 전송 비활성)
4. TestStore 테스트 2건 (입력 길이 제한 로직)
5. 실행 증거: xcodebuild test ... 97+ tests

금지: SafeAreaInset 범위 파괴.
커밋: [R4-ios] feat: 채팅 입력창 개선 — 멀티라인 + 길이 제한 (파일 4개 이하)
테스트 숫자 커밋 메시지에 포함.
```

---

## R5 — Password Reset 서버 + SSE 회복성

### server
```
[R5-server-s6] 작업 지시: Password Reset (request/confirm)
1. specs/api-contract.md v0.2.5 (password reset) 섹션 읽기
2. 신규 Entity PasswordResetToken (id, userId, token, expiresAt, usedAt nullable, createdAt)
   Flyway V11: create table password_reset_tokens (기존 V1~V10 무변경)
3. PasswordResetTokenRepository + Service:
   - requestReset(email): 사용자 존재 시 토큰 생성 (32자 random url-safe, SecureRandom) + expires 30min + 로그 info('password reset token for {email}: {token}')
   - 사용자 없으면 no-op (응답은 동일 성공)
   - confirmReset(token, newPassword): 토큰 찾기 → 만료/usedAt 체크 → bcrypt 해싱 → User.passwordHash 업데이트 → token.usedAt = now
4. AuthController 2 엔드포인트:
   - POST /api/auth/password/reset/request — 공개 (RateLimit auth bucket 공유)
   - POST /api/auth/password/reset/confirm — 공개 (RateLimit)
5. ErrorCode.PASSWORD_RESET_TOKEN_INVALID (400) 추가
6. 테스트 필수: request / confirm 성공 / 만료 토큰 / 이미 사용 / 존재하지 않는 이메일 (no-op)
7. 실행 증거: ./gradlew test 187+ tests

금지: 실제 이메일 발송 (로그만). JWT refresh rotation.
커밋: [R5-server] feat: Password reset — request/confirm (파일 10개 이하)
테스트 숫자 커밋 메시지에 포함.
```

### ios
```
[R5-ios-s6] 작업 지시: SSE 성능 계측 + 회복 UX
1. SSEClient stream 이벤트에 latency (첫 토큰까지 시간) 계측
2. 첫 토큰 3초 이내 안 오면 '연결 중...' 인디케이터 강화
3. 중간 끊김 발생 (URLSession 에러) 시 자동 1회 재시도 — 실패 시 기존 ApiError 흐름
4. TestStore 테스트 2건 (재시도 성공/실패)
5. 실행 증거: xcodebuild test ... 99+ tests

금지: 다중 재시도 (1회만). 세션 자동 종료.
커밋: [R5-ios] feat: SSE 연결 회복 + latency 계측 (파일 4개 이하)
테스트 숫자 커밋 메시지에 포함.
```

### android
```
[R5-android-s6] 작업 지시: SSE 성능 계측 + 회복 UX
1. SseClient.stream 에 첫 토큰 latency 측정 (System.currentTimeMillis 차이)
2. 3초 이내 첫 토큰 없으면 '연결 중...' 상태 (ViewModel state)
3. 중간 IOException 발생 시 1회 자동 재시도 (동일 요청), 실패 시 기존 에러 흐름
4. ViewModel/Client 테스트 2건 (재시도 success/fail)
5. 실행 증거: ./gradlew testDebugUnitTest 107+ tests

금지: 다중 재시도. 백프레셔 변경.
커밋: [R5-android] feat: SSE 연결 회복 + latency 계측 (파일 4개 이하)
테스트 숫자 커밋 메시지에 포함.
```

---

## R6 — Password reset UI + 서버 보안 강화

### ios
```
[R6-ios-s6] 작업 지시: Password Reset UI 플로우
1. api-contract.md v0.2.5 확인 (request/confirm 2단계)
2. AuthView에 '비밀번호 찾기' 링크 추가 → PasswordResetView 표시 (Sheet 또는 Push)
3. PasswordResetFeature (신규):
   State: step (.email/.token/.newPassword/.success), email, token, newPassword, isLoading, error
   Actions: emailChanged, emailSubmitted, tokenChanged, tokenSubmitted, newPasswordChanged, confirmTapped, reset
4. APIClient: resetPasswordRequest(email), resetPasswordConfirm(token, newPassword)
5. 2단계 UI: 이메일 입력 → '토큰을 이메일에서 확인해 입력' 안내 → 토큰 + 새 비번 입력 → 성공 화면
6. TestStore 테스트: request 성공/실패 / confirm 성공/token 무효 / 비번 길이
7. 실행 증거: xcodebuild test ... 103+ tests

금지: 실제 이메일 통합.
커밋: [R6-ios] feat: Password reset UI 플로우 (파일 7개 이하)
테스트 숫자 커밋 메시지에 포함.
```

### android
```
[R6-android-s6] 작업 지시: Password Reset UI 플로우
1. api-contract.md v0.2.5 확인
2. AuthScreen: '비밀번호 찾기' 링크 → PasswordResetScreen nav
3. PasswordResetViewModel:
   state: PasswordResetUiState (sealed — Email/Token/NewPassword/Success)
   함수: submitEmail(), submitTokenAndNewPassword()
4. AidyApiService: @POST('api/auth/password/reset/request'), @POST('api/auth/password/reset/confirm')
5. 2단계 Compose UI
6. ViewModel 테스트 5건 (성공/token 무효/비번 길이/에러 처리)
7. 실행 증거: ./gradlew testDebugUnitTest 113+ tests

금지: 실제 이메일.
커밋: [R6-android] feat: Password reset UI 플로우 (파일 7개 이하)
테스트 숫자 커밋 메시지에 포함.
```

### server
```
[R6-server-s6] 작업 지시: Password reset 보안 강화 + 쿨다운
1. 동일 이메일에 대해 5분 내 재요청 시 기존 유효 토큰 재사용 (또는 no-op, 새 토큰 발급 안 함) — 남용 방지
2. 사용 완료된 토큰 조회 시 동일한 PASSWORD_RESET_TOKEN_INVALID 에러
3. 만료된 토큰은 매 confirm 호출 시 자동 정리 안함 (별도 작업) — 단, 응답에만 포함 안 시킴
4. 테스트 3건 추가 (쿨다운 / 이미 사용 / 만료)
5. 실행 증거: ./gradlew test 195+ tests

금지: 기존 엔드포인트 응답 스키마 변경.
커밋: [R6-server] feat: Password reset 쿨다운 + 보안 강화 (파일 4개 이하)
테스트 숫자 커밋 메시지에 포함.
```

---

## R7 — pg_trgm GIN + 검색 UX

### server
```
[R7-server-s6] 작업 지시: pg_trgm GIN 인덱스 — 메모리 검색 최적화 (V12)
1. Flyway V12__add_pg_trgm_for_memory_search.sql 신규
2. 내용:
   -- PostgreSQL pg_trgm extension + GIN indexes
   -- H2 테스트 프로파일은 flyway.enabled=false (기존 패턴)
   CREATE EXTENSION IF NOT EXISTS pg_trgm;
   CREATE INDEX IF NOT EXISTS idx_memories_content_trgm ON memories USING gin (content gin_trgm_ops);
   CREATE INDEX IF NOT EXISTS idx_memories_title_trgm ON memories USING gin (title gin_trgm_ops);
3. 파일 상단 주석으로 PostgreSQL 전용 명시 + H2 테스트 시 실행 안 됨 안내
4. MemoryRepository.searchByKeyword — 기존 LIKE 그대로 유지 (GIN 인덱스가 자동 사용됨)
5. 테스트 영향 없음 (H2 skip) — ./gradlew test 195+ tests 유지
6. 실행 증거: ./gradlew test

금지: 기존 V1~V11 수정. Entity 변경.
커밋: [R7-server] perf: pg_trgm GIN 인덱스 V12 마이그레이션 (파일 2개 이하)
테스트 숫자 커밋 메시지에 포함.
```

### ios
```
[R7-ios-s6] 작업 지시: 검색 UX 개선 — 최근 검색어 + 하이라이트
1. MemoryView 검색: 최근 검색어 5건 로컬 저장 (UserDefaults) — SearchHistoryClient 의존성
2. 검색 결과 리스트에서 키워드 매칭 부분 하이라이트 (굵게 또는 노란 배경)
3. TestStore 테스트: 최근 검색어 저장/로드/최대 5건 rolling
4. 실행 증거: xcodebuild test ... 113+ tests

금지: 서버 API 변경.
커밋: [R7-ios] feat: 검색 최근어 + 하이라이트 (파일 5개 이하)
테스트 숫자 커밋 메시지에 포함.
```

### android
```
[R7-android-s6] 작업 지시: 검색 UX 개선 — 최근 검색어 + 하이라이트
1. MemoryViewModel: 최근 검색어 5건 EncryptedSharedPreferences 저장
2. MemoryScreen: 검색창 포커스 시 최근 검색어 칩 노출, 매칭 결과 키워드 하이라이트
3. ViewModel 테스트 3건 이상
4. 실행 증거: ./gradlew testDebugUnitTest 117+ tests

금지: 새 dependency.
커밋: [R7-android] feat: 검색 최근어 + 하이라이트 (파일 5개 이하)
테스트 숫자 커밋 메시지에 포함.
```

---

## R8 — E2E 통합 테스트

### server
```
[R8-server-s6] 작업 지시: Password reset + SSE E2E 통합 테스트
1. test/e2e/PasswordResetE2ETest.kt 신규:
   - signup → request-reset → (로그에서 토큰 추출 또는 Repository 직접 조회) → confirm → 새 비번으로 login 성공 시나리오
   - 만료 토큰 시나리오 (직접 DB 업데이트)
   - 이미 사용된 토큰 확인
2. test/e2e/ChatStreamE2ETest.kt 신규 (기존 SSE 시나리오 테스트 확장):
   - signup + login → /api/chat/stream 호출 → 이벤트 시퀀스 검증 (token+ memory? done)
   - Circuit Breaker OPEN 상태에서 /api/chat/stream → error 이벤트 + AI_UNAVAILABLE
   - 빈 메시지 → 400 VALIDATION_ERROR (스트림 시작 안 됨)
3. 실행 증거: ./gradlew test 202+ tests

금지: AiService 실호출 (MockBean).
커밋: [R8-server] test: Password reset + SSE E2E (파일 3개 이하)
테스트 숫자 커밋 메시지에 포함.
```

### ios
```
[R8-ios-s6] 작업 지시: SSE + Password Reset + Draft 통합 테스트
1. AppIntegrationTests.swift 신규:
   - SSE 스트리밍 경로 (fake SSEClient 주입) — token 시퀀스 수신 후 메시지 누적 검증
   - Password Reset 2단계 플로우 전체 (fake APIClient 주입)
   - Draft Queue + 재시도 시나리오
2. 기존 Feature 테스트들 수정 X — 새 통합 시나리오만 추가
3. 실행 증거: xcodebuild test ... 120+ tests

금지: 기존 로직 수정.
커밋: [R8-ios] test: 앱 통합 시나리오 (파일 1-2개)
테스트 숫자 커밋 메시지에 포함.
```

### android
```
[R8-android-s6] 작업 지시: SSE + Password Reset + Draft 통합 테스트
1. AppIntegrationTest.kt 신규 (unit 레벨 조합):
   - SSE 경로: fake SseClient + ChatViewModel 시퀀스 검증
   - Password Reset 2단계: fake AidyApiService + ViewModel 전이
   - Draft Queue + 재시도 시나리오
2. 기존 테스트 수정 X
3. 실행 증거: ./gradlew testDebugUnitTest 130+ tests

금지: Instrumented test (단위만).
커밋: [R8-android] test: 앱 통합 시나리오 (파일 1-2개)
테스트 숫자 커밋 메시지에 포함.
```

---

## R9 — Admin 통계 + 클라 디버그 뷰 (⚠️ 429로 유실 → 재전송본)

### server (재전송)
```
[R9-server-s6] 작업 지시: GET /api/internal/stats/summary — 본인 요약 통계
1. 기존 /api/internal/ai-stats + /error-logs 를 합친 summary 엔드포인트 신설
2. GET /api/internal/stats/summary — 인증 (본인 userId 전용)
   Response: { aiCalls24h, aiSuccessRate, aiAvgDurationMs, errorLogs24h, memoriesTotal, peopleTotal }
3. 기존 Repository 재사용 (AiCallLogRepository, ErrorLogRepository, MemoryRepository, PersonRepository)
4. 컨트롤러 테스트 3건 이상 (권한 검증 포함)
5. 실행 증거: ./gradlew test 207+ tests

금지: api-contract.md 변경 (internal 엔드포인트는 스펙 미포함).
커밋: [R9-server] feat: GET /api/internal/stats/summary (파일 5개 이하)
테스트 숫자 커밋 메시지에 포함.
```

### ios (재전송)
```
[R9-ios-s6] 작업 지시: 디버그 뷰 — 통계/상태 요약
1. SettingsView에 '디버그 정보' 섹션 정리 (또는 DebugView 신규):
   - baseURL, 앱 버전
   - DraftQueue count, ErrorLog 5건 요약 (기존)
   - RequestMetrics 카운트
2. 서버 /api/internal/stats/summary 호출 기능 (성공 시 노출, 실패 시 '—')
3. APIClient.fetchStatsSummary() 추가
4. TestStore 테스트 3건
5. 실행 증거: xcodebuild test ... 125+ tests

금지: 새 화면 대거 추가.
커밋: [R9-ios] feat: 디버그 뷰 정리 + 서버 통계 연동 (파일 5개 이하)
테스트 숫자 커밋 메시지에 포함.
```

### android (재전송)
```
[R9-android-s6] 작업 지시: 디버그 뷰 — 통계/상태 요약
1. SettingsScreen에 '디버그 정보' 섹션 추가
   - baseUrl, 앱 버전, DraftQueue count, ErrorLog 5건 요약
   - RequestMetrics 카운트
2. AidyApiService.getStatsSummary() 추가 → /api/internal/stats/summary
3. SettingsViewModel: statsSummary state + 로딩/에러
4. ViewModel 테스트 3건
5. 실행 증거: ./gradlew testDebugUnitTest 135+ tests

금지: 새 Hilt 모듈.
커밋: [R9-android] feat: 디버그 뷰 + 서버 통계 연동 (파일 5개 이하)
테스트 숫자 커밋 메시지에 포함.
```
