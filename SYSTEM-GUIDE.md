# Aidy Architect — 시스템 운영 가이드

> 이 문서는 Aidy 프로젝트의 멀티 에이전트 관제 시스템이 어떻게 작동하는지 설명한다.
> 설계자(Architect)가 3개 워커(Server/iOS/Android) Claude 세션을 통제하며,
> API 스펙 기반으로 풀스택 개발을 조율한다.

---

## 1. 아키텍처 개요

```
┌──────────────────────────────────────────────────────┐
│                  tmux 세션 (aidy)                      │
│                                                        │
│  ┌─────────────────┬──────────────────┐               │
│  │                 │  pane 1: server  │               │
│  │                 │  Claude Code     │               │
│  │  pane 0:        ├──────────────────┤               │
│  │  ARCHITECT      │  pane 2: ios     │               │
│  │  (관제탑)       │  Claude Code     │               │
│  │                 ├──────────────────┤               │
│  │                 │  pane 3: android │               │
│  │                 │  Claude Code     │               │
│  └─────────────────┴──────────────────┘               │
│                                                        │
│  왼쪽: 설계자가 스펙 정의, 작업 분배, 검증              │
│  오른쪽: 워커 3명이 각자 프로젝트에서 구현               │
└──────────────────────────────────────────────────────┘
```

### 역할 분리

| 역할 | 누가 | 할 수 있는 것 | 할 수 없는 것 |
|------|------|-------------|-------------|
| **Architect** | pane 0의 Claude | 스펙 정의, WO 발행, Gate 검증, 머지 승인 | 직접 코드 작성 |
| **Server 워커** | pane 1의 Claude | aidy-server 코드 구현 | 스펙 변경, 임의 엔드포인트 추가 |
| **iOS 워커** | pane 2의 Claude | aidy-ios 코드 구현 | 스펙 변경, 임의 필드 추가 |
| **Android 워커** | pane 3의 Claude | aidy-android 코드 구현 | 스펙 변경, 임의 필드 추가 |
| **사람 (Jo)** | tmux 전체 | 모든 것. 최종 결정권 | — |

---

## 2. 핵심 원칙

ai-study Compound Engineering 12원칙 중 이 시스템에 적용된 핵심:

### 행동에 박는 가드 > 기억에 의존하는 가드

워커에게 "스펙을 지켜라"라고 **말**하는 것은 기억 가드다. 시간이 지나면 100% 실패한다.
대신 이 시스템은:

- **CLAUDE.md에 자가 검증 명령**을 넣어서, 워커가 커밋 전에 자동으로 스펙 대조를 실행하게 한다
- **Gate 1 검증**에서 Architect가 코드 line-by-line으로 스펙과 대조한다
- **settings.json hooks**로 커밋/푸시 시점에 자동 리마인더를 발동한다

### 메타데이터 신뢰 금지

워커가 "완료했습니다"라고 하면 그 말을 **그대로 신뢰하지 않는다**.
커밋 메시지가 깨끗해도 diff가 망가져 있을 수 있다. `/cross-session-review`로 코드만 본다.

### 부분 실행 불가능

Gate 검증을 "나중에 하자"고 넘어가는 것을 구조적으로 방지한다.
Slash command가 전체 프로세스를 한번에 묶어서, 일부만 실행하고 빠지는 경로를 막는다.

---

## 3. 작업 흐름 (4단계 루프)

```
  Plan → Work → Review → Compound → (다음 Plan)
```

### Plan: 설계 + 작업 분배

1. Architect가 `specs/api-contract.md`에 API 스펙을 정의한다
2. `work-orders/backlog/`에 Work Order를 발행한다
3. `/dispatch`로 WO를 활성화하고 워커에게 전송한다

```bash
# WO 활성화 + 전송
/dispatch 002
# 또는 수동으로:
./architect-cli.sh wo 002
tmux send-keys -t aidy:architect.2 "..." C-m
```

### Work: 워커가 구현

워커는 다음 순서로 작업한다:
1. CLAUDE.md 읽기 (규칙 + 자가 검증 명령)
2. api-contract.md 읽기 (절대 스펙)
3. conventions.md 읽기 (네이밍 규칙)
4. WO 파일 읽기 (구현 요구사항)
5. 하나씩 구현 → 자가 검증 → git commit

**워커가 할 수 없는 것:**
- 스펙에 없는 엔드포인트/필드 추가
- Error code 임의 생성
- 스펙 변경 (Architect에게 요청해야 함)

