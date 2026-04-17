# WO-016: GitHub-hosted primary + Self-hosted fallback workflow 패턴

**담당**: server + android (iOS는 제외 — self-hosted only 유지)
**우선순위**: P1-높음 (빌링 정상화 시 cost 최적화)
**상태**: done
**의존**: WO-014 (server runner online) + WO-015 (android runner online)
**Related**: ADR-010 (초안), WO-012

## 목표

server/android workflow에 "GitHub-hosted primary → 실패 시 self-hosted fallback" 로직을 주입. 빌링 정상일 땐 무료 쿼터 소비, 빌링 차단 시 자동으로 self-hosted 백업.

iOS 는 macOS runner 분당 계수 10배 때문에 제외 — `self-hosted only` 유지.

## 배경

- 사용자 의도: "깃헙 먼저 찌르고 실패하면 self-hosted 로 대체"
- 기술 검토 결과 **Job-level if 패턴 (A 패턴)** 채택 (상세 비교 ADR-010 참조):
  - 단순, YAML 한 파일
  - billing fail + job cancel + 테스트 fail 모두 커버
  - 단점: 진짜 테스트 실패 시에도 fallback 재시도 (시간 2배) — 허용
- 정교한 billing-only detect (B 패턴) 는 YAML 3 job 복잡도 증가 → 보류

## 적용 범위

- ✅ `aidy-server/.github/workflows/test.yml`
- ✅ `aidy-server/.github/workflows/ai-review.yml` (있으면)
- ✅ `aidy-android/.github/workflows/test.yml`
- ✅ `aidy-android/.github/workflows/ai-review.yml` (있으면)
- ❌ `aidy-ios/*` — ADR-009/010 에 따라 self-hosted only

## 구현 요구사항

### 1. 공통 패턴 (A) — Mark-step 우회 필수

🚨 **중요 버그** (WO-016 server 실증): `continue-on-error: true` + `needs.x.result != 'success'` 조합은 **작동 안 함**. `continue-on-error` 가 job result 를 `success` 로 마스킹해서 fallback 이 영원히 skip 됨. 반드시 아래 **Mark-step 우회 패턴** 사용. 근거: ADR-010 §8.

```yaml
jobs:
  test-gh-hosted:
    runs-on: ubuntu-latest
    continue-on-error: true
    outputs:
      passed: ${{ steps.mark.outputs.passed }}   # ★ fallback 트리거 신호
    steps:
      - uses: actions/checkout@v5
      - uses: actions/setup-java@v5
        with: { distribution: 'temurin', java-version: '21' }
      - uses: gradle/actions/setup-gradle@v5
      # ✅ actions/cache OK (github-hosted ephemeral)
      - name: Run tests
        run: ./gradlew test   # android: testDebugUnitTest + assembleDebug
      - name: Mark primary success            # ★ 핵심 — 암묵 `if: success()` 로 이전 step fail 시 skip
        id: mark
        run: echo "passed=true" >> $GITHUB_OUTPUT
      - name: Upload artifacts                # `if: always()` step 은 Mark *뒤* 에 배치
        if: always()
        uses: actions/upload-artifact@v7
        with: { name: test-reports-gh-hosted, path: ... }

  test-self-hosted:
    needs: test-gh-hosted
    # always() 로 skipped 도 평가. outputs 는 continue-on-error 마스킹 안 받음
    if: ${{ always() && needs.test-gh-hosted.outputs.passed != 'true' }}
    runs-on: [self-hosted, macOS, ARM64, aidy-server]   # android: aidy-android
    # env 블록 불필요 — runner .env 에 JAVA_HOME/ANDROID_HOME 이미 주입됨
    steps:
      - uses: actions/checkout@v5
      - uses: actions/setup-java@v5
        with: { distribution: 'temurin', java-version: '21' }
      # ❌ actions/cache 제거 (ADR-010 §7)
      - name: Run tests
        run: ./gradlew test
      - name: Upload artifacts
        if: always()
        uses: actions/upload-artifact@v7
        with: { name: test-reports-self-hosted, path: ... }  # ★ name 중복 금지
```

**필수 원칙**:
1. primary job 에 `outputs.passed` + Mark step 포함. Mark 는 이전 step 모두 성공 시에만 실행됨 (암묵 `if: success()`)
2. fallback `if: ${{ always() && outputs.passed != 'true' }}` — `result` 대신 `outputs` 기준
3. `upload-artifact` 등 `if: always()` step 은 Mark step **뒤** 에 배치 (순서 중요)
4. artifact `name` 은 primary / fallback 분리 (`test-reports-gh-hosted` / `test-reports-self-hosted`)

