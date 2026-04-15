# /dispatch — 워커에게 Work Order 전송

WO를 활성화하고 워커에게 전송한다. 부분 실행 불가능 — 활성화 + 전송 + 확인을 한번에.

## 입력

- WO 번호 (예: `001`)
- 또는 워커 이름 (예: `server`) — 해당 워커의 backlog WO를 자동 탐색

입력 없으면: *"어떤 WO를 전송할까요? (backlog 목록 표시)"*

---

## Phase 1 — WO 활성화

```bash
cd ~/Develop/aidy-architect
./architect-cli.sh wo {번호}
```

WO가 backlog에 없으면 중단.

---

## Phase 2 — 워커에게 프롬프트 전송

WO 파일에서 담당 워커를 추출하고, 아래 프롬프트를 tmux로 전송:

```bash
./architect-cli.sh send {워커} "너는 aidy-{워커} 워커야. 아래 파일을 순서대로 읽고 작업을 시작해:

1. ~/Develop/aidy-{워커}/CLAUDE.md
2. ~/Develop/aidy-architect/specs/api-contract.md
3. ~/Develop/aidy-architect/specs/conventions.md
4. ~/Develop/aidy-architect/work-orders/in-progress/WO-{번호}-{파일명}.md

work-order의 '구현 요구사항'을 하나씩 구현하고, 완료되면 git commit해줘. 커밋 메시지는 한글로.
스펙에 없는 엔드포인트나 필드를 절대 추가하지 마. 의심스러우면 멈추고 물어봐."
```

---

## Phase 3 — 전송 확인

5초 후 워커 pane 상태 확인:

```bash
sleep 5
tmux capture-pane -t aidy:architect.{pane} -p | grep -v "^$" | tail -5
```

워커가 파일을 읽기 시작했는지 확인. 안 됐으면 재전송.

---

## 출력

```
✅ WO-{번호} → {워커} 전송 완료
   상태: backlog → in-progress
   pane: {번호}
   다음: 작업 완료 후 /gate-1 {워커} 실행
```
