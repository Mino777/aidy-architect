# iOS 워커 완료 보고 — WO-010

**시각**: 2026-04-17
**상태**: done (Gate 2 진입 가능)
**WO**: `work-orders/in-progress/WO-010-ios-ci-macos15-economy.md`

## 요약
GitHub-hosted (macos-14 → macos-15) 전환은 결제 차단으로 검증 불가 → Architect 결정대로 **self-hosted runner 전환**으로 완료. `test.yml` + `ai-review.yml` 둘 다 self-hosted 로 정리해서 알림 폭탄 해소. main branch 에서 124 tests / 10 suites TEST SUCCEEDED 확인.

## 수정 커밋 (main 기준)

| SHA | 메시지 | 출처 |
|---|---|---|
| `3e77334` | `[WO-010] ci: macos-15 runner + path filter (#1)` — PR #1 squash merge (req 1~3 + req 5 + iPhone 17 destination + ai-review self-hosted 포함) | Auto Merge 봇 |
| `9c3e715` | `[WO-010] ci: main push 경로 green 확인용 트리거` | 수동 fast-forward |

PR #1: https://github.com/Mino777/aidy-ios/pull/1 (MERGED 2026-04-16T15:18:11Z)

PR 내부 개별 커밋 (squash 되기 전):
- `b26bdd6` — req 1~3 (macos-15 + 트리거 축소 + path filter)
- `89b41f4` — req 5 (self-hosted runner, setup-xcode 제거, tuist 가드)
- `070d48f` — destination `iPhone 15 → iPhone 17` (Xcode 26.3 시뮬레이터 호환)
- `e630b5a` — ai-review.yml 도 self-hosted 전환

## CI Run 증거

### 최종 main Test run (Gate 2 검증)
- Run URL: https://github.com/Mino777/aidy-ios/actions/runs/24518674499
- Event: `push` on `main` (sha `9c3e715`)
- Runner: self-hosted `jominhoui-mba-ios`
- Duration: **1m 56s**
- Conclusion: **success**
- 로그 증거:
  ```
  Test Suite 'All tests' passed at 2026-04-17 00:24:38.567.
  ✔ Test run with 124 tests in 10 suites passed after 0.891 seconds.
  ** TEST SUCCEEDED **
  ```
- Artifact 업로드:
  - `TestResults-xcresult` (534 KB, not expired)
  - `xcodebuild-log` (121 KB, not expired)

### PR 검증 run
- https://github.com/Mino777/aidy-ios/actions/runs/24518168504 — 2m 25s, green, 124 tests passed (self-hosted 첫 green)
- https://github.com/Mino777/aidy-ios/actions/runs/24518370218 — 재확인 run (동일 코드 green)

### Auto Merge 검증
- https://github.com/Mino777/aidy-ios/actions/runs/24518363016 — 1m 45s, success, squash merge + branch reset 성공

## 4월 macOS 분 사용량 변화 (추정)

| 항목 | 이전 | 변경 후 |
|---|---|---|
| runner | GitHub-hosted macOS (분당 가중치 10x) | self-hosted (분 가중치 0) |
| 트리거 | 모든 branch push + PR (중복) | main push + PR, path filter 매치 시만 |
| docs/README 변경 시 | macOS runner 기동 | **skip** |
| ai-review.yml | macos-latest (매 비-main push 가중치 10x) | self-hosted 가중치 0 |
| 4월 누적 macOS 분 | 6 runs × ~3분 × 10 = ~180분 가중 | **0분 가중** (self-hosted) |

**실제 효과**: billing 차단으로 GitHub-hosted runner 자체가 못 돌던 상황 해소. 앞으로 macOS 분 소비 = 0.

## 적용한 path filter 경로

`.github/workflows/test.yml` 의 `on.push.branches: [main]` + `on.pull_request` 양쪽 `paths`:
```yaml
- 'Projects/**'          # 실제 소스/테스트 위치 (WO 권장 'Sources/**' 대신 repo 구조 기준)
- 'Tuist/**'             # Tuist/Package.swift, Package.resolved
- 'Project.swift'        # 루트 프로젝트 정의
- '.github/workflows/test.yml'   # 워크플로 self-test
```
※ WO 에 있던 `Package.swift` 는 루트에 없음 (Tuist/Package.swift 로 대체됨) → 제외.

`.github/workflows/ai-review.yml` 은 `branches-ignore: main` 만, path filter 없음 (rebase + build + merge 라 스펙상 모든 변경에 대해 돌아야 함 — 기존 유지).

## 캐싱 적용 여부
**미적용 (req 4 보류 확정).**
- 이유: self-hosted 는 로컬 디스크에 `~/Library/Developer/Xcode/DerivedData` 영구 보존 → `actions/cache` 불필요.
- 실제로 2m 25s → 1m 56s 로 단축되는 것도 DerivedData 재사용 효과로 추정.

## 적용한 step 단순화 (self-hosted 대응)

