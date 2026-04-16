# WO-010: iOS CI macos-15 마이그레이션 + 분 경제성

**담당**: ios
**우선순위**: P0-긴급 (현재 main CI 빨간불 — Gate 2 차단 상태)
**상태**: done → in-progress → gate-1 → gate-2 → done
**의존**: 없음

## 목표
iOS CI를 복구하고(현재 100% 실패) GitHub Actions macOS 분 사용량을 크게 줄인다.

## 진단 (Architect 사전 조사 — 2026-04-16)

`gh run view 24513934097 --repo Mino777/aidy-ios --log-failed` 결과:

```
Library not loaded: /usr/lib/swift/libswiftSynchronization.dylib
  Referenced from: /opt/homebrew/Caskroom/tuist/4.180.0/tuist
  (built for macOS 15.0 which is newer than running OS)
exit code 134 (SIGABRT)
```

- 현재 runner: `macos-14` (= 14.8.5)
- `brew install tuist` → tuist 4.180.0 (macOS 15 SDK 빌드)
- `libswiftSynchronization.dylib` 는 macOS 15부터 추가됨
- → tuist version 호출 즉시 abort, xcodebuild는 시작도 못 함

**원인**: tuist가 macOS 15 강제. macOS 14 runner에서 영원히 못 돈다.
**한도 초과 아님**: 4월 누적 6 runs (server/ios/android × 2). 분 한도와 무관.

### 추가 발견 (워커 PR 후 — 2026-04-16, 진단 정정)
요구사항 1~3 적용 PR #1 push 시 GitHub-hosted runner 자체가 차단됨:
```
The job was not started because recent account payments have failed
or your spending limit needs to be increased.
```
→ 분 카운트와 별개 사유로 결제 실패 차단. **self-hosted runner 전환으로 GitHub-hosted 의존 자체 제거** 결정.

### 진단 결론 (정정 후)
- 분 한도: ✅ 여유
- 결제: ❌ 차단 (별개 사유) → 우회
- workflow YAML 수정 (req 1~3): ✅ PR #1로 적용 완료, 머지 가능
- 다음 행동: **req 5 (self-hosted 전환) 추가 적용** → 머지

## 구현 요구사항

수정 대상: `aidy-ios/.github/workflows/test.yml`

1. **`runs-on: macos-14` → `runs-on: macos-15`** (1줄)
   - 또는 `macos-latest` (현재 시점에서는 동일하게 macos-15로 매핑됨)
   - 14에 머무를 정당한 이유 없음. 핵심 fix.

2. **트리거 축소 — push + pull_request → pull_request + main push만**
   ```yaml
   on:
     push:
       branches: [main]
     pull_request:
   ```
   - 현재: 모든 브랜치 push 마다 실행
   - 변경 후: feature 브랜치 push는 PR 시점에만 실행 → 분 절반 이상 절감

3. **path filter 추가 — iOS 무관 변경에 CI 안 돌게**
   ```yaml
   on:
     push:
       branches: [main]
       paths:
         - 'Sources/**'
         - 'Tests/**'
         - 'Tuist/**'
         - 'Project.swift'
         - 'Package.swift'
         - '.github/workflows/test.yml'
     pull_request:
       paths:
         - 'Sources/**'
         - 'Tests/**'
         - 'Tuist/**'
         - 'Project.swift'
         - 'Package.swift'
         - '.github/workflows/test.yml'
   ```
   - README/docs/CHANGELOG 변경 시 macOS runner 안 띄움
   - 실제 경로는 본인 repo 구조에 맞게 조정

4. **(선택, 시간 남으면) SPM/Tuist 캐싱**
   - `actions/cache@v4` 로 `~/Library/Developer/Xcode/DerivedData`, `Tuist/Dependencies` 캐싱
   - 매 run 1~3분 절감 (macOS는 분당 가중치 10x — 효과 큼)
   - **self-hosted 전환 시 불필요**: 로컬 디스크에 캐시 영구 보존됨

5. **🆕 self-hosted runner 전환 (req 4를 대체)** — Architect가 사용자 Mac에 runner 등록 완료
   - Runner: `jominhoui-mba-ios` / labels: `self-hosted, macOS, ARM64, aidy-ios` / status: online
   - workflow `runs-on: macos-15` → `runs-on: [self-hosted, macOS, ARM64, aidy-ios]`
   - 사용자 Mac 환경: macOS 26.3.1, Xcode 26.3, tuist 4.180.0 (이미 설치)
   - **단순화 가능 step**:
     - `Select Xcode (latest stable)` (`maxim-lobanov/setup-xcode@v1`) — 시스템 Xcode 26.3 사용 OK. step 제거 또는 유지(idempotent라 큰 비용 없음, 다만 setup-xcode가 macos-26에서 동작할지는 확인 필요)
     - `Install Tuist` (`brew install --quiet tuist`) — 이미 설치됨, 멱등이라 두면 빠름. 또는 `command -v tuist || brew install tuist` 가드
   - **주의**: self-hosted라 `runs-on:` 배열만 바꾸면 끝. brew/Xcode step은 보수적으로 유지.

## 테스트 요구사항

- [ ] 수정 후 push → 새 run 트리거됨 + green 확인
- [ ] 로컬에서 `tuist install && tuist generate --no-open && xcodebuild test ...` 통과 (이미 잘 됨)
- [ ] CI run의 `Run xcodebuild test` step에서 "Test Suite ... passed" 출력 확인

## 검증 기준 (Gate 통과 조건)

- [ ] `gh run list --repo Mino777/aidy-ios --branch main --limit 1` 가 success
- [ ] xcresult artifact 정상 업로드
- [ ] xcodebuild.log 에 실제 테스트 카운트 ("N tests passed") 포함
- [ ] **테스트 정책 (`gates/test-policy-ios.md`)** 준수
- [ ] 분 경제성: 동일 PR에서 docs-only 변경 시 workflow skip 확인

## 완료 보고

- 수정 커밋 SHA + 메시지
- 새 run URL + duration
- 4월 시점 macOS 분 사용량 변화 추정 (이전 vs 변경 후)
- 적용한 path filter 경로 목록
- 캐싱 적용 여부 + 절감 분
- 특이사항/추가 발견

## 참고 — 후속 옵션 (이번 WO 범위 외)

- self-hosted runner (사용자 본인 Mac) — 무료, 무한 분
- Xcode Cloud (Apple Developer 가입자 25h/월 무료)
- 분 사용량 원본 확인: `gh auth refresh -h github.com -s user && gh api /users/Mino777/settings/billing/actions`
