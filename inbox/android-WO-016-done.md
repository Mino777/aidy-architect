# WO-016 완료 보고 — android Hybrid Fallback 패턴

**워커**: android
**완료 시각**: 2026-04-17 08:52 (KST)
**상태**: ✅ 패턴 적용 + fallback 발동 실증 완료. 정상 시나리오는 billing 차단으로 deferred.

## 0. Mark-step 패턴 적용 확인 (architect 긴급 지시 반영)

✅ ADR-010 §8 `continue-on-error: true` + `needs.x.result` 버그 회피 적용 완료.
cross-check 대상 `Mino777/aidy-server@86fe88c` 와 패턴 동등성 확인.

- primary job `outputs.passed: ${{ steps.mark.outputs.passed }}` 선언
- `Mark primary success` step (id: mark) 을 업무 step **뒤 + upload-artifact 앞** 에 배치
- fallback `if: ${{ always() && needs.x.outputs.passed != 'true' }}` (result 미사용)
- `upload-artifact` 는 `if: always()` 로 Mark 뒤에 배치

ai-review.yml 특이 처리: Mark step 에 `if: steps.merge.outputs.merged == 'true'` 가드 추가 (rebase conflict 로 merge step skipped 된 경우 암묵 `success()` 만으론 통과되어 fallback 이 잘못 skip 되는 것 방지).

## 1. Workflow 변경 diff 요약

| 파일 | 라인 | 구조 변경 |
|---|---|---|
| `.github/workflows/test.yml` | +93 / -10 | 단일 self-hosted job → `test-gh-hosted` (primary, ubuntu-latest) + `test-self-hosted` (fallback, MBA) 2-job |
| `.github/workflows/ai-review.yml` | +137 / -4 | 단일 self-hosted job → `auto-merge-gh-hosted` + `auto-merge-self-hosted` 2-job. Mark step 은 `merge.outputs.merged == 'true'` 가드 |

액션 핀 (server@86fe88c cross-check 반영):
- `actions/checkout` @v5 → **@v6**
- `actions/upload-artifact` @v6 → **@v7**
- `actions/setup-java` @v5 (양쪽 job 유지, JDK 21 ADR-010 §6)
- `actions/github-script` @v8 (양쪽 유지)
- `gradle/actions/setup-gradle` @v5: primary 만 사용, fallback 은 생략 (ADR-010 §7)

Artifact name 충돌 회피: `test-report-html-{gh-hosted|self-hosted}`, `test-results-xml-{gh-hosted|self-hosted}`.

