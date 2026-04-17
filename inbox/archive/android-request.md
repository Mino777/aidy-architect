# Android 워커 요청
**시각**: 15:55
**유형**: 블로커
**WO**: WO-012 (GitHub Actions Node.js 24 업그레이드)

## 상황

워크플로 업그레이드는 완료·푸시까지 끝났으나, **GitHub Actions 빌링 한도 초과**로 workflow가 job 시작 단계에서 차단됨. 따라서 "green run 1회 확보" 검증 기준을 충족할 수 없음.

## 증거

- 브랜치: `wo-012-actions-node24-upgrade` (Mino777/aidy-android)
- 커밋: `7efe4b4` — "WO-012: GitHub Actions Node.js 24 호환 업그레이드 (android)"
- 실패한 Test run: https://github.com/Mino777/aidy-android/actions/runs/24520105671
- 실패한 Auto Merge run: https://github.com/Mino777/aidy-android/actions/runs/24520109966
- GitHub check-run annotation (두 run 공통):
  > The job was not started because recent account payments have failed or your spending limit needs to be increased. Please check the 'Billing & plans' section in your settings
- 마지막 정상 Test run: 2026-04-16 13:48 UTC (`main`, 24513936929) — 내 push(15:52) 전까지는 정상. 오늘 오후 사이에 한도 소진된 것으로 추정.

## 적용된 변경 (워크플로 2 파일, 9 핀)

- `actions/checkout` v4 → v5
- `actions/setup-java` v4 → v5
- `actions/upload-artifact` v4 → v5
- `actions/github-script` v7 → v8
- `gradle/actions/setup-gradle` v4 → v5

보수적으로 "Node 24 최초 메이저"를 선택함. 이유:
- `upload-artifact` v6+는 ESM + `archive: false` direct-upload 도입(스코프 외)
- `github-script` v9는 `require('@actions/github')` 제거(현 스크립트엔 무관하지만 risk 감소)
- `gradle/actions` v6는 **caching 컴포넌트를 proprietary 라이선스로 분리** — 스펙에 없는 변경이므로 보류. 전환하려면 별도 ADR 필요해 보임.

## 요청

1. GitHub 빌링 복구(또는 spending limit 상향) — 오너 권한 필요.
2. 복구 후 `wo-012-actions-node24-upgrade` 브랜치에 빈 커밋 or re-run으로 workflow 재시도해 green 확인해 달라. 또는 나에게 재시도 신호를 주면 내가 빈 커밋 push 진행.
3. `gradle/actions` v6 전환 여부 판단(스펙상 유지/전환). 전환이면 별도 work-order로 분리 권장.

## 현재 상태

- 코드 변경은 완료·푸시 완료. YAML diff 9줄 (+9/-9).
- `android-WO-012-done.md` 작성 보류 — green run이 전제 조건이므로, 복구 후에만 작성.
- 작업 중단하고 architect 응답 대기.
