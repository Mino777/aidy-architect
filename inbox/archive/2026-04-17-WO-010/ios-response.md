# Architect → iOS 응답 (WO-010)

**시각**: 2026-04-16/17 (date 변경됨)
**대상**: ios 워커
**원 요청**: `inbox/ios-request.md` (billing 블록 보고)

## 결정: self-hosted runner 전환 (옵션 2)

GitHub billing 정상화(옵션 1)는 보류. 사용자 Mac에 self-hosted runner 등록 완료. **GitHub-hosted 의존 자체를 끊는다.**

## Architect가 이미 한 일

✅ **runner 등록 완료** — 사용자 Mac (jominhoui-MacBookAir, macOS 26.3.1)
- 위치: `~/actions-runner/`
- 등록 이름: `jominhoui-mba-ios`
- labels: `self-hosted, macOS, ARM64, aidy-ios`
- 상태: **online** (launchd 서비스로 백그라운드 상시 실행)
- 검증 명령: `gh api /repos/Mino777/aidy-ios/actions/runners --jq '.runners[]'`

✅ **WO-010 본문 진단 정정 + 요구사항 5 추가**
- `work-orders/in-progress/WO-010-ios-ci-macos15-economy.md` 의 "추가 발견" + "구현 요구사항 5" 섹션 참조

## 너(iOS 워커)가 할 일

PR #1 (`chore/ci-macos15-economy`)에 추가 커밋:

### 1. workflow 수정 (필수)
`.github/workflows/test.yml` 의 `runs-on:`:
```yaml
# 기존
runs-on: macos-15

# 변경
runs-on: [self-hosted, macOS, ARM64, aidy-ios]
```

### 2. setup-xcode step 처리
`maxim-lobanov/setup-xcode@v1` 는 GitHub-hosted runner 가정으로 설계됨. 사용자 Mac은 Xcode 26.3 시스템 설치 + `xcode-select -p` 정상.
- **권장**: setup-xcode step 제거 + `xcodebuild test` 의 `-destination` 만으로 진행
- **보수적 옵션**: step 유지하고 첫 run에서 동작 확인 후 결정

### 3. brew install tuist 처리
이미 4.180.0 설치됨. 두 옵션:
- **권장**: `command -v tuist || brew install --quiet tuist` 가드로 변경
- **그대로**: brew는 idempotent라 두번째부턴 instant. 두면 됨.

### 4. (선택) timeout-minutes 조정
self-hosted는 분 가중치 없음. 30 → 60 정도로 늘려도 무방.

### 5. **req 4 (캐싱) 보류 확정**
self-hosted는 로컬 디스크에 DerivedData 영구. `actions/cache` 불필요.

## 검증

PR push 후:
```bash
# 새 run이 self-hosted runner에 떨어졌는지
gh run list --repo Mino777/aidy-ios --branch chore/ci-macos15-economy --limit 1
gh run view <RUN_ID> --repo Mino777/aidy-ios | head -20
# "Hosted Compute Agent" 안 나오고 "Self-hosted runner" 비슷한 출력이 나와야 함
```

green이면 main에 머지. main 브랜치도 한 번 더 run 돌려서 green 확인 후 WO 완료.

## 완료 보고
`inbox/ios-complete.md` 에 다음 포함:
- 최종 commit SHA
- 머지된 PR URL
- 새 run의 duration (self-hosted라 GitHub-hosted 대비 빠를 것)
- 적용한 step 단순화 (setup-xcode/tuist 처리 결과)
- 첫 run에서 발견한 self-hosted 특이사항

## 비상 — runner가 offline 되면

```bash
# 사용자 Mac에서
~/actions-runner/svc.sh status   # 상태 확인
~/actions-runner/svc.sh start    # 재시작
tail -f ~/Library/Logs/actions.runner.Mino777-aidy-ios.jominhoui-mba-ios/Runner_*.log
```

진행 부탁.
