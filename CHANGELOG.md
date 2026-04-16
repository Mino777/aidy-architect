# Changelog

## [0.7.1] — 2026-04-16

### 토큰 경제성 인프라 (P3 — s6 후속)

s6 종료 시 박제된 "토큰 리밋 리셋 직후 17% + 429 rejection" 교훈을 도구로 박제. 다음 autoceo 안전벨트.

**P3-7 — 직렬 dispatch (architect-cli.sh send-seq)**
- `send-seq <t1> "m1" <t2> "m2" [...]` — 가변 인자 (target, prompt) 페어
- 워커별 `wait_for_idle` 후 다음 워커로 진행 (idle = "esc to interrupt" 미감지 + 프롬프트 시그니처)
- 환경변수: `AIDY_SEQ_TIMEOUT` (기본 1800s), `AIDY_IDLE_POLL_SEC` (기본 15s)
- 추가 명령: `wait-idle <target> [timeout]` — 단독 idle 대기

**P3-8 — 429 자동 backoff (tmux_send 내장)**
- dispatch 후 `AIDY_SEND_429_WATCH`초 (기본 30s) 동안 pane 폴링
- 패턴: rate limit, 429, too many requests, usage limit reached, retry-after, claude usage limit, api error 529
- 감지 시 `AIDY_SEND_429_BACKOFF`초 (기본 300s) 백오프 후 1회 재시도
- 환경변수: `AIDY_SEND_429_DETECT=0` 비활성, `AIDY_SEND_NO_429=1` 단일 호출 비활성, `AIDY_SEND_429_RETRY` 재시도 횟수
- 재시도 시 무한루프 방지 위해 내부 카운터 (`AIDY_SEND_429_TRY_NUM`) 전달

**P3-9 — CI 상태 자동 수집 (ci-status.sh)**
- 3개 워커 repo의 GitHub Actions 결과를 한 번에 (gh CLI + jq)
- 옵션: `--limit N`, `--branch`, `--workflow`, `--since 24h|7d`, `--json`, `--watch`
- 색상 출력: success(녹), failure(적), in_progress(황)
- `--watch` 모드: 실패 워크플로만 한 줄 보고 — exit 1 (모니터링 통합용)
- `--json` 모드: jq 파이프 가능 (다른 스크립트 통합용)
- `/monitor` Phase 6 추가 + `/gate-2` Phase 0 (머지 전 빨간불 차단) 통합
- 첫 실행 결과: iOS Test 워크플로 2건 연속 실패 — 후속 조사 필요



### 스트리밍 + 계정 복구 + 검색 최적화 (autoceo 6차 스프린트, 8라운드 완주 — R9 org rate limit로 deferred)

**tmux 오케스트레이션 안정화 + 프롬프트 로깅 (R1)**
- `architect-cli.sh tmux_send` — paste-buffer 경유 + Enter flush 3회 재시도
- `docs/worker-prompts/` — 워커 dispatch 프롬프트 자동 기록 (프롬프트 엔지니어링 학습용)
- 채팅 메시지 복사 (iOS Context Menu / Android LocalClipboardManager)
- JUnit5 `@Timeout` 5초 (플레이키 방지)

**SSE Phase 2 — Anthropic streaming 실연동 (R2~R5)**
- 서버: `AiService.chatStream` + OkHttp `BufferedSource` 수동 SSE 파싱 (content_block_delta)
- 서버: Circuit Breaker 래핑 유지 (OPEN → onError 즉시)
- iOS: `SSEClient` (`URLSession.bytes`) + `AsyncThrowingStream` + 점점점 애니메이션
- Android: `SseClient` (OkHttp 수동) + Flow 이벤트 + ChatScreen 점진 표시
- 끊김 1회 자동 재시도 + latency 계측

**채팅 since 증분 동기화 v0.2.4 (R4)**
- GET `/api/chat/history?since=ISO8601` — `createdAt > since` ASC
- 잘못된 since → 400 VALIDATION_ERROR

