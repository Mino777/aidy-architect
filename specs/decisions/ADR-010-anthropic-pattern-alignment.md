# ADR-010: Anthropic 공식 에이전트 패턴 정렬

## 상태: ACCEPTED

## 컨텍스트

Anthropic "Building Effective Agents" 가이드에서 5가지 공식 패턴을 정의.
우리 시스템이 이미 대부분을 구현하고 있지만, 공식 권장사항과 정렬이 필요.

## Anthropic 5대 패턴 → Aidy 매핑

### 1. Prompt Chaining (순차 처리)
**공식**: 작업을 고정 단계로 분리, 각 단계 출력이 다음 입력
**Aidy 구현**: autoceo의 Step 1→2→3→4→5 순차 실행
- Research → Plan → Dispatch → QA → Compound
- 각 단계 결과가 다음 단계 입력으로 사용

### 2. Routing (입력 분류)
**공식**: 입력 유형에 따라 전담 핸들러로 분기
**Aidy 구현**: 
- 워커 타입별 라우팅 (server/ios/android)
- Gate 유형별 라우팅 (gate-1 축약/풀, gate-2)
- WO 우선순위 라우팅 (P0~P4)

### 3. Parallelization (병렬 실행)
**공식**: 독립적 서브태스크를 동시 실행 후 결과 통합
**Aidy 구현**:
- 2-way/3-way 워커 병렬 dispatch
- Gate-1 백그라운드 서브에이전트 병렬
- 파이프라이닝 (서버 대기 중 클라이언트 선행 dispatch)

### 4. Orchestrator-Worker (오케스트레이터-워커)
**공식**: 중앙 조율자가 동적으로 작업 분해 → 전담 워커 위임
**Aidy 구현**: 이것이 우리 핵심 패턴
- Architect (Opus) = Orchestrator
- Server/iOS/Android Claude = Workers
- WO = 동적 작업 분해 단위
- Gate = 결과 통합 검증

### 5. Evaluator-Optimizer (평가-최적화 루프)
**공식**: 생성기가 만들고, 평가기가 검증, 기준 미달 시 재생성
**Aidy 구현**:
- 워커 = 생성기 (코드 구현)
- Gate-1/2 = 평가기 (스펙 검증)
- FAIL → 수정 지시 → 재구현 (최대 3회)
- auto-gate1.sh = 커밋 시점 실시간 평가

## 추가 도입한 Anthropic 패턴

### 6. Advisor (자문)
**공식**: 빠른 executor가 막히면 고급 advisor에게 자문
**Aidy 구현**: inbox 파일 기반 자문 프로토콜
- 워커(executor) → inbox/advise.md → Architect(advisor) → inbox/advice.md
- 5분 타임아웃 + [자율판단] 폴백

### 7. Hooks (도구 수명주기)
**공식**: PreToolUse/PostToolUse에서 자동 검증/경고
**Aidy 구현**:
- PreToolUse: git commit 시 빌드 검증 + 스펙 대조 (auto-gate1.sh)
- PreToolUse: 금지 명령 차단 (reset --hard, push --force 등)
- PostToolUse: git push 시 Compound 리마인드

### 8. Worktree Isolation (격리 실행)
**공식**: 서브에이전트를 격리된 git worktree에서 실행
**Aidy 구현**: Gate-1 서브에이전트에 isolation: "worktree" 적용

## 앞으로의 원칙

> **새 패턴 도입 시 반드시 Anthropic 공식 문서를 확인하고, 공식 권장 방식을 우선 채택한다.**
> 공식 패턴에 단점이 있다면 문서화하고, 대안을 ADR로 기록한다.
