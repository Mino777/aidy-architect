# WO-013: iOS 워크플로 통합 검토 (test.yml + ai-review.yml 중복 제거)

**담당**: ios
**우선순위**: P3-낮음 (현재 동작은 OK, 효율성 개선)
**상태**: backlog → in-progress → gate-1 → gate-2 → done
**의존**: WO-010 done, ADR-009

## 목표
`test.yml` 과 `ai-review.yml` 의 중복 작업(둘 다 tuist install/generate/build 실행)을 정리한다. 옵션 평가 후 1개 채택.

## 발견 경로
WO-010 완료 보고(2026-04-17) + ADR-009 후속 검토 항목:
- `test.yml` (PR 트리거): tuist install + generate + xcodebuild test
- `ai-review.yml` (비-main push 트리거): tuist install + generate + tuist build + squash merge
- 같은 PR에서 둘 다 돌면 동일 빌드를 2회 수행

self-hosted runner라 분 비용 0이지만, 큐 직렬화로 PR feedback 시간 길어짐.

## 옵션 (의사결정 필요)

### A) Test 결과를 Auto Merge가 받아서 머지
- ai-review.yml의 build/test step 제거 → `workflow_run` 으로 test.yml green 후 트리거
- 장점: 중복 제거, 명확한 의존
- 단점: workflow_run 의존성 디버깅 까다로움

### B) Auto Merge를 별도 워크플로에서 분리
- ai-review.yml 은 rebase + squash merge 로직만 담당
- 빌드/테스트는 test.yml에 집중 (브랜치 별 path filter는 동일)
- 장점: 단순. 단점: A안과 유사

### C) Auto Merge 폐지 + 수동 머지
- PR review/머지를 사람이 수행
- 장점: 단순. 단점: autoceo 자동화 흐름 깨짐

## 구현 요구사항
1. 옵션 A/B/C 중 1개 선택 (Architect 의사결정 또는 워커가 evaluation 후 제안)
2. 선택 옵션 구현 + dry-run
3. WO-010 baseline 유지 (124 tests, self-hosted, path filter)

## 검증 기준
- [ ] PR 1건 push 시 빌드/테스트 1회만 수행
- [ ] 머지 자동화 유지 (A/B 선택 시)
- [ ] 124 tests 통과
- [ ] 알림 폭탄 재발 없음

## 비고
WO-010 의 핵심 목표(green + 알림 멈춤)는 달성됨. 이번 WO는 효율성 개선이며 시급도 낮음.