**Password Reset v0.2.5 (R5, R6)**
- 서버: V11 `password_reset_tokens` 테이블 + SecureRandom 32자 URL-safe + 30분 만료 + 1회용 + 5분 쿨다운
- POST `/api/auth/password/reset/request` — 존재 여부 유출 방지 (항상 200)
- POST `/api/auth/password/reset/confirm` — bcrypt 재해싱
- 새 ErrorCode `PASSWORD_RESET_TOKEN_INVALID` (400)
- iOS/Android: 2단계 플로우 (이메일 → 토큰+새 비번 → 성공)
- 이메일 발송은 로그 출력 (Phase 1 — SMTP 통합 후속)

**검색 최적화 (R7)**
- 서버: V12 `pg_trgm` extension + GIN indexes (memories.content/title) — PostgreSQL 전용
- iOS/Android: 최근 검색어 5건 rolling + 매칭 키워드 하이라이트

**E2E 확장 (R8)**
- 서버: `PasswordResetE2ETest` + `ChatStreamE2ETest` (SSE/Circuit Breaker OPEN/validation)
- iOS: `AppIntegrationTests` (+329 라인)
- Android: `AppIntegrationTest` (+341 라인)

**R9 — 순차 재개 (admin 통계 + 디버그 뷰)**
- 서버: GET /api/internal/stats/summary (JWT principal 본인 데이터만, 다른 유저 노출 차단)
- iOS: SettingsFeature loadStatsSummary + 디버그 섹션 통계 표시
- Android: SettingsViewModel loadStatsSummary + StateFlow + 섹션 UI
- 재개 전략: 서버 solo → 클라 2-way → 429 시 순차 continue (짧은 프롬프트로 재개)

**테스트 메트릭 (최종)**
- **466 tests · 0 failures** (server 207 / iOS 124 / android 135)
- 세션 5 대비 +126 tests

**Flyway**: V9 → V11(password_reset_tokens) + V12(pg_trgm)
**API Contract**: v0.2.3 → v0.2.5

## [0.6.0] — 2026-04-16

### 플랫폼 성숙 (autoceo 5차 스프린트, 10라운드)

**Gate 1 강화 + WO 템플릿 (R1)**
- Gate 1 체크리스트에 "테스트 실행 숫자 증거" 필수 항목 추가
- `architect-cli.sh build_prompt` 에 테스트 통계 요구 고정 문구
- /api/health 응답 확장 (BuildProperties 기반 version/buildTime)
- iOS/Android Settings 에 앱 정보 섹션

**CI/CD (R2)**
- GitHub Actions `test.yml` 3-way 추가 (server ubuntu / iOS macos-14 / android ubuntu)
- 기존 `ai-review.yml` (auto-merge) 공존

**오프라인 드래프트 큐 + AI 통계 (R3)**
- iOS/Android DraftQueue (50건 rolling, Android는 EncryptedSharedPreferences)
- 전송 실패 시 로컬 큐 → 재시도 UI
- 서버 GET /api/internal/ai-stats + V9 (ai_call_logs.user_id)

**메모리 페이지네이션 v0.2.2 (R4)**
- GET /api/memories offset/limit + HTTP 헤더 (X-Total-Count/X-Offset/X-Limit/X-Has-More)
- **body는 bare array 유지** — backward compat
- 클라 무한 스크롤

**Biometric 앱 잠금 + 토큰 refresh (R5)**
- POST /api/auth/refresh (v0.2.3) — 단순 re-sign
- iOS LocalAuthentication Face ID/Touch ID
- Android androidx.biometric:1.2.0 (AndroidX 확장으로 예외 허용)
- Settings 잠금 토글

**관측성 — 에러 로그 집계 (R6)**
- 서버 V10 error_logs 테이블 + GET /api/internal/error-logs
- iOS 파일 기반 ErrorLogClient (100건 rolling)
- Android EncryptedSharedPreferences + CoroutineExceptionHandler 전역

**SSE 채팅 스트리밍 — ADR-008 (R7)**
- POST /api/chat/stream (SseEmitter, Phase 1 fake-stream)
- 클라 검색 debounce 300→200ms + 요청 통계 UI

**E2E + 경계 테스트 (R8)**
- SecurityRegressionTest + MemoryPaginationE2ETest (서버)
- 클라 DraftQueue/Biometric/ErrorLog 경계 테스트

