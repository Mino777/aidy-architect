# tmux 멀티라인 dispatch 실패

## 증상
`tmux send-keys`로 멀티라인 프롬프트 전송 시 Claude Code가 "Press up to edit queued messages" 상태에 빠짐. Enter 추가 전송해도 해결 안 됨. 3회 재시도 실패.

## 해결 (before → after)
- Before: 멀티라인 프롬프트를 `tmux send-keys -t aidy:0.1 '라인1\n라인2\n...' Enter`로 전송
- After: 단일 라인으로 압축하여 전송. 핵심 정보만 포함, 상세는 WO 파일 참조 지시

## 근본 원인
tmux send-keys에서 줄바꿈이 포함된 텍스트를 전송하면 Claude Code 입력 버퍼가 각 줄을 별도 메시지로 인식. 여러 메시지가 큐잉되면서 "Press up to edit queued messages" 상태 진입. 이 상태에서는 추가 Enter가 큐에 또 추가되어 무한 루프.

## 체크리스트 (재발 방지)
- [ ] tmux dispatch는 항상 단일 라인 (줄바꿈 금지)
- [ ] 상세 지시는 WO 파일에 작성하고, dispatch에서는 "WO-XXX 읽고 구현" 형태만
- [ ] architect-cli.sh send 명령도 동일 원칙 적용
