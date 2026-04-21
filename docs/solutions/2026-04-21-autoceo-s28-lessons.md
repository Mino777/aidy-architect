# autoceo s28 세션 교훈 (2026-04-21)

## 크래시 2회 발생
- **iOS R4**: 세션 종료 (원인 미진단 → 이후 crash-log 명령 추가)
- **Server R5**: 세션 종료 (원인 미진단)
- **교훈**: 재시작 전 pane 캡처 + 시스템 상태 수집 필수

## Android 테스트 미실행
- assembleDebug만 실행하여 컴파일만 확인
- testDebugUnitTest 미실행 → 테스트 로직 검증 누락
- **교훈**: verify 명령 사용으로 빌드+테스트 일괄 검증

## 프롬프트 품질 저하 (후반 라운드)
- R2~R3 프롬프트: 상세 (WO + 스펙 섹션 + 금지사항 + 커밋 규칙)
- R5 프롬프트: 간략 (에지 케이스 나열만, 기대 테스트 수 없음)
- **교훈**: 후반 라운드에서도 프롬프트 품질 유지, 체크리스트 활용

## 개선 조치
1. `architect-cli.sh crash-log` 명령 추가 (OOM/TOKEN/RATE_LIMIT/NETWORK 분류)
2. 메모리에 FAIL/META/VERIFY 피드백 3개 추가
3. 바선생 L5.5 → L6.0 목표 설정 (FAIL 5.5+, META 5.5+)