| Step | 기존 | 변경 후 |
|---|---|---|
| `Select Xcode (latest stable)` (`maxim-lobanov/setup-xcode@v1`) | 있음 | **제거**. 시스템 Xcode 26.3 (`xcode-select -p`) 사용. setup-xcode 의 macOS 26 호환성 불확실한데 시스템 Xcode 로 충분. |
| `Install Tuist` (`brew install --quiet tuist`) | 무조건 설치 | **`command -v tuist \|\| brew install --quiet tuist`** 가드. 이미 4.180.0 설치됨 → 즉시 pass. |
| `Show toolchain` (신규) | — | `xcode-select -p`, `xcodebuild -version`, `sw_vers` 로그 (self-hosted 환경 디버깅 대비). |
| `timeout-minutes` | 30 | **60** (self-hosted 는 분 가중치 없음). |
| `-destination name` | `iPhone 15` | **`iPhone 17`** (Xcode 26.3 시뮬레이터 + test-policy-ios.md 스펙과 일치). |

동일 단순화를 `ai-review.yml` 에도 적용 (runs-on / setup-xcode 제거 / tuist 가드).

## 특이사항 / 추가 발견

1. **billing 차단으로 검증 불가 (진단 시점 이후 변동)**
   - WO 원 진단 "분 한도 여유, 결제 정상" → 실제 실험 시점엔 "The job was not started because recent account payments have failed" 로 runner 미기동. Architect 정정 응답 #1 로 self-hosted 전환 결정.

2. **ai-review.yml 알림 폭탄**
   - test.yml 만 self-hosted 로 바꿨을 때, 비-main push 마다 `ai-review.yml` (runs-on: macos-latest) 가 여전히 호출되어 결제 차단 FAIL 알림 폭탄. Architect 응답 #2 지시로 동일하게 self-hosted 전환.

3. **GitHub path-filter 의 "filter 도입 커밋 자체" 평가 누락**
   - PR #1 squash merge 커밋 (`3e77334`) 은 `.github/workflows/test.yml` 을 수정했고 새 path filter 에도 포함되지만 main 에서 Test 트리거가 **안 일어남**. 이는 GitHub Actions 의 알려진 거동 (workflow 파일 자체를 처음 도입/수정하는 커밋은 푸시 시점의 OLD workflow 기준으로 평가될 수 있음 — 실험적으로 확인).
   - 우회: 다음 커밋 (`9c3e715`) 에서 한 줄 주석 추가 → 정상 트리거 → green.
   - 정식 수정 후에는 재발하지 않을 것 (다음 feature 커밋부터 자연스럽게 검증됨).

4. **Auto Merge 가 PR 자동 생성 불가**
   - `ai-review.yml` 의 "Find or Create PR" step 이 `GitHub Actions is not permitted to create or approve pull requests` 로 실패. PR 이 **사전에 존재해야** 동작. main-verify 브랜치에서 이 현상 확인. 이번 WO 범위는 아니라 기록만.
   - 해결하려면 repo Settings → Actions → Workflow permissions → "Allow GitHub Actions to create and approve pull requests" 활성화 필요.

5. **시뮬레이터 목록 변경 (Xcode 26.3)**
   - iPhone 15 없음. iPhone 16e / 17 / 17 Pro / 17 Pro Max / Air / iPad 시리즈만 존재. `iPhone 17` 로 맞추는 게 test-policy-ios.md 스펙과도 일치.

6. **Swift 6 Sendable 경고 다수**
   - `SearchHistoryClient.swift`, `ErrorLogClient.swift`, `DraftQueueClient.swift` 등에서 `concurrently-executed local function ... must be marked as '@Sendable'` 경고 다수 (에러 아님, 빌드 통과). Swift 6 언어 모드 전환 시 에러화될 것. 별도 WO 후보로만 기록.

7. **Node.js 20 deprecation 경고**
   - `actions/checkout@v4`, `actions/upload-artifact@v4`, `actions/github-script@v7` 모두 Node.js 20 사용 (2026-06-02 부터 기본 Node.js 24 강제). 별도 WO 후보.

## Gate 2 진입 체크리스트

- [x] `gh run list --repo Mino777/aidy-ios --branch main --limit 1` → **success** (24518674499)
- [x] xcresult artifact 정상 업로드 (534 KB, `TestResults-xcresult`)
- [x] xcodebuild.log 에 실제 테스트 카운트 포함 (`Test run with 124 tests in 10 suites passed` + `** TEST SUCCEEDED **`)
- [x] test-policy-ios.md 준수 (iPhone 17 destination, `-workspace Aidy.xcworkspace`, `tuist test` 대체로 xcodebuild test + 124 > 46 baseline)
- [x] 분 경제성: self-hosted 전환 + path filter (docs-only 변경 시 skip 설계)
- [x] 알림 폭탄 해소 (ai-review.yml self-hosted 전환으로 결제 차단 FAIL 사라짐)

## 후속 WO 후보 (범위 외)

- Swift 6 Sendable 경고 정리
- GitHub Actions Node.js 24 업그레이드 (checkout/upload-artifact/github-script)
- `test.yml` + `ai-review.yml` 역할 통합 또는 정리 (둘 다 tuist install/generate 수행 — 중복)
- `ai-review.yml` 의 PR 자동생성 권한 설정 (repo 설정에서 토글)

완료. Gate 2 진행 부탁드립니다.
