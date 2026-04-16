# Architect → iOS 추가 응답 (WO-010)

**시각**: 2026-04-17
**대상**: ios 워커
**원인**: GitHub run failed 알림 폭탄

## 진단

`test.yml` self-hosted 전환은 ✅ 정확히 됨.

문제: **`.github/workflows/ai-review.yml` (Auto Merge to main)** 워크플로가 여전히 `runs-on: macos-latest` 라서, 모든 비-main push마다 GitHub-hosted runner 호출 → 결제 차단 → 매번 fail.

이 워크플로는 사실상 두 번째 CI 게이트(rebase + tuist build + squash merge)라 그냥 disable 하면 안 됨. **self-hosted로 전환**해야 함.

## 너가 할 일 (PR #1에 추가 커밋)

### `.github/workflows/ai-review.yml` 수정:

1. **runs-on 변경**:
   ```yaml
   # 기존
   runs-on: macos-latest
   # 변경
   runs-on: [self-hosted, macOS, ARM64, aidy-ios]
   ```

2. **Setup Xcode step 제거** (test.yml 처리 방식과 동일):
   ```yaml
   # 제거할 step
   - name: Setup Xcode
     uses: maxim-lobanov/setup-xcode@v1
     with:
       xcode-version: latest-stable
   ```
   - 사용자 Mac은 시스템 Xcode 26.3 (`xcode-select -p`) 정상.

3. **Install Tuist 가드** (멱등 + 빠르게):
   ```yaml
   - name: Install Tuist
     if: steps.sync.outputs.status != 'conflict'
     run: command -v tuist || brew install --quiet tuist
   ```

### 검증 + 머지

PR #1에 push 후:
- 새 Test run + Auto Merge run 둘 다 self-hosted runner에 떨어지는지
- 둘 다 green이면 main에 머지

`gh run list --repo Mino777/aidy-ios --limit 5` 로 결과 한 번에 확인.

## 후속 (이번 WO 끝나고)

Test와 Auto Merge가 거의 같은 일(tuist install/generate/build|test) 함 → 워크플로 통합 또는 역할 분리는 별도 WO 후보. 지금은 **알림 폭탄 멈추기 + 둘 다 green** 만 목표.

## 보너스 — runner 모니터링

`gh api /repos/Mino777/aidy-ios/actions/runners` 로 runner status 확인 가능. busy=true면 작업 중. offline 이면 사용자 Mac에서 `~/actions-runner/svc.sh start` 재시작.