### Review: 검증 게이트 2단

**Gate 1: 스펙 준수** (`/gate-1`)
- API contract의 모든 엔드포인트와 코드를 필드별 대조
- Error code가 스펙 표와 정확히 일치하는지 확인
- 보안 체크리스트 통과 여부
- 결과: `gates/reviews/gate-1-WO-{번호}-{워커}.md`에 박제

**Gate 2: 통합 검증** (`/gate-2`)
- 로컬 빌드 + 테스트 통과 (CI 위임 금지)
- 서버-iOS-Android 간 Request/Response 스키마 교차 대조
- 결과: `gates/reviews/gate-2-WO-{번호}-{워커}.md`에 박제

```
PASS        → WO done 처리 + 머지 승인
CONDITIONAL → 사소한 이슈, 다음 WO에서 수정
FAIL        → 재작업 지시 (워커에게 피드백 전송)
```

### Compound: 지식 축적

Gate 2 통과 후 `/compound` 실행:
1. **WO 회고** (`docs/retros/WO-{번호}-retro.md`) — 잘된 것, 아쉬운 것, 다음에 적용할 것
2. **솔루션** (`docs/solutions/`) — 재발 가능한 문제만 기록
3. **ADR 업데이트** (`specs/decisions/`) — 아키텍처 결정이 있었으면

---

## 4. 파일 구조

```
aidy-architect/
├── .claude/
│   ├── settings.json              ← hooks (행동 레벨 가드)
│   └── commands/                  ← slash commands
│       ├── dispatch.md            ← /dispatch
│       ├── gate-1.md              ← /gate-1
│       ├── gate-2.md              ← /gate-2
│       ├── cross-session-review.md ← /cross-session-review
│       ├── monitor.md             ← /monitor
│       └── compound.md            ← /compound
│
├── specs/                         ← 스펙 (Architect만 수정)
│   ├── api-contract.md            ← API 절대 규칙
│   ├── conventions.md             ← 네이밍 컨벤션
│   └── decisions/                 ← Architecture Decision Records
│       ├── 001-tech-stack.md
│       ├── 002-architecture-pattern.md
│       └── BACKLOG.md             ← 미결정 이슈
│
├── work-orders/                   ← 작업 파이프라인
│   ├── backlog/                   ← 아직 착수 안 한 작업
│   ├── in-progress/               ← 워커가 작업 중
│   └── done/                      ← 완료 + Gate 통과
│
├── gates/                         ← 검증 시스템
│   ├── gate-checklist.md          ← Gate 1/2 체크리스트
│   ├── security-hardening-checklist.md ← 보안 (공통/서버/iOS/Android)
│   └── reviews/                   ← Gate 리뷰 결과 보관
│
├── templates/                     ← 재사용 템플릿
│   ├── work-order.md
│   ├── wo-retro.md
│   └── gate-review.md
│
├── docs/                          ← Compound 문서
│   ├── retros/                    ← WO별 회고
│   └── solutions/                 ← 재발 가능 문제 솔루션
│
├── CLAUDE.md                      ← Architect 규칙 + 명령 목록
├── SYSTEM-GUIDE.md                ← 이 문서
├── HANDOFF.md                     ← 세션 전환 문서
├── architect-cli.sh               ← CLI 오케스트레이터
├── orchestrator.sh                ← tmux 세션 관리
└── dispatch.sh                    ← WO 자동 프롬프트 전송
```

---

## 5. 워커 통제 메커니즘

### 계층별 가드

```
Layer 0 (가장 강력): --dangerously-skip-permissions 모드로 실행
                     → 워커가 권한 승인 없이 작업 가능 (속도)
                     → 대신 Gate 검증으로 품질 보장

Layer 1 (코드 레벨): 워커 CLAUDE.md
                     → 분야별 특화 규칙 + 자가 검증 명령
                     → 커밋 전 스펙 대조 grep 명령 내장

Layer 2 (행동 레벨): .claude/settings.json hooks
                     → 커밋 시 자동 게이트 확인 리마인더
                     → 푸시 후 compound 문서화 리마인더

Layer 3 (검증 레벨): /gate-1 + /gate-2 + /cross-session-review
                     → Architect가 직접 코드 line-by-line 검증
                     → 메타데이터 신뢰 금지, diff만 본다
```

### 분야별 특화

