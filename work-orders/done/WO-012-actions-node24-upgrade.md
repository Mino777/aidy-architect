# WO-012: GitHub Actions Node.js 24 업그레이드 (3 워커 공통)

**담당**: ios + server + android (각 워커가 자기 repo workflow 수정)
**우선순위**: P1-높음 (2026-06-02 강제 마이그레이션)
**상태**: done (iOS done + merged, server/android blocked by billing)
**의존**: WO-014 (server self-hosted) + WO-015 (android self-hosted) 완료 후 Gate 2 재개
**블로커**: GitHub Actions 결제 차단으로 server/android green run 확보 불가. 빌링 복구 불가 상황 → self-hosted 통합 경로로 우회 결정 (2026-04-17, ADR-010)

## 목표
2026-06-02 부로 GitHub Actions가 Node.js 24를 기본값으로 강제하기 전에 모든 워크플로 액션을 Node.js 24 호환 버전으로 업그레이드.

## 발견 경로
WO-010 워커 보고(2026-04-17), 실제 run 경고:
> Node.js 20 actions are deprecated. The following actions are running on Node.js 20 and may not work as expected: `actions/checkout@v4`, `actions/upload-artifact@v4`. Actions will be forced to run with Node.js 24 by default starting June 2nd, 2026.

## 영향 범위
- `aidy-ios/.github/workflows/test.yml` + `ai-review.yml`
- `aidy-server/.github/workflows/test.yml` + `ai-review.yml` (있으면)
- `aidy-android/.github/workflows/test.yml` + `ai-review.yml` (있으면)
- 사용 중인 액션: `actions/checkout`, `actions/upload-artifact`, `actions/github-script`, `actions/cache`, `maxim-lobanov/setup-xcode` 등

## 구현 요구사항
1. **각 워커**: 자기 repo의 모든 `.github/workflows/*.yml` 에서 액션 버전 점검
2. Node.js 24 호환 최신 메이저 버전으로 업그레이드 (예: `actions/checkout@v5` 가 나오면 그쪽으로)
3. 임시 우회 옵션 (단기): `FORCE_JAVASCRIPT_ACTIONS_TO_NODE24=true` env 또는 `ACTIONS_ALLOW_USE_UNSECURE_NODE_VERSION=true` (비권장)
4. 업그레이드 후 워크플로 1회 dry-run 으로 동작 확인

## 검증 기준
- [ ] 모든 워커 repo에서 deprecation 경고 0건
- [ ] 각 워크플로 1회 이상 green run
- [ ] iOS는 self-hosted runner 환경에서도 호환 (Node.js 24 액션이 self-hosted 호환 확인)

## 비고
- 단순 버전 bump가 대부분이지만, 메이저 변경 시 input/output 스키마 변동 가능 — 액션별 release note 확인 필수
- 3 워커 동시 진행 가능 (cross-dependency 없음). `architect-cli.sh send-seq` 활용 가능
