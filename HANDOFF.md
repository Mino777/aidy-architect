# Architect 핸드오프 — VS Code → tmux 전환

> **작성일**: 2026-04-15 23:15
> **상황**: VS Code 세션 종료 → tmux 관제 센터로 이관

## 현재 상태

### 완료된 것
1. **aidy-architect** — 관제 센터 구축 완료
   - `specs/api-contract.md` — API Contract v0.1 (Chat + Memory + Health)
   - `specs/conventions.md` — 네이밍/코딩 컨벤션
   - `specs/decisions/` — ADR 2건 (기술스택 + 아키텍처 패턴)
   - `work-orders/backlog/` — WO-001(서버), WO-002(iOS), WO-003(Android)
   - `gates/gate-checklist.md` — 검증 게이트 2단
   - `architect-cli.sh` — tmux 오케스트레이터 (setup/send/run/wo)
   - `orchestrator.sh` — tmux 세션 관리
   - `dispatch.sh` — WO 기반 자동 프롬프트 전송

2. **aidy-server** — Spring Boot + Kotlin 초기 셋업 (BUILD SUCCESS)
   - Entity: User, ChatMessage, Memory
   - Controller: Chat, Memory, Health
   - Service: ChatService, MemoryService, AiService (Claude API)
   - Flyway migration V1
   - Docker Compose PostgreSQL
   - Architect 계약 CLAUDE.md 연동

3. **aidy-ios** — Tuist + TCA + SwiftUI 초기 셋업
   - Feature: Chat, Memory, Settings (TCA Reducer 패턴)
   - APIClient (TCA DependencyClient)
   - Model: ChatMessage, MemoryItem
   - `tuist install` 성공 (SPM 의존성)
   - `tuist generate` 는 Xcode 설치 후 실행 필요
   - Architect 계약 CLAUDE.md 연동

4. **aidy-android** — Kotlin + Jetpack Compose 초기 셋업
   - Screen: Chat, Memory, Settings (Compose)
   - ViewModel: ChatViewModel
   - Retrofit API service
   - Material 3 테마
   - Android Studio에서 열기 필요
   - Architect 계약 CLAUDE.md 연동

5. **ai-study** — 보안 스프린트 완료 + Compound 문서화
   - 보안 7건 수정 (auth + headers + CVE + rate limit + etc)
   - n8n 리서치 문서
   - 83 엔트리

### tmux 세션 상태
- `tmux attach -t aidy` 로 접속
- 윈도우 0: architect (Claude Code 미실행)
- 윈도우 1: server (Claude Code 실행 중)
- 윈도우 2: ios (Claude Code 실행 중)
- 윈도우 3: android (Claude Code 실행 중)

## 다음 세션 (tmux architect) 시작 순서

### 1. tmux 접속
```bash
tmux attach -t aidy
```

### 2. architect 윈도우에서 Claude Code 시작
```
Ctrl+B → 0
claude
```

### 3. Claude Code에 이렇게 입력
```
~/Develop/aidy-architect/CLAUDE.md 읽고, HANDOFF.md 읽어줘.
나는 Architect(설계자) 역할이야.
tmux 윈도우 1(server), 2(ios), 3(android)에 워커 Claude가 떠있어.
architect-cli.sh로 워커에게 명령을 보낼 수 있어.
WO-001부터 시작하자.
```

### 4. 워커에게 WO-001 전송
```bash
! cd ~/Develop/aidy-architect && ./architect-cli.sh send server "~/Develop/aidy-server/CLAUDE.md 읽고, ~/Develop/aidy-architect/specs/api-contract.md 읽고, ~/Develop/aidy-architect/work-orders/backlog/WO-001-server-chat-api.md 읽고 작업 시작해"
```

### 5. 서버 완료 후 iOS/Android 병렬 전송
```bash
! ./architect-cli.sh send ios "~/Develop/aidy-ios/CLAUDE.md 읽고, ~/Develop/aidy-architect/specs/api-contract.md 읽고, ~/Develop/aidy-architect/work-orders/backlog/WO-002-ios-chat-screen.md 읽고 작업 시작해"

! ./architect-cli.sh send android "~/Develop/aidy-android/CLAUDE.md 읽고, ~/Develop/aidy-architect/specs/api-contract.md 읽고, ~/Develop/aidy-architect/work-orders/backlog/WO-003-android-chat-screen.md 읽고 작업 시작해"
```

## 환경 설정 (필요한 것들)
- JDK 21: `export JAVA_HOME=/opt/homebrew/opt/openjdk@21` (~/.zshrc에 추가 권장)
- Docker: PostgreSQL용 (`docker compose up -d`)
- Xcode: iOS 빌드용 (`sudo xcode-select -s /Applications/Xcode.app`)
- Android Studio: Android 빌드용
