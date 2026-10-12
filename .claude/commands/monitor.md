# /monitor — 전체 워커 상태 모니터링

모든 워커의 현재 상태를 한눈에 파악한다.

---

## Phase 1 — Work Order 현황

```bash
cd ~/Develop/aidy-architect
echo "=== BACKLOG ===" && ls work-orders/backlog/ 2>/dev/null || echo "(비어있음)"
echo "=== IN-PROGRESS ===" && ls work-orders/in-progress/ 2>/dev/null || echo "(비어있음)"
echo "=== DONE ===" && ls work-orders/done/ 2>/dev/null || echo "(비어있음)"
```

---

## Phase 2 — 워커 프로젝트 git 상태

각 워커 프로젝트의 최신 커밋 + 변경사항 확인:

```bash
for project in server ios android; do
  echo "=== aidy-$project ==="
  cd ~/Develop/aidy-$project
  git log --oneline -3
  git status --short
  echo ""
done
```

---

## Phase 3 — tmux 워커 세션 상태

```bash
tmux list-panes -t aidy:architect -F '#{pane_index}: #{pane_current_command} (#{pane_width}x#{pane_height})'
```

각 pane의 마지막 출력 확인:
```bash
for i in 1 2 3; do
  echo "=== pane $i ==="
  tmux capture-pane -t aidy:architect.$i -p | grep -v "^$" | tail -5
  echo ""
done
```

---

## Phase 4 — Inbox 요청 확인 (워커 → Architect)

워커가 막혀서 도움을 요청한 파일이 있는지 확인:

```bash
echo "=== Inbox ==="
ls ~/Develop/aidy-architect/inbox/*-request.md 2>/dev/null || echo "(요청 없음)"
```

요청이 있으면:
1. 요청 파일 읽기
2. 요청 처리 (스펙 변경, 터미널 명령 실행, 답변 등)
3. `inbox/{워커}-response.md`에 응답 작성
4. 워커에게 tmux로 알림: "응답 파일 확인해줘"

---

## Phase 5 — Gate 리뷰 현황

```bash
echo "=== Gate Reviews ==="
ls ~/Develop/aidy-architect/gates/reviews/ 2>/dev/null || echo "(아직 없음)"
```

---

## 출력 형식

```markdown
# 관제 현황 — YYYY-MM-DD HH:MM

| 워커 | WO | 상태 | 최근 커밋 | tmux |
|------|-----|------|----------|------|
| server | WO-001 | in-progress/done | abc1234 feat: ... | 대기중/작업중 |
| ios | WO-002 | backlog | ... | 대기중/작업중 |
| android | WO-003 | backlog | ... | 대기중/작업중 |

## Gate 현황
- Gate 1: 0/3 통과
- Gate 2: 0/3 통과

## 다음 액션
- [ ] ...
```
