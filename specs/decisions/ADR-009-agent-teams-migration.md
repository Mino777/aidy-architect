# ADR-009: Agent Teams 마이그레이션 로드맵

## 상태: ACCEPTED (하이브리드 모델 — 즉시 도입)

## 컨텍스트

현재 Architect-Worker 시스템은 tmux 기반 비동기 메시지 패싱으로 동작한다:
- `tmux send-keys`로 워커에게 명령 전송
- `inbox/` 파일 시스템으로 자문/요청 처리
- `watch-workers` bash 스크립트로 완료 감지

Claude Code Agent Teams (실험적)은 네이티브 멀티에이전트를 지원:
- `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` 환경변수로 활성화
- Lead + Teammate 구조
- 직접 메시징, 공유 태스크 목록

## 현재 vs Agent Teams 비교

| 기능 | tmux 시스템 (현재) | Agent Teams |
|------|-------------------|-------------|
| 워커 생성 | `tmux split-pane` + `claude` | Claude가 자동 생성 |
| 명령 전달 | `tmux send-keys` | 직접 메시지 |
| 완료 감지 | `watch-workers` 폴링 | 네이티브 알림 |
| 자문 요청 | inbox 파일 기반 | 직접 메시지 |
| 상태 추적 | WO 파일 시스템 | 공유 태스크 목록 |
| 세션 재개 | `/exit` + 재시작 | 미지원 (제한) |
| 토큰 비용 | 독립 세션 (각자 컨텍스트) | Lead에 추가 오버헤드 |

## 결정: 하이브리드 모델 (즉시 도입)

Architect ↔ Worker는 tmux 유지, **Worker 내부에서 Agent Teams 사용**.

```
Architect (tmux 오케스트레이션)
  ├── Server 워커 ← Agent Teams (같은 repo 내 병렬)
  │     ├── Teammate: Entity + Migration
  │     ├── Teammate: Service + Controller
  │     └── Teammate: Tests
  │
  ├── iOS 워커 ← Agent Teams
  │     ├── Teammate: Model + Client
  │     ├── Teammate: Feature (TCA)
  │     └── Teammate: View + Tests
  │
  └── Android 워커 ← Agent Teams
        ├── Teammate: Data layer
        ├── Teammate: ViewModel
        └── Teammate: UI + Tests
```

**왜 하이브리드인가:**
- Agent Teams = 단일 repo 내 병렬에 최적 → 각 워커가 자기 repo 안에서 팀 운영
- Architect ↔ Worker = 프로젝트 분리형 → tmux가 더 효율적
- 실험 단계 리스크가 워커 1개로 제한 (폭발 반경 최소)

**기대 효과:**
- WO 1개 처리 시간: 10분 → 4-5분 (레이어별 병렬)
- 순차 의존성(Entity→Service→Controller)은 Teams가 자동 조율

**활성화:**
```bash
# 워커 세션 시작 시 환경변수 추가
CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1 claude --dangerously-skip-permissions
```

## 폴백 전략

Worker 내부 Agent Teams가 불안정할 경우:
- 환경변수 제거 → 기존 단일 워커 모드로 즉시 복귀
- Architect 측 변경 불필요 (tmux dispatch는 동일)

## Architect 레벨 전환 조건 (tmux → Agent Teams 완전 전환)

Architect ↔ Worker 간 통신까지 Agent Teams로 전환하는 조건:
- [ ] Agent Teams가 GA (experimental 해제)
- [ ] 멀티 repo 지원
- [ ] 세션 재개 지원
- [ ] 토큰 오버헤드가 tmux 대비 20% 이내

## 왜 현재 tmux가 Agent Teams보다 효율적인가

### tmux가 우위인 영역

| 항목 | tmux (현재) | Agent Teams | 판정 |
|------|------------|-------------|------|
| **토큰 효율** | 워커 각자 독립 컨텍스트, 중개 비용 0 | Lead가 모든 통신 중개 → 토큰 오버헤드 | tmux 승 |
| **세션 재개** | `/exit` + 재시작 자유자재 | 미지원 (실험 단계 제한) | tmux 승 |
| **파일 충돌** | 워커별 프로젝트 분리 (server/ios/android) → 충돌 0 | 같은 repo 작업 시 충돌 위험 | tmux 승 |
| **제어 정밀도** | architect-cli.sh로 세밀한 순서/타이밍 제어 | Claude 자동 조율 (블랙박스) | tmux 승 |
| **안정성** | 2주+ 실전 검증 (s28~s30, 120+ WO) | 실험적, API 변경 가능 | tmux 승 |
| **디버깅** | tmux pane 직접 관찰, crash-log 명령 | 내부 상태 불투명 | tmux 승 |

### Agent Teams가 우위일 수 있는 영역

| 항목 | 설명 | Aidy에 해당? |
|------|------|-------------|
| **단일 repo 병렬** | 같은 프로젝트에서 여러 에이전트 협업 | ❌ (프로젝트 분리됨) |
| **워커 간 직접 소통** | 워커끼리 조율이 빈번할 때 | ❌ (허브-스포크 구조) |
| **자동 태스크 분해** | 작업을 자동으로 분배 | ❌ (WO 기반 명시적 분배가 Gate 검증에 유리) |
| **부팅 자동화** | 워커 세션 생성이 자동 | △ (tmux-setup으로 충분) |

### 핵심 결론

Aidy는 **프로젝트 분리형 허브-스포크 오케스트레이션**이다.
Agent Teams는 **단일 repo 내 피어 협업**에 최적화되어 있다.
구조적 미스매치가 있으므로, Agent Teams가 GA + 멀티 repo 지원 + 토큰 최적화될 때까지 tmux 유지가 합리적.

## 리스크

- Agent Teams 실험 단계에서 API 변경 가능
- 토큰 비용 증가 (Lead가 모든 통신을 중개)
- 세션 재개 미지원으로 장기 작업 불안정
