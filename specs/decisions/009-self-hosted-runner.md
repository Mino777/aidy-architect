# ADR-009: iOS CI를 self-hosted runner로 전환

**Date**: 2026-04-17
**Status**: Accepted
**Sprint**: WO-010 (s7-prep)
**Related**: WO-010, gate-2-WO-010-ios.md, .github/workflows/{test,ai-review}.yml

## 배경

s6-R9 이후 iOS Test workflow가 **100% 실패 상태**. 진단 흐름:

1. **1차 진단** (Architect, ci-status.sh 첫 출력): `tuist 4.180.0` (macOS 15 SDK) ↔ runner `macos-14` (= 14.8.5) 미스매치 → `libswiftSynchronization.dylib` 누락 → exit 134. **분 한도 무관, 결제 정상 가정.** macos-14 → macos-15 전환으로 해결 예상.

2. **워커 PR #1 push** 직후 새 사실 발견:
   ```
   The job was not started because recent account payments have failed
   or your spending limit needs to be increased.
   ```
   GitHub-hosted runner 자체가 **결제 차단**으로 안 뜸. 분 카운트와 별개. Architect 진단 정정 필요.

3. **알림 폭탄 추가 발견** (사용자 보고): test.yml만 self-hosted로 옮기면 ai-review.yml(`runs-on: macos-latest`)이 매 비-main push마다 결제 차단으로 fail → 매번 알림.

## 결정

**iOS CI 전체를 self-hosted runner로 전환**. GitHub-hosted 의존을 끊는다.

- Runner: 사용자 Mac (jominhoui-MacBookAir, macOS 26.3.1, Xcode 26.3, tuist 4.180.0)
- 등록 이름: `jominhoui-mba-ios`
- Labels: `self-hosted, macOS, ARM64, aidy-ios`
- 실행: launchd user agent (`~/actions-runner/svc.sh install + start`)
- 적용 워크플로: `test.yml` + `ai-review.yml` 둘 다 동시 전환

대안 비교:

| 옵션 | 비용 | 의존성 | 폐기 사유 |
|---|---|---|---|
| GitHub billing 정상화 (카드 갱신) | 분당 가중치 10x (macOS) | 결제 정상 유지 의존 | 같은 사고 재발 가능 + 토큰 경제성 안 풀림 |
| Xcode Cloud (Apple) | 25h/월 무료 | Apple Developer 가입 + Tuist 호환성 검증 필요 | 도입 비용 큼, Tuist 호환성 불확실 |
| 워크플로 disable | 0 | — | CI 자체 포기 — 받아들일 수 없음 |
| **self-hosted (사용자 Mac)** | **0** (전기료만) | 사용자 Mac 가용성 | **선택**. 토큰 경제성 best, 머신은 항상 켜져 있음 |

## 의사결정 기록 (시간순 — 진단의 진화)

| 시각 | 사실 | 결정 |
|---|---|---|
| t0 | iOS CI 100% fail | 1차 진단: macos-14↔tuist 미스매치 |
| t1 | WO-010 발주 (req 1~3 = macos-15 + 트리거 + path filter) | 워커 dispatch |
| t2 | 워커 PR push → "payments have failed" | **진단 정정**: 결제 차단 별개 사유 |
| t3 | self-hosted runner 등록 (Architect 직접) | runner online, ios-response.md |
| t4 | 워커가 test.yml self-hosted 적용 → main green | test 게이트 OK |
| t5 | 알림 폭탄 지속 — ai-review.yml 미전환 | ios-response-2.md |
| t6 | 워커가 ai-review.yml 전환 → 알림 멈춤 | Gate 2 PASS |

## 영향

### 긍정
- **macOS 분 가중치 0**: 4월 누적 ~180min → 0min
- **결제 차단 영원히 무관**: 카드 사고/한도/spending limit 변경에 비의존
- **로컬 캐시 영구**: DerivedData 재사용으로 build 1m 56s (캐시 무효화 1m+ 절감)
- **분 한도 걱정 없이 path filter/트리거 정책을 더 보수적으로** (의도적 trigger 줄이기 인센티브 약화 가능 — 주의)

### 부정 / 위험
- **단일 머신 의존**: 사용자 Mac이 꺼지면 CI 중단 → svc 자동 부팅으로 완화. 정기 점검 필요.
- **사용자 Mac 동시 작업 부하**: 빌드 중 본인 작업 영향 가능. 영향 작음(1m 56s).
- **launchd user agent 보안**: root 아님 + 사용자 본인 repo + token은 short-lived registration token만 사용. 추가 점검: `~/actions-runner/.runner` 의 토큰 권한 600 유지.
- **Repo 추가 시 runner 재등록**: 현재 aidy-ios repo 단일 등록. server/android는 미적용 (필요 시 별도 등록).

## 운영 가이드

### Runner 상태 확인
```bash
gh api /repos/Mino777/aidy-ios/actions/runners --jq '.runners[] | {name,status,busy}'
```

### Runner 재시작
```bash
~/actions-runner/svc.sh status
~/actions-runner/svc.sh start
tail -f ~/Library/Logs/actions.runner.Mino777-aidy-ios.jominhoui-mba-ios/Runner_*.log
```

### Runner 등록 토큰 재발급
```bash
gh api -X POST /repos/Mino777/aidy-ios/actions/runners/registration-token --jq '.token'
```

### Runner 제거
```bash
~/actions-runner/svc.sh stop
~/actions-runner/svc.sh uninstall
~/actions-runner/config.sh remove --token <removal-token>
```

## 후속 검토 항목

- aidy-server / aidy-android 도 같은 패턴(self-hosted) 적용 여부 — Linux runner는 분 가중치 1x라 GitHub-hosted 그대로 두는 게 합리적일 수도. 결제 차단 영향 받는지 별도 확인 필요.
- self-hosted runner 무중단 — Mac 재시작 후 launchd 자동 부팅 검증
- 보조 runner (PR 폭증 시 큐) — 아직 단일이라 직렬 처리, 큐 대기 발생 가능
- `test.yml` + `ai-review.yml` 역할 통합 (둘 다 tuist install/generate 중복 — 별도 WO)

## 박제 교훈

1. **"한도 초과 아님" ≠ "결제 정상"**. 분 카운트와 결제 상태는 별개. 진단 시 둘 다 확인.
2. **PR 1개 = 워크플로 1개 가정 금지**. 같은 push 트리거에 다른 워크플로(특히 자동 머지 봇)가 묶여 있을 수 있음. ci-status.sh `--watch` 가 모든 워크플로 fail을 잡았기에 발견 가능.
3. **인프라 변경 후 알림 폭탄은 진단 신호**. 무시하면 같은 사고 반복.
4. **self-hosted는 토큰 경제성 + billing 안전 동시 해결**. macOS CI에서 특히 효과 큼 (분 가중치 10x).
