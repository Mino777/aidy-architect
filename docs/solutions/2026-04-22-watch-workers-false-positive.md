# watch-workers 오탐 (dispatch 직후 idle 판정)

## 증상
dispatch 직후 watch-workers가 워커를 "idle"로 판정하고 즉시 "[완료]" 알림 전송.
실제로는 워커가 아직 프롬프트를 받지 못한 상태.

## 해결 (before → after)
- **before**: `sleep 10` 후 바로 idle 체크 시작
- **after**: 60s warmup 동안 모든 워커가 "working" 상태로 전환될 때까지 대기.
  3단계 상태 추적: 0=미확인 → 1=working확인 → 2=완료알림済.
  working 확인 안 된 워커는 idle 판정하지 않음.

## 근본 원인
`is_pane_idle()`은 tmux pane에 "bypass permissions on"이 보이면 idle로 판정.
dispatch 직후 워커가 프롬프트를 아직 처리하기 전에도 이 문자열이 보임.

## 체크리스트 (재발 방지)
- [ ] watch-workers 호출 시 warmup 단계에서 "전원 working 확인" 로그 출력 확인
- [ ] dispatch 후 최소 1분은 idle 판정하지 않음
