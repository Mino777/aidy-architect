# Changelog

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