| 분야 | 스택 | 특화 가드 |
|------|------|----------|
| **Server** | Spring Boot + Kotlin | Flyway DDL 가드, application.yml 시크릿 금지, gradlew 빌드 검증 |
| **iOS** | TCA + SwiftUI | Keychain 강제, ATS 예외 금지, TCA 패턴 가드 (Effect에서 직접 API 호출 금지) |
| **Android** | Jetpack Compose | EncryptedSharedPreferences 강제, cleartext 금지, ViewModel 패턴 강제 |

---

## 6. 일상적인 운영 시나리오

### 시나리오 1: 새 기능 추가

```
1. Architect: api-contract.md에 새 엔드포인트 추가
2. Architect: WO 3개 발행 (server/ios/android)
3. Architect: /dispatch로 server에 전송 (서버 먼저)
4. Server 워커: 구현 + 커밋
5. Architect: /gate-1 server → PASS
6. Architect: /gate-2 server → PASS (빌드+테스트)
7. Architect: /dispatch로 ios, android에 동시 전송
8. iOS/Android 워커: 병렬 구현
9. Architect: /gate-1 ios, /gate-1 android
10. Architect: /gate-2 ios, /gate-2 android (크로스 호환성 포함)
11. Architect: /compound (3개 WO 회고 + 솔루션)
```

### 시나리오 2: 워커가 스펙 변경을 요청할 때

```
1. 워커: "이 Response에 totalCount 필드가 필요합니다" (작업 중단)
2. Architect: 요청 타당성 평가
3. Architect: api-contract.md 수정 (또는 거절)
4. Architect: 수정된 스펙을 워커에게 전달
5. 워커: 수정된 스펙으로 작업 재개
```

### 시나리오 3: Gate 1 FAIL

```
1. Architect: /gate-1 server → FAIL (Response 필드 누락)
2. Architect: gate review 파일에 불일치 상세 기록
3. Architect: server 워커에게 피드백 전송
   "WO-001 Gate 1 FAIL. MemoryResponse에 createdAt 필드 누락.
    api-contract.md § 3. Memory 참조하여 수정해줘."
4. Server 워커: 수정 + 커밋
5. Architect: /gate-1 server → PASS (재검증)
```

---

## 7. Inbox 메시징 (워커 → Architect)

워커 세션은 독립 프로세스라 Architect에게 직접 말을 걸 수 없다.
대신 **파일 기반 메시징**으로 통신한다.

### 흐름
```
워커가 막힘
  → inbox/{워커}-request.md 파일 생성
  → 작업 중단 + 대기

Architect가 발견 (/monitor 또는 inbox-watcher.sh)
  → 요청 읽기
  → 처리 (스펙 변경, 터미널 명령 실행, 답변)
  → inbox/{워커}-response.md 작성
  → 워커에게 tmux로 알림: "응답 확인해"

워커가 응답 읽기
  → 작업 재개
  → request + response 파일 삭제
```

### 자동 감시
```bash
# 백그라운드 워처 (5초 간격, macOS 알림)
./inbox-watcher.sh &

# 또는 /monitor에서 수동 확인
/monitor
```

### 요청 유형
| 유형 | 예시 |
|------|------|
| 스펙변경 | "Response에 totalCount 필드 필요합니다" |
| 권한 | "Docker 실행 권한이 없습니다" |
| 터미널명령 | "gradle daemon 재시작 필요합니다" |
| 질문 | "이 엔드포인트 페이지네이션 방식은?" |
| 블로커 | "의존성 충돌로 빌드 불가" |

---

## 8. 모니터링

```bash
# 전체 현황 한눈에
/monitor

# 워커 pane 확인
tmux capture-pane -t aidy:architect.{1,2,3} -p | tail -5

# WO 파이프라인
./architect-cli.sh status

# 특정 워커 git 상태
cd ~/Develop/aidy-server && git log --oneline -5
```

---

## 9. tmux 조작법

| 조작 | 키 |
|------|-----|
| pane 간 이동 | `Ctrl+B → 방향키` |
| pane 최대화/복원 | `Ctrl+B → z` |
| 스크롤 모드 | `Ctrl+B → [` (q로 나가기) |
| 세션 분리 | `Ctrl+B → d` |
| 세션 재접속 | `tmux attach -t aidy` |

---

## 10. 토크노믹스 (토큰 절약)

