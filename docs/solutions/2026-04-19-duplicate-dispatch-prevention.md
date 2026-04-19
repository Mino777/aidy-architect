# architect-cli.sh send 중복 전송 방지

## 증상
R7에서 서버 워커에 동일 작업 지시를 2번 전송. 첫 번째는 `run_in_background`로 Bash 호출, 두 번째는 정상 호출. 워커가 "(중복된 [R7] 메시지는 동일 작업이므로 위 커밋으로 처리 완료)"로 감지했지만 토큰 낭비.

## 해결 (before → after)
- Before: `Bash(run_in_background=true)` + `Bash(일반)` 혼용
- After: `architect-cli.sh send` 호출 시 항상 일반 Bash 사용. run_in_background 절대 사용 금지.

## 근본 원인
Architect가 send 명령을 run_in_background로 보내면 결과를 즉시 확인 못하고, 동일 명령을 다시 보냄.

## 체크리스트 (재발 방지)
- [ ] `architect-cli.sh send`는 항상 foreground Bash로 실행
- [ ] send 결과 "[완료]" 확인 후 다음 단계 진행
