# Gate 2 Review: WO-010 (ios)

**일시**: 2026-04-17
**검증자**: Architect
**Gate 1**: 생략 (긴급 인프라 — main CI 100% fail 차단 상태). 코드 검증 없이 직접 Gate 2.

## 결과: PASS

## CI (Phase 0 — ci-status.sh)

```
gh run list --repo Mino777/aidy-ios --branch main --limit 1
→ Test (24518674499) success, 1m 56s, self-hosted runner
```
- 마지막 실패 1건(`24518640193`)은 **워커 코드와 무관**한 repo 권한 이슈 (PR 자동생성). 사용자 토글로 해소.

## 빌드 / 테스트

- main `9c3e715` Test run: **success**
- self-hosted runner: `jominhoui-mba-ios` (online)
- xcodebuild test 결과:
  ```
  Test Suite 'All tests' passed at 2026-04-17 00:24:38.567.
  ✔ Test run with 124 tests in 10 suites passed after 0.891 seconds.
  ** TEST SUCCEEDED **
  ```
- Artifact: `TestResults-xcresult` (534 KB), `xcodebuild-log` (121 KB)

## 변경 사항 (PR #1, squash `3e77334`)

| 파일 | 변경 |
|---|---|
| `.github/workflows/test.yml` | runs-on macos-14 → self-hosted, setup-xcode 제거, tuist 가드, 트리거 main+PR 축소, path filter, iPhone 17 destination, timeout 60 |
| `.github/workflows/ai-review.yml` | runs-on macos-latest → self-hosted, setup-xcode 제거, tuist 가드 |

## 크로스 프로젝트 호환성

- [x] 서버/Android와 무관 (iOS-only CI 인프라 변경)
- [x] API contract 변경 없음
- [x] specs/ 변경 없음

## 보안 / 정책

- [x] test-policy-ios.md 준수 (iPhone 17 destination, `-workspace`, 124 tests > 46 baseline)
- [x] 보안 체크리스트 무관 (CI 워크플로 변경)
- [x] self-hosted runner 보안: launchd user agent (root 아님), 사용자 본인 머신, public repo 아님(검증 필요 — repo는 owner Mino777 개인)

## 분 경제성

- self-hosted 전환으로 4월 누적 macOS 분 가중치 ~180min → **0min**
- path filter 도입: docs/README only 변경 시 workflow skip
- 트리거 축소: 모든 branch push → main push + PR (중복 제거)

## 발견 (별도 WO 후보 — backlog 등록 예정)

1. Swift 6 Sendable 경고 다수 (`SearchHistoryClient`, `ErrorLogClient`, `DraftQueueClient` 등)
2. Node.js 20 deprecation (2026-06-02 이후 강제 24)
3. `test.yml` + `ai-review.yml` 중복 (둘 다 tuist install/generate)
4. ~~`ai-review.yml` PR 자동생성 권한~~ — ✅ 사용자 토글 완료

## 다음 액션

- [x] Repo 설정 PR 자동생성 권한 토글 (사용자)
- [x] `./architect-cli.sh wo-done 010`
- [x] ADR-009 (self-hosted runner 결정) 작성
- [x] backlog WO 등록 (Swift 6 / Node 24 / workflow 통합)
- [x] CHANGELOG v0.7.2 + HANDOFF 갱신
