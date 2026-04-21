# ADR-009: Agent Teams 마이그레이션 로드맵

## 상태: PROPOSED (실험 단계 — Agent Teams가 GA되면 실행)

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

## 결정

**Phase 1 (현재)**: tmux 기반 유지 + Anthropic 공식 패턴 개별 도입
- Advisor 자문 프로토콜 (도입 완료)
- Hook 자동 Gate-1 (도입 완료)
- Worktree 격리 (도입 완료)

**Phase 2 (Agent Teams GA 시)**: 점진적 전환
- Lead = Architect 역할
- Teammates = Server/iOS/Android 워커
- WO 파일 시스템 → 공유 태스크 목록으로 전환
- inbox 프로토콜 → 직접 메시징으로 전환

**Phase 3 (안정화 후)**: tmux 레이어 완전 제거
- `architect-cli.sh send` → Agent Teams 네이티브 메시지
- `watch-workers` → 네이티브 완료 알림
- `preflight` 등 시스템 점검은 유지

## 전환 조건 (Phase 2 시작 기준)

- [ ] Agent Teams가 GA (experimental 해제)
- [ ] 세션 재개 지원
- [ ] 파일 충돌 방지 메커니즘 내장
- [ ] 토큰 오버헤드가 tmux 대비 20% 이내

## 호환 레이어

전환 기간 동안 `architect-cli.sh`가 두 모드를 지원:
```bash
# 환경변수로 모드 선택
AIDY_AGENT_MODE=tmux   # 기본값 (현재)
AIDY_AGENT_MODE=teams  # Agent Teams 모드
```

## 리스크

- Agent Teams 실험 단계에서 API 변경 가능
- 토큰 비용 증가 (Lead가 모든 통신을 중개)
- 세션 재개 미지원으로 장기 작업 불안정
