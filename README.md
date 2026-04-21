# Aidy Architect

멀티에이전트 관제 센터. 코드를 직접 작성하지 않고, 아키텍처를 결정하고 API 스펙을 정의하고 작업을 분배하고 결과를 검증한다.

## 역할

```
설계자 (이 프로젝트)
  ├── API 스펙 정의 (specs/api-contract.md)
  ├── 작업 지시서 발행 (work-orders/)
  ├── 검증 게이트 운영 (gates/)
  └── 아키텍처 결정 기록 (specs/decisions/)
        │
   ┌────┼────────────┐
   │    │            │
 백엔드  iOS        Android
 워커   워커         워커
```

## 프로젝트 맵

| 프로젝트 | 스택 | 역할 |
|---------|------|------|
| **aidy-architect** | Markdown + Shell | 관제 (이 프로젝트) |
| aidy-server | Spring Boot + Kotlin | 백엔드 API |
| aidy-ios | Tuist + TCA + SwiftUI | iOS 클라이언트 |
| aidy-android | Jetpack Compose + MVVM | Android 클라이언트 |

## 현재 상태 (v3.4, 2026-04-21)

### 구현 완료 피처 (109 엔드포인트)

| 버전 | 피처 |
|------|------|
| v0.1~v0.2 | Auth (가입/로그인/JWT/비밀번호 재설정) |
| v0.3~v0.8 | Chat (대화/스트리밍/히스토리/삭제/검색/요약) |
| v0.1~v0.6 | Memory (CRUD/카테고리/인물/검색/일괄/공유) |
| v1.0~v1.2 | People (인물 목록/병합/수정), App Config, Notifications |
| v1.3~v1.5 | Chat Grouped, Dashboard, Bookmarks, Feedback, Topics, Export |
| v1.6~v1.9 | Smart Review, Sentiment, Weekly Summary, Memory Connections |
| v2.0~v2.3 | Health Score, Daily Digest, Conversation Starters, Anniversaries |
| v2.4~v2.8 | Notification Preferences, Nudges, Gift Suggestions, Timeline, Quick Notes |
| v2.9~v3.1 | Smart Notifications, Relationship Map, Interaction Log |
| v3.2~v3.4 | **Shared Memories, Memory Tags, AI Chat Suggestions** |

### WO 현황

- 완료: WO-001 ~ WO-120 (120개)
- 진행중: 0
- 백로그: 0

## CLI

```bash
./architect-cli.sh send <target> "<msg>"        # 워커에게 명령
./architect-cli.sh send-seq <t1> "m1" <t2> "m2" # 직렬 dispatch
./architect-cli.sh verify <server|android|all>   # 빌드+테스트 검증
./architect-cli.sh crash-log <target>            # 크래시 원인 진단
./architect-cli.sh preflight                     # 시스템 점검
./architect-cli.sh watch-workers [timeout]       # 워커 완료 감시
./architect-cli.sh wo <number>                   # WO 활성화
./architect-cli.sh wo-done <number>              # WO 완료
./architect-cli.sh status                        # WO 현황
./architect-cli.sh restart-workers               # 워커 재시작
```

## 검증 게이트

| Gate | 시점 | 검증 내용 |
|------|------|----------|
| Gate-1 | PR 직후 | API contract 일치, Request/Response 스키마, 에러 코드, 네이밍 |
| Gate-2 | 머지 전 | 빌드 통과, 테스트 통과, 크로스 프로젝트 호환성 |

## 자동화 (Slash Commands)

| 커맨드 | 기능 |
|--------|------|
| `/autoceo N` | N라운드 풀 자동 스프린트 (Research→Plan→Dispatch→QA→Compound) |
| `/dispatch` | WO 활성화 + 워커 전송 |
| `/gate-1` | 스펙 준수 검증 |
| `/gate-2` | 통합 검증 |
| `/compound` | 회고 + 솔루션 + ADR 문서화 |
| `/monitor` | 전체 워커 상태 모니터링 |

## 디렉토리 구조

```
specs/
  api-contract.md          # API 스펙 (단일 소스)
  decisions/               # ADR + BACKLOG
  conventions.md           # 코딩 컨벤션
work-orders/
  backlog/                 # 미착수
  in-progress/             # 진행중
  done/                    # 완료 (120개)
gates/
  reviews/                 # Gate 검증 기록
  test-policy.md           # 테스트 정책
docs/
  worker-prompts/          # 워커 프롬프트 로그 (날짜별)
  solutions/               # 삽질 기록 + 세션 교훈
  crash-logs/              # 워커 크래시 진단 로그
  retros/                  # 스프린트 회고
```

## 바선생 레벨

```
Operator L5.5 Engineer+ ⬡
ORCH 6.0 | VERIFY 5.5 | DECOMP 5.5 | FAIL 5.0 | CTX 5.0 | META 5.0
목표: L6.0 Orchestrator (FAIL/META 5.5+)
```