**성능 + 폴리시 (R9)**
- ThroughputBenchmarkTest (MockMvc 100회 반복, p95 assumeTrue)
- 햅틱 피드백 (UIImpactFeedbackGenerator / LocalHapticFeedback)
- Skeleton shimmer 애니메이션 (외부 lib 0)

**신규 ADR**
- ADR-008: SSE 스트리밍 채팅 (P-002 결론)

**테스트 메트릭**
- **340 tests · 0 failures** (server 170 / iOS 87 / android 83)
- 세션 4 대비 +142 tests
- 테스트 실행 증거 워커 자체 보고 100% 정착

## [0.5.0] — 2026-04-16

### 안정성 + 관측성 + UX 폴리시 (autoceo 4차 스프린트, 10라운드)

**AI 안정성 (R2)**
- ADR-007: in-memory Circuit Breaker (P-004 Phase 1) — 0 dependency
- AI_UNAVAILABLE (503) 에러 코드 신설
- 서버 다운 구간 stampede 제거 → fast-fail + cooldown 복구

**에러 응답 표준화 (R3)**
- VALIDATION_ERROR 코드 + 필드별 한국어 메시지 보존
- api-contract v0.2.1 — Error Codes 표에 retryable 컬럼 문서화
- iOS/Android ApiError.isRetryable + 채팅 재시도 UI
- GlobalExceptionHandler MethodArgumentNotValid + HttpMessageNotReadable 분기

**DB 최적화 (R4)**
- Flyway V8 — 6 복합 인덱스 (memories/chat_messages/persons/person_memories)
- IF NOT EXISTS로 기존 인덱스와 안전 공존
- iOS/Android 채팅 자동 스크롤 하단

**관측성 (R5)**
- RequestIdFilter — X-Request-Id 헤더 + MDC 전파
- logback 패턴 [%X{requestId}]
- AiService 구조화 로그 (duration_ms, success, model)
- 메모리 스와이프 삭제 (iOS/Android 낙관적 UI)

**보안 (R6)**
- InMemoryRateLimiter — chat 20rpm, auth 10rpm (env 오버라이드)
- SecurityConfig 보안 헤더 (X-Frame-Options DENY, Referrer-Policy, X-Content-Type-Options)
- iOS/Android 빈 상태 UI (메모리/인물)

**UX 폴리시 (R7)**
- Skeleton 로딩 (iOS/Android, shimmer 라이브러리 0)
- 에러 재시도 UI 일관성
- RateLimitInterceptor @SpringBootTest 통합 테스트

**접근성 + 한글화 (R8)**
- iOS accessibilityLabel/Hint + 다크모드 semantic colors
- Android contentDescription + MaterialTheme.colorScheme 일관성
- DTO @field validation 메시지 한글화

**테스트 강화 (R9)**
- 서버 ChatE2ETest (signup → login → chat / 401 / validation)
- iOS Auth/Chat/Memory Feature 통합 흐름 테스트 (+154 라인)
- Android Auth/Chat/People ViewModelTest (+208 라인)
- SecurityConfig @Lazy 순환 의존성 해결

**문서 (R10)**
- README 갱신 (server) + 신규 (ios, android)
- OPERATIONS.md (server) — Request-Id, Rate Limit, CB 운영 노트
- ADR-007 편입

**총 메트릭 (R1-R10)**
- 커밋: ~30 (server 10 / ios 10 / android 10)
- 보호파일 위반: 0
- 롤백: 0
- 테스트 추가: 대략 +1,200 라인

## [0.4.0] — 2026-04-16

### 보안 + 인증 + 품질 (autoceo 2차 스프린트, 10라운드)

**보안 (R1)**
- DB 기본 패스워드 제거 — 환경변수 필수화

**JWT 인증 (R2-R4)**
- WO-009: 서버 JWT 인증 (signup/login + bcrypt + jjwt + 인증 필터)
- iOS: Auth 화면 + Keychain 토큰 + 401 자동 로그아웃
- Android: Auth 화면 + EncryptedSharedPreferences + 401 자동 로그아웃
- X-User-Id 헤더 완전 제거
- ADR-006: JWT 인증 아키텍처 결정