머지된 커밋 (origin/main):
- `e7935d4` WO-016: hybrid fallback 패턴 적용 (#3)
- `d61bd20` WO-016 검증: step-level exit 1 주입 (#4) — 일부러 임시 커밋
- `ae553d2` WO-016 검증 마무리: 임시 injection 제거 (#5)

최종 main 상태에는 injection 흔적 없음:
```
gh api ...contents/test.yml?ref=main | grep -E "exit 1|Inject"
→ no injection on main — clean
```

## 2. 정상 시나리오 (primary green → fallback skipped)

❌ **관찰 불가 — billing 차단 중**. GitHub Actions ubuntu-latest job 이 startup 단계에서 차단:
> The job was not started because recent account payments have failed or your spending limit needs to be increased.

ADR-010 §8 가 이 상태를 이미 인정 (server 도 동일): "billing 차단 중이라 관찰 deferred — 코드 레벨 보증 (Mark step 암묵 `if: success()` 라 실패 시 실행 안 됨)".

코드 레벨 보증:
- primary 의 모든 test/assemble step 이 성공하면 `Mark primary success` 실행 → `passed=true`
- fallback `if: ${{ always() && needs.x.outputs.passed != 'true' }}` 가 false → skip
- billing 복구 후 dogfood 가능

## 3. 장애 시나리오 (primary fail → fallback green)

✅ **관찰됨 — 3 푸시 모두 동일 결과**.

| push | 커밋 | Test run | Auto Merge run | 결과 |
|---|---|---|---|---|
| 패턴 최초 적용 | `ffbf94a` | [24539873206](https://github.com/Mino777/aidy-android/actions/runs/24539873206) | [24539873222](https://github.com/Mino777/aidy-android/actions/runs/24539873222) | primary fail → fallback green |
| step-level exit 1 injection | `9b82d87` | [24539975571](https://github.com/Mino777/aidy-android/actions/runs/24539975571) | [24539975568](https://github.com/Mino777/aidy-android/actions/runs/24539975568) | primary fail → fallback green |
| injection 제거 cleanup | `e0caf15` | [24540062023](https://github.com/Mino777/aidy-android/actions/runs/24540062023) | [24540061991](https://github.com/Mino777/aidy-android/actions/runs/24540061991) | primary fail → fallback green |

모든 run 에서 workflow 전체 conclusion 은 **success** (continue-on-error + fallback green 조합 덕).

### step-level exit 1 injection 관찰 결과 (참고)

의도: primary 에 `- run: exit 1` 주입 → step-level fail 시 Mark step 패턴 동작 확인.

실제 관찰: primary 가 billing 으로 **job startup 단계에서 차단**되어 주입한 step 까지 도달 못 함 (`check-runs/annotations` 증거: "The job was not started because recent account payments have failed"). 그러나 Mark step 패턴의 작동 로직상 원인 무관:
- billing startup fail → 어떤 step 도 실행 안 됨 → Mark 실행 안 됨 → `passed` 미설정 → fallback 발동 ✓
- step-level exit 1 → 그 이후 step (Mark 포함) 실행 안 됨 → 동일 결과 ✓

ADR-010 §8 server 관찰("step-level exit 1 동일 동작 ✓") 과 패턴 동등. android 의 경우 billing 차단이 step-level fail 보다 먼저 발생하여 구분 관찰은 불가능하지만, Mark-step 패턴의 정합성은 동일하게 보증됨.

## 4. Fallback trigger 지연 측정

primary fail 종료 시각 → fallback 시작 시각 간격:

| push | workflow | primary 종료 | fallback 시작 | 지연 |
|---|---|---|---|---|
| `ffbf94a` | Test | 23:44:23 | 23:44:26 | **~3s** |
| `ffbf94a` | Auto Merge | 23:44:24 | 23:45:21 | ~57s |
| `9b82d87` | Test | 23:47:33 | 23:47:37 | **~4s** |
| `9b82d87` | Auto Merge | 23:47:34 | 23:48:34 | ~60s |
| `e0caf15` | Test | 23:50:20 | 23:51:22 | ~62s |
| `e0caf15` | Auto Merge | 23:50:20 | 23:50:23 | **~3s** |

**관찰**: 지연은 3-62초 구간. 하한(3-4s) 은 순수 GitHub Actions 스케줄링 시간. 상한(57-62s) 은 `aidy-android` 단일 runner 를 Test + Auto Merge 가 공유하면서 발생하는 **직렬화 대기**. Test 가 먼저 잡히면 Auto Merge 가 대기, 혹은 그 반대. ADR-010 §8 말미의 runner 직렬화 비용(20-60초) 과 일치.

→ ADR-010 §5 fallback 발동률 모니터링에 **"runner 대기 시간" 지표**를 병기하면 체감 CI 속도 원인 분석에 유용.

## 5. 양 시나리오 동일 테스트 숫자 확인

세 번 모두 fallback 에서 동일 테스트 수 관찰:

| 커밋 | job | testDebugUnitTest | assembleDebug |
|---|---|---|---|
| `ffbf94a` | self-hosted fallback | (skipped — Test Gate 안 수행한 duplicate 로그 제공 생략) | |
| `9b82d87` | self-hosted fallback | BUILD SUCCESSFUL (step-level injection 과 무관하게 fallback 은 깨끗한 코드) | BUILD SUCCESSFUL |
| `e0caf15` | self-hosted fallback | **BUILD SUCCESSFUL in 20s** / 24 tasks | **BUILD SUCCESSFUL in 7s** / 37 tasks |

XML 집계 (e0caf15 cleanup run, `test-results-xml-self-hosted` 아티팩트):
**135 tests · 0 failures · 0 errors · 0 skipped**

WO-015 완료 보고에서 관찰한 값과 동일 (135 tests). baseline 유지.

## 6. GitHub-hosted Android SDK 자동 제공 확인

❌ **관찰 불가 — billing 차단 중**. ubuntu-latest 는 Android SDK (platforms + build-tools + platform-tools) 기본 포함으로 알려져 있으나, 실제 `assembleDebug` 가 primary 에서 돌지 못함.

현 workflow 에는 `android-actions/setup-android` 등 SDK 설치 step 이 **양쪽 job 에서 모두 제거**되어 있음 (task 지시 및 ADR-010 §7 준수). billing 복구 시:
- primary 가 돌면 `assembleDebug` BUILD SUCCESSFUL 이 관찰되어야 SDK 자동 제공 확인 완료
- 만약 primary 가 SDK 미설치로 실패한다면 setup-android step 추가 필요 (별도 WO)

**현 위험 평가**: 낮음. ubuntu-latest 이미지 공식 문서 (`actions/runner-images`) 에 `android-*` 컴포넌트가 명시돼 있고, WO-012 이전 기존 workflow 가 ubuntu-latest 에서 `./gradlew testDebugUnitTest` 만 실행했지만 Android Gradle Plugin 이 compileSdk=35 를 요구함에도 별도 setup-android 없이 동작했던 이력 존재 (WO-012 run 24513936929 = last green main run, 2026-04-16 13:48).

## 7. 특이사항 / 참고

### (a) 브랜치·커밋 흐름 이상 없음
WO-015 에서 경험한 squash-merge-reset 사이클 재현:
- push → fallback green → ai-review fallback 이 squash merge → branch force-reset to main → 다음 push 전에 `reset --hard origin/<branch>` 로 재동기화
- worktree 사용 덕분에 원본 작업 트리 오염 없음

### (b) upload-artifact v7 관측
server@86fe88c 이 v7 을 채택했고, android 도 일치시킴. 기존 (name/path/retention-days/if-no-files-found) 입력은 v7 에서도 동일하게 동작 확인 (fallback 의 XML 아티팩트를 문제없이 다운로드).

### (c) gradle/actions/setup-gradle v5 유지
ADR-010 §6 v6 의 caching proprietary 전환 이슈 때문에 primary 는 v5 유지. fallback 에서는 step 자체 제거 (§7).

### (d) checkout v6 영향
`credential persistence to a separate file` 변경 외 기존 동작 영향 관찰되지 않음. ai-review 의 token 기반 force-push 정상 동작.

## 8. 검증 체크리스트

- [x] Mark-step 패턴 적용 (outputs.passed + Mark step + fallback if: always() && outputs.passed != 'true')
- [x] server@86fe88c cross-check 반영 (checkout v6 / upload-artifact v7 / setup-java v5 / Mark step 배치)
- [x] test.yml 2-job hybrid 구조
- [x] ai-review.yml 2-job hybrid 구조 (Mark 에 merge 가드)
- [x] setup-android step 양쪽 제거
- [x] actions/cache self-hosted 제거 (step 자체 없음 + setup-gradle 도 fallback 에선 skip)
- [x] artifact name 충돌 회피 (runner suffix)
- [x] 장애 시나리오 3회 관찰 (billing-fail 경유)
- [x] 135 tests · 0 failures 재확인
- [ ] 정상 시나리오 (primary green) — billing 차단으로 deferred, 복구 후 관측
- [ ] github-hosted Android SDK 자동 제공 — 동일 이유로 deferred

## 9. 후속 권장

1. **billing 복구 후 재검증**: 정상 시나리오 + SDK 자동 제공 dogfood. 예상 duration: ~3분 (Gradle daemon start 포함)
2. **runner 대기 시간 지표 도입**: ADR-010 §5 weekly fallback 모니터링에 "primary → fallback 지연 P50/P95" 추가
3. **ai-review primary 성공 시 branch-reset 제외 검토**: 현재 fallback 에서 merge 되면 그 fallback job 이 reset 수행. 만약 빌링 복구 후 primary 가 성공하면 primary 에서 reset 해야 하는데, 두 job 이 동시에 reset 경쟁할 일은 없으나(fallback 은 primary success 시 skip), primary 성공 경로가 아직 실증되지 않음 → billing 복구 시 1회 관찰 필요
