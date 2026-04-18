# ADR-011: WO 에이전트 라우팅 — 정적 유지, AgentCompiler 불채택

- **상태**: Accepted
- **날짜**: 2026-04-19
- **출처**: ai-study 허브 이슈 #1 (멀티 Claude 에이전트 관리: 컴파일 전략)

## 맥락

ai-study 위키의 "멀티 Claude 에이전트 관리: 컴파일 전략" 엔트리에서 AgentCompiler 패턴을 소개.
현재 Aidy의 WO 라우팅이 정적 설정인데, 동적 컴파일로 전환할지 검토 요청.

## 현재 라우팅 구조

### 정적 할당 (3단계)

```
1. WO 작성 시: **담당**: server|ios|android (Architect 수동 결정)
2. /dispatch 시: WO 파일에서 담당 필드 파싱 → tmux pane 매핑
3. architect-cli.sh: server→pane1, ios→pane2, android→pane3 (하드코딩)
```

### 프롬프트 조립 (정적 컴파일)

```
architect-cli.sh wo {번호}:
  1. CLAUDE.md (워커 프로젝트)
  2. specs/api-contract.md
  3. specs/conventions.md
  4. work-orders/in-progress/{WO 파일}
  5. gates/test-policy.md
```

### 워커 상태 감지 (제한적 동적)

- `is_pane_idle()`: tmux pane 프롬프트 시그니처로 idle 판별
- `wait_for_idle()`: 15초 간격 폴링
- 429 감지 + 300초 자동 backoff

## AgentCompiler 패턴 적용 시 이점

| 이점 | 설명 |
|------|------|
| 자동 할당 | 워커 능력/부하를 평가해서 최적 워커에 라우팅 |
| 동적 프롬프트 | 워커 상태에 따라 컨텍스트 조합 변경 |
| 확장성 | 새 워커 추가 시 코드 변경 최소화 |

## AgentCompiler 패턴 적용 시 리스크

| 리스크 | 설명 | 심각도 |
|--------|------|--------|
| 과잉 엔지니어링 | 워커 3개 고정, 역할 명확 — 라우팅 결정이 자명 | High |
| 토큰 오버헤드 | 능력 평가 + 동적 컴파일 자체가 토큰 소비 | Medium |
| 디버깅 난이도 | 동적 라우팅은 "왜 이 워커에 갔는지" 추적 어려움 | Medium |
| 안정성 | 현재 56 WO 무사고 — 변경 동기 부족 | High |

## 결정

**현행 정적 라우팅 유지. AgentCompiler 불채택.**

### 근거

1. **워커 3개, 역할 고정**: server=백엔드, ios=iOS, android=Android. 라우팅 결정이 WO 작성 시점에 자명. "어디에 보낼지" 고민한 적이 한 번도 없음.

2. **ADR-003 (Client Sync Rule)**: iOS와 Android는 항상 동일한 작업을 수행. 라우팅이 아니라 "동시 디스패치"가 패턴. 동적 할당의 가치가 없음.

3. **비용 대비 효과**: AgentCompiler는 워커 수 10+, 역할 중첩, 부하 분산이 필요할 때 가치. 현재 규모(3 고정)에서는 YAGNI.

4. **56 WO 실적**: 정적 라우팅으로 56개 WO 완주. 실패 원인이 라우팅이었던 적 없음.

## 전환 트리거 (재검토 조건)

다음 중 하나 이상 발생 시 AgentCompiler 재검토:

- [ ] 워커가 5개 이상으로 증가
- [ ] 역할 중첩 발생 (예: fullstack 워커)
- [ ] WO 할당 실수가 2회 이상 연속
- [ ] 워커 부하 불균형이 관측됨

## 참고

- ai-study 엔트리: "멀티 Claude 에이전트 관리: 컴파일 전략"
- 현재 CLI: `architect-cli.sh` (415줄)
- 관련 ADR: ADR-003 (Client Sync Rule)