**프롬프트 최적화 (R5)**
- normalizedName 정규화 규칙 강화 (동일 인물 호칭 통일)
- 추출 품질 힌트 추가 (확실하지 않으면 추출 안 함)

**iOS 기능 (R6)**
- 메모리 검색 (.searchable + debounce 300ms)

**테스트 (R7)**
- server: PersonService + Auth + 피드백 테스트
- iOS: PeopleFeature + AuthFeature TestStore
- Android: PeopleViewModel + AuthViewModel 19건

**문서 (R8-R10)**
- BACKLOG: P-001/003/005 완료 처리
- ADR-006: JWT 인증

## [0.3.0] — 2026-04-16

### 관계 메모리 Phase 1 (10라운드 autoceo)

**설계 파이프라인** (R1-R3)
- /office-hours → /plan-ceo-review → /plan-eng-review → /plan-design-review → /design-consultation
- DESIGN.md 생성 (Organic/Natural, 딥 그린 #2D7D46, Pretendard)
- API Contract v0.2.0 — People 엔드포인트 + 피드백 API + personDetail 확장
- ADR-005 — 관계 메모리 아키텍처 (B+C 합성, Phase 1/2 분리)

**서버 (R4, R6, R8)**
- WO-006: Person/PersonMemory/MemoryFeedback 3개 테이블 + Flyway 마이그레이션
- WO-006: GET /memories/people + POST /memories/{id}/feedback
- WO-006: LLM 프롬프트 강화 (personDetail 추출)
- WO-005: AI 출력 5-Layer 런타임 검증

**iOS (R2, R5, R6)**
- WO-007: 피플 탭 (리스트 행 + 이니셜 아바타 + 상세 타임라인)
- WO-007: 기억 확인 바텀시트 + 피드백 버튼 (맞아/틀려)
- R2: 메모리 삭제 + 설정 화면 (Android 동기화)

**Android (R5, R6)**
- WO-008: 피플 탭 (리스트 행 + 이니셜 아바타 + 상세 타임라인)
- WO-008: BottomSheet 확인 카드 + 피드백 버튼

**Gate 통과**: WO-002~008 전부 Gate 1 + Gate 2 PASS → done

## [0.2.1] — 2026-04-16

### WO 발행
- `WO-004` — AI 호출 안정성 (Circuit Breaker + Timeout + Retry + 비용 로깅)
- `WO-005` — AI 출력 런타임 검증 (5-Layer 방어 체계, WO-004 의존)
- `api-contract.md` v0.1.1 — AI_TIMEOUT (504) 에러 코드 추가
- `specs/decisions/BACKLOG.md` — P-004~006 큐 등록

### /ingest: ai-study wiki 흡수 (83 entries → 12 패턴 발견)
- `.claudeignore` — architect 프로젝트 컨텍스트 오염 방지 (done/ WO, lock, .git 제외)
- `CLAUDE.md` — 토큰 최적화 규칙 (model routing, cache 5분 TTL, prefix 다이어트)
- `CLAUDE.md` — 성숙도 Ladder 추가 (현재 Stage 3, Stage 4 실험 중)
- `docs/compound-principles.md` — Compound Engineering 12 원칙 Aidy 적용 문서
- `specs/decisions/BACKLOG.md` — P-004~006 추가 (Circuit Breaker, 5-Layer 검증, Multi-Agent Pipeline)
- `inbox/ingest-2026-04-16.md` — 워커 공유 알림 (서버 WO 후보 + iOS/Android 확인사항)

## [0.2.0] — 2026-04-16

### 하네스 엔지니어링
- `.claude/settings.json` — PreToolUse/PostToolUse hooks (커밋 게이트, 금지 액션 차단, compound 리마인더)
- `.claude/commands/` — 6개 slash command (gate-1, gate-2, monitor, dispatch, compound, cross-session-review, autoceo, ingest)
- `.claude/agents/` — gate-reviewer, spec-writer (architect), api-verifier, migration-checker (server), tca-scaffold, contract-sync (ios), compose-scaffold, contract-sync (android)
- 워커 `.claude/settings.json` × 3 — 분야별 pre-commit QA gate + 금지 액션 hook
- `.github/workflows/ai-review.yml` × 3 — 자동 PR + Test Gate + Squash Merge
- `/wt-branch` × 3 — worktree 기반 안전 분기 (squash merge 함정 회피)
- `.claudeignore` × 3 — 빌드 산출물/IDE/캐시 제외 (토큰 절약)
- `inbox/` 메시징 시스템 — 워커 → Architect 파일 기반 통신
- `worker-monitor.sh` — 백그라운드 워커 상태 감시
- `inbox-watcher.sh` — 워커 요청 감지 + macOS 알림
- `architect-cli.sh` pane fallback — 윈도우 합친 레이아웃 지원

### 컴파운드 엔지니어링
- `gates/security-hardening-checklist.md` — 공통 + 서버 + iOS + Android 분야별
- `gates/reviews/` — Gate 1 리뷰 결과 보관 (WO-001~003)
- `templates/wo-retro.md`, `gate-review.md` — 회고 + 리뷰 템플릿
- `specs/decisions/BACKLOG.md` — 미결정 이슈 추적
- `specs/decisions/003-client-sync-rule.md` — iOS/Android 동기화 규칙 ADR
- `docs/retros/round-1-retro.md`, `round-2-retro.md` — autoceo 라운드 회고
- `SYSTEM-GUIDE.md` — 전체 시스템 운영 매뉴얼 (11 섹션)

### 워커 CLAUDE.md 강화
- 분야별 행동 가드 (서버: Flyway DDL, iOS: Keychain/TCA, Android: EncryptedSharedPreferences/MVVM)
- 자가 검증 명령 (커밋 전 스펙 대조 grep)
- Architect inbox 메시징 규칙
- 금지 액션 목록 (hooks로 차단)

### 토크노믹스
- 핸드오프 정책: 매번 재시작 → 세션 유지 (설정 변경 시에만 재시작)
- .claudeignore 전 프로젝트 배치
- gstack 스킬 활용 가이드

## [0.1.0] — 2026-04-15

### Added
- API Contract v0.1 (Chat + Memory + Health)
- Work Orders: WO-001 (server), WO-002 (ios), WO-003 (android)
- Gate 체크리스트 2단 (스펙 준수 + 통합 검증)
- Architect CLI (tmux-setup, send, wo, wo-done, status)
- Conventions 문서 (네이밍 규칙)
- ADR-001 기술스택, ADR-002 아키텍처 패턴

---

## 워커 프로젝트 변경 요약

### aidy-server
| 커밋 | 내용 |
|------|------|
| WO-001 | Chat API + Memory 파이프라인 전체 구현 |
| R1 | harness 파일 + ChatController/MemoryService 테스트 |
| R2 | AI 타임아웃, CORS, 500 에러 로깅 |
| WO-004 | AI 호출 안정성 — 에러 분류 + 재시도 + 타임아웃 |
| R4 | 관계 메모리 DB + 엔티티 + PersonService + People API |
| R6 | displayName fallback 수정 |
| R8 | AI 출력 5-Layer 런타임 검증 |

### aidy-ios
| 커밋 | 내용 |
|------|------|
| WO-002 | 채팅 화면 서버 연동 + 히스토리 |
| Gate 재작업 | categories + health + error 파싱 |
| R1 | harness 파일 + Memory 화면 카테고리 필터 |
| R2 | 메모리 빈 화면 + 삭제 + 설정 화면 |
| R5 | 피플 탭 — 인물 목록 + 상세 타임라인 + 피드백 |
| R6 | 바텀시트 확인 카드 + relationship + 터치타겟 |

### aidy-android
| 커밋 | 내용 |
|------|------|
| WO-003 | 채팅 화면 서버 연동 |
| Gate 재작업 | delete + categories + health + error 파싱 |
| R1 | harness 파일 + Memory 탭 (카테고리+리스트+삭제) |
| R2 | Settings 화면 (서버 URL 동적 변경 + 닉네임) |
| R5 | 피플 탭 — 인물 목록 + 상세 + 확인카드 + 피드백 |
| R6 | PersonRow 날짜 표시 수정 |
