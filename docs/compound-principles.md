# Compound Engineering 12 원칙 — Aidy 적용

> 출처: ai-study wiki "Compound Engineering 철학" (13 referencing 엔트리에서 교차 검증)
> 핵심: 한 스프린트의 산출물이 다음 스프린트의 정확한 입력이 되도록 설계

---

## 12 원칙

### 1. 사이클이 곧 자산
WO 완료 = 코드 + 회고 + 솔루션 + CHANGELOG. 하나라도 빠지면 사이클 미완료.

### 2. 행동에 박는 가드 > 기억에 의존하는 가드
settings.json hooks, /dispatch 원자적 실행이 이 원칙의 구현체.
기억으로 "나중에 해야지" → 100% 누락.

### 3. 사고는 다음 사이클의 입력
Gate 1 FAIL은 실패가 아니라 다음 WO의 가장 높은 ROI 입력.

### 4. 박제는 맥락 + 검증 방법 포함
`docs/solutions/`에 증상만 쓰지 않는다. 근본 원인 + 재발 방지 체크리스트 필수.

### 5. 박제 전이성
회고/솔루션은 다른 워커 세션도 읽을 수 있어야 한다. "For AI Agents" 섹션 필수.

### 6. 사이클 분할 — 한 사이클에 한 WO
한 번에 여러 WO 동시 진행 금지. 어느 변경이 어느 효과를 만들었는지 추적 가능해야.

### 7. 병렬 박제 (3 Agent)
/compound의 Phase 2에서 회고, 솔루션, 의사결정을 병렬 생성. 품질 유지 + 시간 효율.

### 8. 부분 실행 불가능
/compound, /dispatch는 전체 Phase를 한 커맨드로 묶음. 부분 실행 자체를 차단.

### 9. 사고 재발률 0
같은 문제 2회 발생 → 메모리 레벨 가드를 행동 레벨(hook/workflow)로 상향.

### 10. 메타데이터 신뢰 금지
gate-reviewer의 핵심 원칙. 커밋 메시지, PR 설명이 아닌 코드 line-by-line.

### 11. LLM-First 박제
회고/솔루션은 사람 서술이 아닌 AI 에이전트가 즉시 실행 가능한 형태.

### 12. 4단계 루프
Plan → Work → Review → Compound. Aidy에서는:
- Plan: WO 발행 + /dispatch
- Work: 워커 구현
- Review: /gate-1 → /gate-2 → /cross-session-review
- Compound: /compound

---

## Aidy 현재 성숙도: Stage 3

| Stage | 상태 | Aidy 현황 |
|-------|------|----------|
| 1. 수동 | 기억 의존 | 통과 |
| 2. 리마인드 | hooks 알림 | 통과 (PostToolUse compound 리마인더) |
| 3. 슬래시 커맨드 | /compound 등 | **현재** (8개 커맨드 운용) |
| 4. 자동 루프 | /autoceo N라운드 | 실험 중 (2라운드 dogfooding 완료) |
| 5. 완전 자율 | 사람은 회고만 읽음 | 목표 |

---

## For AI Agents

이 문서를 읽은 에이전트는:
- WO 완료 후 반드시 /compound 실행 (원칙 1, 8)
- Gate FAIL을 다음 WO 입력으로 활용 (원칙 3)
- 솔루션 작성 시 "For AI Agents" 섹션 포함 (원칙 5, 11)
- 같은 이슈 재발 시 hook 추가 제안 (원칙 9)
