# ADR-010: Server/Android Self-hosted Runner 통합 + Hybrid Fallback 전략

**Date**: 2026-04-17
**Status**: Accepted (WO-014/015 검증 완료 — server 207 tests, android 135 tests green)
**Sprint**: WO-012 후속 (s7)
**Related**: ADR-009 (iOS self-hosted 선행), WO-012 / WO-014 / WO-015 / WO-016

## 배경

2026-04-17 WO-012 dispatch 중 재발한 GitHub Actions billing 차단:
> "The job was not started because recent account payments have failed or your spending limit needs to be increased"

- iOS: ADR-009 로 self-hosted 이미 전환 → 영향 없음 (WO-012 (iOS) PR #2 merged)
- server/android: GitHub-hosted (ubuntu-latest) 의존 → **job 시작 자체 차단** → green run 확보 불가 → WO-012 Gate 2 blocked
- 빌링 복구 불가 상황 (사용자 보고) → 단기 우회 + 구조 개선 동시 필요

ADR-009 "후속 검토 항목" 에 이미 명시됨:
> "aidy-server / aidy-android 도 같은 패턴(self-hosted) 적용 여부 — Linux runner는 분 가중치 1x 라 GitHub-hosted 그대로 두는 게 합리적일 수도. 결제 차단 영향 받는지 별도 확인 필요."

결제 차단 영향을 직접 받음이 확인됨 → 재평가 필요.

## 결정

**3 워커 모두 self-hosted runner 를 포함한다. 단, 워커별 전략 차등 적용:**

| 워커 | 전략 | 근거 |
|---|---|---|
| **iOS** | self-hosted **only** | macOS runner 분당 계수 10x — GitHub-hosted 쓰면 월 200분 = 금방 소진. ADR-009 유지 |
| **Server** | **Hybrid**: GitHub-hosted primary + self-hosted fallback | Linux 계수 1x — 평상시 무료 쿼터(2000분) 로 충분. 빌링 차단 시 자동 fallback |
| **Android** | **Hybrid**: GitHub-hosted primary + self-hosted fallback | 동일 논리 + 사용자 의도 "셋다 github 먼저 찌르고 실패시 self-hosted" |

구현: WO-014 (server runner) + WO-015 (android runner + SDK) + WO-016 (fallback workflow 패턴).

### Fallback 패턴 선택: A (Job-level if)

기술 검토에서 3 패턴 비교:

| 패턴 | 복잡도 | 커버 범위 | 채택 |
|---|---|---|---|
| **A. Job-level if** (`continue-on-error` + `needs.x.result != 'success'`) | 낮음 (2 job) | billing + cancel + test fail 전부 | ✅ |
| B. Billing annotation detect (3 job) | 중간 (3 job, API 호출) | billing 만 정밀. test fail 은 fallback 안 함 | 보류 (evolution 조건 하단) |
| C. Self-hosted only + 주간 cron 크로스체크 | 낮음 (1 job) | billing 독립성 최대 | 사용자 의도 불일치 ("github 먼저") |

**A 채택 이유**: 사용자 의도 100% 부합 + 구현 간결. 단점(진짜 test fail 시 self-hosted 재시도 → 시간 2배) 은 허용 범위.

**B 로의 evolution 조건** (미래):
- primary test 실패율 > 20% 누적 3주 → fallback 오염 발생 → B 패턴 재평가
- or CI 분 비용이 하루 10달러 초과 → billing-only detect 필요

## 대안 비교

| 대안 | 비용 | 의존성 | 폐기 사유 |
|---|---|---|---|
| GitHub billing 정상화 (카드 갱신) | Linux 계수 1x → 월 2000분 무료, 초과 $0.008/min | 결제 유지 | 같은 사고 재발 가능. **사용자 현재 불가** |
| server/android GitHub-hosted only (대기) | 0 (빌링 정상 시) | GitHub 인프라 + 결제 상태 | **빌링 차단 중** → WO-012 영원히 blocked |
| server/android self-hosted only | 0 (전기료) | MBA 가용성 | 사용자 의도 "깃헙 먼저" 불일치. 무료 쿼터 활용 기회 상실 |
| **Hybrid (A 패턴)** | 평상시 0 (github 무료 쿼터) + 비상시 self-hosted | MBA 백업 가용성 | **선택**. 쿼터 최대 활용 + 장애 독립성 |

## 예상 영향

### 긍정
- **WO-012 Gate 2 unblock**: self-hosted fallback 으로 server/android green run 확보 경로 확보
- **빌링 독립**: 빌링 차단 다시 발생해도 CI 자동 복구
- **Linux 무료 쿼터 활용**: 다음 billing cycle reset 후 primary 로 재사용 (공짜)
- **iOS WO-010 패턴 복제**: runner 등록/launchd svc/JDK 세팅 절차 재활용

### 부정 / 위험
- **MBA 부하 집중**: iOS + server + android runner 3개 동시 busy 가능 → CPU/메모리 경합. 완화: 평상시 primary 가 GitHub 에서 돌아서 self-hosted 3-동시 busy 는 드뭄 (fallback 상황에서만)
- **디스크 소비 급증**: iOS Xcode(~30GB) + Android SDK(~15GB) + Gradle 캐시(~5GB) + _work 누적 → **50GB+ 필요**. MBA 디스크 여유 확인 필수
- **환경 드리프트**: 사용자가 MBA JDK/SDK 업그레이드 시 CI 영향 → 운영 규칙으로 완화
- **Test flakiness 오탐**: primary 불안정 → fallback 상시 재시도 → CI 느림. B 패턴 evolution 조건으로 대응
- **이중 알림**: primary + fallback 양쪽 fail 시 notification 중복. Slack/checks 정책 재점검 필요

## 운영 규칙

### 1. MBA 환경 변경은 CI 재검증 필수
- JDK, Android SDK, Xcode 업그레이드 시 → 수동 workflow_dispatch 로 3 repo 회귀 테스트
- 시스템 업그레이드(macOS major) 시 → WO-010 같은 수준의 사전 점검

### 2. 디스크 관리
- 월 1회: `./gradlew --stop && rm -rf ~/.gradle/caches/build-cache-*`
- 분기 1회: `~/actions-runner*/_work` 확인 및 정리
- 포화 방지: `df -h` 모니터링 (자동화 backlog 후보)

### 3. Runner 장애 대응
- 각 runner svc 상태: `~/actions-runner-{ios,server,android}/svc.sh status`
- 로그: `~/Library/Logs/actions.runner.Mino777-aidy-{ios,server,android}.*/Runner_*.log`
- 장애 시 workflow 는 primary(GitHub) 로 자동 fallback ← hybrid 의 **양방향 안정성** 핵심

### 4. 라벨 충돌 방지
- iOS runner: `aidy-ios`
- server runner: `aidy-server`
- android runner: `aidy-android`
- workflow 의 `runs-on` 배열에 repo-specific 라벨 포함 필수 (OS-only 라벨로 다른 repo 에 잘못 할당되는 사고 방지)

### 5. Fallback 발동률 모니터링
- weekly: `gh run list --json conclusion,name` 로 fallback job 빈도 추적
- 발동률 > 30% 3주 연속 → B 패턴 / billing 정상화 / primary 문제 재평가

### 6. JDK 버전 정책 (WO-015 발견)
- **원칙**: runner `.env` 의 `JAVA_HOME` 은 baseline (기본값 안전망), **프로젝트의 실제 JDK 요구와 다르면 workflow 의 `setup-java@v5` 로 override**
- Android 사례: `app/build.gradle.kts` 가 JDK 21 요구 → `.env` 의 JDK 17 대신 `actions/setup-java@v5` with `java-version: '21'` 이 tool-cache 에 Temurin 21 설치 (idempotent, cache hit)
- server 사례: 동일 — setup-java@v5 가 Temurin 21 자동 설치. runner `.env` JDK 17 은 unused but harmless
- **금지**: build.gradle 수정으로 프로젝트 JDK 를 runner 기본에 맞추려 하지 말 것 (프로젝트 스펙은 별도 WO 로 변경)

### 8. Hybrid Fallback YAML 패턴 — Mark-step 우회 (WO-016 server 발견)

**버그**: `continue-on-error: true` 가 job-level 에 있으면 `needs.<job>.result` 가 실제 실패에도 불구하고 **`success` 로 마스킹**됨 (GitHub Actions 문서화 빈약). 결과적으로 `!= 'success'` 조건이 항상 false → fallback 영원히 skip.

**증거 (WO-016 server run 24539214108)**:
- primary conclusion: `failure` (billing 차단)
- fallback conclusion: **`skipped`** (예상: success)
- workflow 전체: `success` (의도와 반대 결과)

**수정 패턴 — Mark-step**:
```yaml
test-gh-hosted:
  runs-on: ubuntu-latest
  continue-on-error: true
  outputs:
    passed: ${{ steps.mark.outputs.passed }}
  steps:
    - # ... actual work steps ...
    - name: Mark primary success
      id: mark
      # 암묵 `if: success()` — 이전 step 중 하나라도 failure 면 실행 안 됨
      run: echo "passed=true" >> $GITHUB_OUTPUT
    - # upload-artifact 같은 `if: always()` step 은 Mark 뒤에 배치

test-self-hosted:
  needs: test-gh-hosted
  # always() 로 skipped 도 평가. outputs 는 continue-on-error 마스킹 안 받음
  if: ${{ always() && needs.test-gh-hosted.outputs.passed != 'true' }}
```

**Merge-step 가드 강화 (WO-016 android 발견)**: ai-review 등 **조건부 merge step**이 있는 workflow 에서는 Mark step 에 추가 가드 필수. 암묵 `if: success()` 만으로는 "merge step 이 rebase conflict 로 skip → 그러나 이전 step 은 success" 상황에서 fallback 이 잘못 skip 됨.

```yaml
- id: merge
  if: <merge 조건>
  run: ...
  outputs:
    merged: ${{ steps.merge.outputs.merged }}

- name: Mark primary success
  id: mark
  if: steps.merge.outputs.merged == 'true'   # ★ 조건부 step 결과까지 확인
  run: echo "passed=true" >> $GITHUB_OUTPUT
```

→ **규칙**: `if: <조건>` 으로 skip 가능한 step 이 primary 에 있으면 Mark 에 동일/파생 조건 복제.

**검증 (WO-016 server)**:
- 장애 시나리오 (billing 차단): primary fail → fallback green **3초 지연** ✓
- 장애 시나리오 (step-level exit 1 주입): 동일 동작 ✓
- 정상 시나리오: billing 차단 중이라 관찰 deferred — 코드 레벨 보증 (Mark step 이 암묵 `if: success()` 라 실패 시 실행 안 됨 → `passed` 미설정 → fallback 발동)

**runner 직렬화 비용 (실측)**:
- 같은 repo 의 Test + Auto Merge workflow 가 동일 self-hosted runner 를 두고 경합
- 먼저 점유된 경우 대기 시간 20-60초 추가
- ADR-010 §5 fallback 발동률 모니터링에 "runner 대기 시간" 지표 추가 고려

### 7. Self-hosted에서 actions/cache 금지 (WO-014 발견)
- `~/.gradle/caches`, `~/Library/Developer/Xcode/DerivedData` 등은 self-hosted 에 **로컬 영구** → GitHub Actions cache service (`actions/cache`) 중복 + 불필요
- 실측: WO-014 1차 run 에서 `Post Cache Gradle` 단계가 15분+ hang (cache upload 가 billing 제약과 맞물린 것으로 추정) → step 제거 후 정상
- **규칙**: self-hosted runner 전용 workflow 에서는 `actions/cache@*` step 제거. primary(ubuntu-latest) + fallback(self-hosted) hybrid 에서는 OS별 cache key 자동 분리라 유지 가능하지만 self-hosted job 에선 skip 고려 (WO-016 에서 판단)

## 의사결정 기록

| 시각 | 사실 | 결정 |
|---|---|---|
| 2026-04-17 15:40 | WO-012 dispatch (3 워커 send-seq) | iOS green, server/android billing 차단 |
| 2026-04-17 15:55 | android-request.md 에스컬레이션 | architect: billing 복구 or self-hosted 전환 검토 |
| 2026-04-17 t1 | 사용자: "빌링 복구 안되는 상황. B로 가야될듯" | **self-hosted 통합 결정** |
| 2026-04-17 t2 | WO-014/015/016 초안 + ADR-010 | 3 WO dispatch 준비 |
| 2026-04-17 t3 | Architect: 3 runner 등록 + JDK 17 + Android SDK 35 세팅 | jominhoui-mba-{ios,server,android} 모두 online |
| 2026-04-17 t4 | WO-014 완료 (server, 207 tests green) | actions/cache 제거 발견 → 규칙 §7 추가 |
| 2026-04-17 t5 | WO-015 완료 (android, 135 tests green) | 프로젝트 JDK 21 요구 발견 → 규칙 §6 추가 |
| 2026-04-17 t6 | **Status: Accepted** | WO-016 dispatch 로 진행 |

## 박제 교훈

1. **"후속 검토 항목" 은 실제 후속**: ADR-009 작성 시 "server/android 는 나중에 검토" 가 1 스프린트 만에 실제 이슈로 돌아옴. 미래 불확실한 결정은 반드시 문서화.
2. **billing 복구 가능성은 결정 변수**: "결제 카드 갱신" 이 옵션일 때와 아닐 때의 최적 아키텍처가 다름. 조직 제약은 기술 결정의 1차 입력.
3. **사용자 의도 우선**: A/B/C 중 A가 구현 제일 쉽지만 채택 이유는 "사용자 의도 부합". 기술적 우아함 < 사용 흐름 fit.
4. **Hybrid 는 양방향 안전망**: 단일 runner 의존은 장애 시 전멸. primary/fallback 이중화는 billing + MBA 장애 둘 다 커버.

## 후속 검토 항목

- 빌링 정상화 시: primary/fallback 비율 관찰 — fallback 발동률 < 5% 면 cost 최적 구조 유지. 5~30% 면 primary 안정화 필요.
- Xcode Cloud (25h/월 무료) 재평가 — iOS self-hosted 대안으로 한 번 더 검토
- Instrumented Android test (emulator) 지원 — 현재 unit test only, 향후 WO 로 emulator 세팅 검토
- MBA → 전용 CI 서버 (Mac mini + UPS) 이관 — 사용자 작업 부하 충돌 해결
