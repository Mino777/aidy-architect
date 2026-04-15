# Changelog

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

### aidy-ios
| 커밋 | 내용 |
|------|------|
| WO-002 | 채팅 화면 서버 연동 + 히스토리 |
| Gate 재작업 | categories + health + error 파싱 |
| R1 | harness 파일 + Memory 화면 카테고리 필터 |

### aidy-android
| 커밋 | 내용 |
|------|------|
| WO-003 | 채팅 화면 서버 연동 |
| Gate 재작업 | delete + categories + health + error 파싱 |
| R1 | harness 파일 + Memory 탭 (카테고리+리스트+삭제) |
| R2 | Settings 화면 (서버 URL 동적 변경 + 닉네임) |
