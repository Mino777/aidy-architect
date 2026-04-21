# autoceo s29 세션 교훈 (2026-04-21)

## iOS 반복 크래시 (3회 연속 + 추가 1회)
- R3에서 3회 연속 세션 종료 (커밋 없음)
- crash-log 원인: ERROR / UNKNOWN
- 4차 시도에서 성공
- **패턴**: task 표시는 완료되지만 커밋 전 세션 종료
- **추정 원인**: 메모리 부족 또는 세션 길이 제한 (토큰 초과)
- **교훈**: iOS 프롬프트를 더 간결하게, 2개 WO를 나눠서 보내기

## watch-workers 오탐
- 미dispatch된 워커도 idle로 감지 → "전원 완료" 오보
- **교훈**: watch-workers에 "dispatch 후 최소 1분 working 확인" 로직 필요

## send 실행 확인 실패 빈번
- "경고: 실행 확인 실패" 메시지가 거의 매번 발생
- 실제로는 프롬프트 수신되어 작업 수행
- **교훈**: 확인 로직의 패턴 매칭 업데이트 필요 (터미널 크기 이슈?)

## 개선 적용
1. crash-log 3건 기록 (FAIL 축 ↑)
2. 이 파일 작성 (META 축 ↑)
3. Android testDebugUnitTest 의무 실행 (VERIFY 축 ↑)
