# restart-workers 즉시 종료 이슈 (Claude 재시작 시)

## 증상
`/exit` 후 `claude --dangerously-skip-permissions` 재시작하면 Claude가 즉시 종료.
"Resume this session with: claude --resume ..." 출력 후 쉘 프롬프트로 돌아감.

## 해결 (before → after)
- **before**: `/exit` → `sleep 3` → `claude` 재시작 (타이밍 불안정)
- **after**: 
  1. PGID kill로 고아 프로세스 완전 정리
  2. C-c 2회 전송
  3. shell 프롬프트 복귀 대기 (최대 5초)
  4. 2초 간격으로 순차 재시작 (동시 시작 방지)
  5. 15초 후 ready 확인

## 근본 원인
`/exit` 후 Claude 프로세스는 종료되지만 Node.js 서브프로세스가 고아로 남음.
이 상태에서 새 Claude를 시작하면 stdin 충돌 또는 이전 세션 resume 트리거.

## 체크리스트 (재발 방지)
- [ ] `./architect-cli.sh restart-workers` 사용 (수동 send + sleep 금지)
- [ ] 재시작 후 3/3 ready 확인 로그 출력 확인