⚠️ **WO-014/015 발견 반영 체크리스트** (워커 주의):
- `setup-java@v5 java-version: '21'` 양쪽 job 동일 유지 (server/android 둘 다 JDK 21 bytecode 요구, ADR-010 §6)
- `actions/cache@*` step 은 **self-hosted job 에서 제거** (ADR-010 §7)
- `actions/upload-artifact` 는 **v6+ 사용** (v5 는 action.yml `using: node20` 잔존 → deprecation, WO-015 발견)
- `gradle/actions/setup-gradle` 은 **v5 유지** (v6 는 caching proprietary 변경, 스코프 외)

### 2. DRY 원칙 — Composite action 또는 reusable workflow

매 workflow 에 2 job 중복은 유지보수 부담. **reusable workflow** 로 추출 권장:

```yaml
# .github/workflows/_test-reusable.yml (callable)
on:
  workflow_call:
    inputs:
      runner:
        type: string
        required: true
jobs:
  run:
    runs-on: ${{ fromJSON(inputs.runner) }}
    steps: [...]
```

```yaml
# test.yml (caller)
jobs:
  on-gh:
    uses: ./.github/workflows/_test-reusable.yml
    with:
      runner: '"ubuntu-latest"'
    # continue-on-error 는 reusable 내부 개별 step 에 적용 필요 (job level 지원 X) → 우회: 아래 needs.x.result 확인
  on-self:
    needs: on-gh
    if: needs.on-gh.result != 'success'
    uses: ./.github/workflows/_test-reusable.yml
    with:
      runner: '["self-hosted","macOS","ARM64","aidy-server"]'
```

⚠️ **주의**: reusable workflow 는 `continue-on-error: true` 를 job level 에서 지원하지 않음 → `needs.on-gh.result != 'success'` 조건이 "failure" 에만 트리거. "cancelled"도 커버하려면 `if: needs.on-gh.result == 'failure' || needs.on-gh.result == 'cancelled'`.

워커는 DRY 여부 선택 — 단순 인라인 복제가 YAML 이해도가 높으면 복제도 허용.

### 3. 서비스 계정 관점 — 컨텍스트 유지

GITHUB_TOKEN 은 각 job 마다 새로 발급 → fallback job 도 동일 권한 확보 OK. PR 코멘트/병합 로직이 ai-review.yml 에 있다면 **두 job 모두 동일 outputs 계약 유지** 필수.

### 4. Skip 조건 (optional)

빌링 정상일 때 굳이 fallback job 을 skip 하고 싶으면 repo variable 제어:

```yaml
  test-self-hosted:
    if: needs.test-gh-hosted.result != 'success' && vars.ENABLE_FALLBACK != 'false'
```

기본값은 `true` 가정. Kill switch 역할.

### 5. 검증 절차

각 워커가:
1. 빌링 OK 상태에서 workflow 실행 → `test-gh-hosted` green → `test-self-hosted` skipped 확인
2. 일시적으로 `runs-on: [ubuntu-latest-broken]` 같은 잘못된 라벨로 primary 강제 fail → fallback green 확인
3. 빌링 복구 후 상시 동작 확인

## 검증 기준

- [ ] server/android 각 repo 에서 workflow 2 job 구조로 전환 완료
- [ ] 정상 시나리오: primary green + fallback skipped
- [ ] 장애 시나리오: primary fail → fallback green
- [ ] iOS 워크플로는 변경 없음 (self-hosted only 유지)
- [ ] 동시 2 job (primary fail → fallback) 시 runner queue 대기 없이 pickup
- [ ] 분 소비량: 정상 시 primary 만 카운트 (기존과 동일)

## 완료 보고

`inbox/{server,android}-WO-016-done.md`
- workflow 변경 커밋 SHA + 전후 diff 요약
- 정상 + 장애 시나리오 run URL 각 1개 (총 2개)
- reusable workflow 채택 여부 + 이유
- fallback trigger 지연 (primary fail 감지 ~ fallback start) 측정값

## 리스크

- **시간 2배**: primary fail 시 fallback 재시도 → 테스트 실패 케이스에서 CI 체감 느림. 허용 범위 판단
- **이중 알림**: primary + fallback 둘 다 fail 시 notification 중복 가능. Slack/GitHub checks 정책 재확인 필요
- **cache 불일치**: primary(ubuntu) 와 fallback(macOS self-hosted) OS 다름 → OS-specific cache key 자동 분리 (actions/cache 가 runner.os 기반)
- **test flakiness 오탐**: primary 불안정 테스트가 매번 fallback 유도 → "primary 실패율 > 20%" 면 test 수정 우선 (ADR-010 규칙)

## 비고

- 이 WO 완료 후 WO-012 Gate 2 자동 재개 (fallback 로 green run 확보)
- B 패턴 (billing-only detect) 은 트래픽 폭증 or test fail 빈발 시 재검토 — ADR-010 에 evolution criteria 기록