### .claudeignore
각 워커 프로젝트에 `.claudeignore`를 배치하여 빌드 산출물, IDE 파일, 캐시를 제외.
- **server**: build/, .gradle/, .idea/, logs/
- **ios**: DerivedData/, .build/, *.xcodeproj/, Tuist/.build/
- **android**: build/, .gradle/, .idea/, *.apk

### RTK (Rust Token Killer)
`rtk`가 설치되어 있으면 Claude Code hooks가 자동으로 git/ls 등을 rtk로 프록시.
60-90% 토큰 절약. `rtk gain`으로 절약량 확인.

### 핸드오프 정책 (토큰 효율)

**매번 재시작 금지.** 재시작은 CLAUDE.md 재로드 + 세션 초기화로 ~3K tokens 낭비.

| 상황 | 액션 |
|------|------|
| 작업 완료 → 다음 작업 | **같은 세션에 새 프롬프트 전송** (재시작 X) |
| CLAUDE.md / settings.json 변경 | 재시작 필요 (설정 반영) |
| 워커 컨텍스트 오염 (이상 동작) | 재시작 |
| 10+ 라운드 누적 | 재시작 (컨텍스트 비대화 방지) |

---

## 11. 비상 절차

### 워커가 멈춘 경우
```bash
# pane 상태 확인
tmux capture-pane -t aidy:architect.{N} -p | tail -10

# Claude Code 재시작
tmux send-keys -t aidy:architect.{N} "/exit" C-m
sleep 3
tmux send-keys -t aidy:architect.{N} "claude --dangerously-skip-permissions" C-m
```

### 워커가 스펙을 무시한 경우
```bash
# 즉시 /cross-session-review 실행
# Gate 1 FAIL 처리 → 재작업 지시
```

### 전체 세션 복구
```bash
tmux kill-session -t aidy
./architect-cli.sh tmux-setup
# 또는 수동으로 4분할 레이아웃 재구성
```

---

## 11. gstack 스킬 활용

Architect가 사용할 수 있는 gstack 스킬:

| 스킬 | 사용 시점 | 효과 |
|------|----------|------|
| `/review` | Gate 검증 시 | 워커 diff를 자동 분석, 구조적 이슈 탐지 |
| `/browse` | 서버 API 테스트 | 실제 URL 접속하여 응답 검증 |
| `/qa` | 통합 QA | 웹앱 전체 테스트 + 버그 발견 |
| `/investigate` | 빌드 실패 시 | 4단계 디버깅 (조사→분석→가설→구현) |
| `/cso` | 보안 감사 | OWASP Top 10, 의존성 감사, 시크릿 탐지 |
| `/ship` | PR 생성 | 테스트→리뷰→PR→push 자동화 |
| `/health` | 코드 품질 | 타입체크+린트+테스트+데드코드 종합 점수 |
| `/ingest` | 외부 학습 | URL→교차검증→Aidy 적용 |

---

## 12. Compound Engineering 성숙도

현재 Aidy 프로젝트 상태: **Stage 2~3**

| Stage | 상태 | Aidy 현재 |
|-------|------|----------|
| 1. 수동 | 모든 박제를 기억해서 수행 | ❌ 지나옴 |
| 2. 리마인드 | hooks가 박제를 상기시킴 | ✅ settings.json hooks |
| 3. 슬래시 커맨드 | 박제가 한 커맨드에 통합 | ✅ /compound, /gate-1 등 |
| 4. 자동 루프 | N 라운드 자동 반복 | ⏳ 목표 |
| 5. 완전 자율 | 사람이 회고만 읽음 | — |

**목표**: Stage 3 안정화 → 서버 완료 후 클라이언트 병렬 자동 디스패치 (Stage 4)

---

## For AI Agents

다음 Architect 세션에서 이 가이드를 입력으로 받을 때:

1. **tmux 레이아웃**: 왼쪽 1 (architect) : 오른쪽 3 (server/ios/android) — `main-vertical` + pane 0 폭 135
2. **워커 모드**: `--dangerously-skip-permissions` 로 실행 (속도, Gate로 품질 보장)
3. **4단계 루프**: Plan(/dispatch) → Work(워커) → Review(/gate-1,2) → Compound(/compound) 를 매 WO마다 반복
4. **메타데이터 신뢰 금지**: 워커가 "완료"라고 해도 `/cross-session-review`로 코드만 본다
5. **architect-cli.sh의 send 명령은 윈도우 기반** — pane으로 합친 경우 `tmux send-keys -t aidy:architect.{N}` 직접 사용
