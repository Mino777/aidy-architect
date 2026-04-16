# iOS 워커 요청

**시각**: $(date) — 2026-04-16 세션
**유형**: 블로커 (계정/빌링)
**WO**: WO-010

## 내용
WO-010 요구사항 1~3 구현은 완료. 그러나 PR을 올리자마자 GitHub Actions가 다음 에러로 runner를 아예 띄우지 않음:

```
The job was not started because recent account payments have failed
or your spending limit needs to be increased.
Please check the 'Billing & plans' section in your settings.
```

- 실패한 새 run: `24517644432` (PR #1, chore/ci-macos15-economy)
- 참고: `Auto Merge to main` 이라는 별도 워크플로(내가 건드리지 않은)도 같은 이유로 FAIL — billing 블록이 맞음.
- WO 진단에는 "한도 초과 아님: 4월 누적 6 runs"라고 되어 있었지만, 현재 시점에서는 빌링 자체가 막혀 있음. 상태가 바뀐 것으로 추정.

## 현재상태
- 브랜치: `chore/ci-macos15-economy` 커밋 `b26bdd6` 푸시 완료
- PR: https://github.com/Mino777/aidy-ios/pull/1
- 로컬 변경 사항:
  - `runs-on: macos-14` → `macos-15`
  - 트리거: `push(main) + pull_request`
  - path filter: `Projects/**`, `Tuist/**`, `Project.swift`, `.github/workflows/test.yml`
  - 요구사항 4 (캐싱)는 보류 — 우선 블로커 해소 후 검토.

## 필요한 조치 (사용자/Architect)
1. GitHub https://github.com/settings/billing 에서 payment 갱신 또는 spending limit 조정
2. 그 후 내게 `inbox/ios-response.md` 로 "재시도 가능" 회신 주시면:
   - PR에서 `gh run rerun` 으로 재시도 → green 확인
   - main에 머지하여 main CI도 green 확인
   - WO "완료 보고" 작성 후 `ios-complete.md` 제출

## 대안 (빌링 해제 불가한 경우)
- self-hosted runner (본인 Mac)
- Xcode Cloud 전환
- WO 본문 "후속 옵션" 참고

응답 대기 중.
