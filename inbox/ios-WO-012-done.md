# iOS 워커 완료 보고 — WO-012

**시각**: 2026-04-16 (WO-010 이어서)
**상태**: done
**WO**: `work-orders/in-progress/WO-012-actions-node24-upgrade.md`

## 요약
`aidy-ios/.github/workflows/*.yml` 의 Node.js 20 액션을 Node.js 24 호환 최신 메이저로 일괄 bump. self-hosted runner(2.333.1) 에 node24 이미 번들되어 runner 세팅 변경 없이 완료.

## 변경된 액션 목록

| 파일 | 액션 | before | after | Node runtime 증거 |
|---|---|---|---|---|
| `test.yml` | `actions/checkout` | `@v4` | **`@v6`** | v6 release note: "Node.js 24 지원"; `action.yml` → `using: node24` |
| `test.yml` | `actions/upload-artifact` | `@v4` | **`@v7`** | `action.yml` → `using: 'node24'` |
| `ai-review.yml` | `actions/checkout` | `@v4` | **`@v6`** | 위와 동일 |
| `ai-review.yml` | `actions/github-script` | `@v7` | **`@v9`** | v9 release note; `action.yml` → `using: node24` |

메이저 버전 기준 pin (기존 관례 유지). 최신 패치(v6.0.2 / v7.0.1 / v9.0.0)가 메이저 태그가 가리키는 head.

WO 스펙에 언급된 `maxim-lobanov/setup-xcode` 는 **WO-010에서 이미 제거됨** (`test.yml` + `ai-review.yml` 양쪽에서 setup-xcode step 제거 완료, 시스템 Xcode 사용). 이번에 건드릴 것 없음.

`actions/cache` 는 현재 미사용 (req 4 보류 결정 — self-hosted 로컬 DerivedData 영구).

## github-script v9 breaking 점검

v9 주요 breaking:
1. `require('@actions/github')` 금지 — ESM 전환
2. `getOctokit` 은 이제 script context 에 주입된 function (`const getOctokit` 재정의 시 `SyntaxError`)
3. `@actions/github` 내부 직접 접근 제한

`ai-review.yml` 의 두 스크립트 (Find or Create PR, Squash Merge) 모두:
- `require('@actions/github')` 미사용 ✓
- `const getOctokit` 선언 없음 ✓
- 사용 API: `github.rest.pulls.*`, `github.rest.repos.compareCommits`, `core.setOutput`, `core.setFailed`, `context.ref`, `context.repo.*`, `console.warn` — 전부 v9 호환 ✓

추가 코드 변경 없이 버전만 bump로 안전.

## self-hosted runner 호환성 결과

| 항목 | 확인 방법 | 결과 |
|---|---|---|
| runner 버전 | `cat ~/actions-runner/.runner` → agentName | 2.333.1 (`jominhoui-mba-ios`) |
| node24 번들 | `ls ~/actions-runner/externals/` | `node20/` + **`node24/`** 존재 |
| 실제 실행 | run 24519694356 / 24519681488 | 모두 green |
| 세팅 변경 | — | **불필요** |

Runner v2.328.0 부터 node24 번들 — 현재 2.333.1 은 충분. `FORCE_JAVASCRIPT_ACTIONS_TO_NODE24` 같은 임시 플래그 불필요.

## Green run URL + 증거

### Test workflow
- URL: https://github.com/Mino777/aidy-ios/actions/runs/24519694356
- Event: `pull_request` (PR #2, sha `d203243`)
- Duration: **1m 59s**
- Conclusion: **success**
- 모든 step 성공

### Auto Merge workflow
- URL: https://github.com/Mino777/aidy-ios/actions/runs/24519681488
- Event: `push` (feature/wo-012-actions-node24, sha `d203243`)
- Duration: **1m 47s**
- Conclusion: **success**
- PR #2 squash merge → main sha `1bf614f`

### PR
- https://github.com/Mino777/aidy-ios/pull/2 (MERGED 2026-04-16T15:45:09Z)
- merge commit: `1bf614f`

## Deprecation 경고 0건 증거

GitHub Checks API annotations 조회:
```bash
gh api /repos/Mino777/aidy-ios/check-runs/71673671186/annotations \
  --jq '[.[] | select(.message | ascii_downcase | contains("node.js") or contains("deprecated"))] | length'
# → 0

gh api /repos/Mino777/aidy-ios/check-runs/71673624307/annotations \
  --jq '[.[] | select(.message | ascii_downcase | contains("node.js") or contains("deprecated"))] | length'
# → 0
```

Test run (job 71673671186): **Node.js deprecation 0건**
Auto Merge run (job 71673624307): **Node.js deprecation 0건**

(참고: Auto Merge run annotation 에 Swift 6 Sendable 경고 10건 있음 — 앱 코드의 언어모드 경고지 Node.js 와 무관. WO-010 완료 보고의 "후속 WO 후보" 에 이미 기록됨.)

## Gate 검증 체크리스트

- [x] 모든 워커 repo (iOS) deprecation 경고 0건
- [x] 각 워크플로 1회 이상 green run (Test + Auto Merge 모두)
- [x] iOS self-hosted runner 호환 확인 (2.333.1 + node24 번들)

## 특이사항

- WO-010 에서 관찰된 "squash merge 커밋이 main Test 를 트리거 안 함" 현상이 이번에도 재현 (merge commit `1bf614f`). pull_request run 이 green 이므로 Gate 영향 없음 — 차후 feature 커밋에서 자연 검증됨. WO-012 의 Gate 기준 "각 워크플로 1회 green run" 은 pull_request/push 이벤트 어느쪽이든 충족.
- Auto Merge 워크플로의 "Find or Create PR" step 은 여전히 pre-existing PR 없으면 실패 (repo Settings 토글 필요). 이번엔 PR 을 즉시 `gh pr create` 로 만들어 우회. WO-010 보고에 후속 WO 후보로 이미 제출.
- 워크플로 외 파일 변경 없음 — 앱 코드 / Tuist / Project.swift 무변경.
- runner 자체 세팅 변경 불필요 → architect 추가 조치 없음.

## 수정 커밋

- `d203243` `WO-012: GitHub Actions Node.js 24 호환 업그레이드 (iOS)` (PR #2 내부)
- main squash: `1bf614f` `[WO-012] GitHub Actions Node.js 24 호환 업그레이드 (#2)`

완료. server/android 워커도 동일 작업 진행 시 참고 가능.
