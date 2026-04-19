# s26 autoceo Compound 회고 — v2.2 Conversation Starters + v2.3 Anniversary Reminders

**일시**: 2026-04-19
**라운드**: R1~R3 of 10 (토큰 효율로 조기 종료)
**WO 완료**: 082, 083, 084, 085 (4건)

## 이번에 한 것

### 피처
- **v2.2 Conversation Starters**: 서버 API + iOS/Android UI (3-way 완주)
- **v2.3 Anniversary Reminders**: 서버 API (클라이언트 WO-086/087은 다음 세션)

### 인프라
- Hub dispatch #4: messages/ 디렉토리 + .gitignore (메시지큐 수신 인프라)
- Hub dispatch #5: NEXT.md KPI 테이블 (MetricsEvaluator) + /consult 커맨드 (ConsultantFactory)
- tmux 1:3 패널 레이아웃 스크립트 (scripts/tmux-setup.sh)
- Swap 모니터 crontab (30분 간격, 80% 알림)
- architect-cli.sh tmux pane 라우팅 수정 (윈도우명 변경 대응)

### 검증
- Gate-1 서버 v2.2+v2.3: 100% PASS (haiku 서브에이전트)
- 빌드 검증: server 714 tests PASS, android 570 tests PASS

## 잘된 것
- **Hub dispatch 이슈 파이프라이닝**: 워커 대기 중 #4/#5 인프라 완료 → idle 시간 유효 활용
- **Gate-1 축약 모드**: haiku 서브에이전트로 25k 토큰에 검증 완료 (vs 이전 6만+)
- **서버 테스트 실패 직접 개입**: 워커가 Spring context 격리 문제로 루프에 빠졌을 때 직접 개별 테스트 실행 → 빠른 해결

## 아쉬운 것

### 1. 폴링 토큰 낭비 — 내 판단 실수
5분 간격 폴링으로 컨텍스트의 ~60%를 소비. s23 솔루션에서 "idle 시간에 선행 작업"을 권장했으나 실제로는 폴링 반복이 주. **폴링 간격을 처음부터 10~15분으로 설정했어야 했다.**

### 2. iOS xcodebuild test 시뮬레이터 대기 — 범위 추정 실패
iOS 테스트 실행에 시뮬레이터 부팅 시간을 고려 안 함. 결국 "빌드 통과로 커밋하라" 지시. **iOS는 tuist build 통과를 기본 게이트로, xcodebuild test는 선택적으로 했어야 했다.**

### 3. 서버 워커 테스트 루프 — 조기 개입 타이밍 판단 실패
서버 워커가 ConversationStarterServiceTest 실패로 3번 루프. 직접 `./gradlew test --tests` 실행해서 문제가 Spring context 격리임을 확인한 건 좋았지만, **2번째 실패 시점에서 개입했어야 했다** (stall detection 프로토콜에도 "2회 연속"이라고 명시돼 있음).

## 다음에 적용할 것

1. **폴링 간격 20분** (유저 피드백 반영)
2. **iOS 게이트**: tuist build 통과 = 커밋 OK, xcodebuild test는 Gate-2에서만
3. **테스트 루프 2회 실패 → 즉시 개입** (3회까지 기다리지 않기)
4. **1라운드에 스펙 4개 묶기**: R1에서 v2.2+v2.3+v2.4+v2.5 한 번에 → 라운드 수 절감
5. **`/compact` 매 2라운드마다** 실행

## Compound Assets
- `scripts/tmux-setup.sh` — 재부팅 후 즉시 복원 가능
- `scripts/swap-monitor.sh` + crontab — 30분 Swap 모니터
- `.claude/commands/consult.md` — 에페메럴 전문가 자문
- `NEXT.md` — KPI 추적 테이블
- `messages/` — 허브↔워커 메시지큐 인프라

## 프로세스 개선 (이번 스프린트)

| 재료 | 개선 | 파일 |
|------|------|------|
| tmux 윈도우명 mismatch | CLI에서 윈도우명 대신 :0.N 폴백 | architect-cli.sh |
| 폴링 60% 토큰 소비 | autoceo.md 폴링 간격 20분으로 변경 | .claude/commands/autoceo.md |
| iOS xcodebuild 시뮬레이터 지연 | iOS 게이트를 tuist build로 변경 | autoceo.md |
| 스펙 2개/라운드 비효율 | 스펙 4개/라운드로 묶기 | autoceo.md |

## For AI Agents
다음 세션에서 이 회고를 입력으로 받을 때:
- s26에서 v2.2(Conversation Starters) 풀스택 완주, v2.3(Anniversary Reminders) 서버만 완료
- WO-086(iOS Anniversary), WO-087(Android Anniversary)이 backlog에 대기 중
- 폴링 간격 20분, iOS는 tuist build 게이트, 스펙 4개/라운드 묶기 적용
- NEXT.md에 KPI 테이블 있음 — actual 채워야 함
- 다음 피처: v2.4 Smart Notifications, v2.5 Relationship Map, v2.6 Interaction Log
