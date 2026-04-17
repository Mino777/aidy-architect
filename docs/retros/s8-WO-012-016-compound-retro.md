# s8 Compound 회고 — WO-012/014/015/016 (CI 인프라 독립화)

**일시**: 2026-04-17
**워커**: ios + server + android (전체)
**소요**: 1 세션 (~3h, 리밋 대기 포함)
**ADR**: ADR-010 (신규 + 3차 보강)

## 이번에 한 것

1. **WO-012**: 3 리포 GitHub Actions Node.js 24 호환 업그레이드 (2026-06-02 deadline 대비)
2. **WO-014**: server self-hosted macOS runner 전환 (billing 차단 우회)
3. **WO-015**: android self-hosted macOS runner + Android SDK 35 통합
4. **WO-016**: Hybrid fallback 패턴 (GitHub-hosted primary → self-hosted fallback)
5. **ADR-010**: 3회 보강 (§6 JDK 정책, §7 cache 금지, §8 Mark-step 우회 패턴 + merge 가드)
6. **인프라**: MBA에 3 self-hosted runner 동시 운영체제 구축

## 잘된 것

- **send-seq P3-7 첫 실전**: WO-012 3 워커 직렬 dispatch → idle 감지 정상 (195s→465s→210s). rate-limit 없이 깔끔한 파이프라인.
- **위기 대응 체인**: billing 차단 발견 → 사용자와 즉시 방향 전환 → self-hosted 통합 결정 → 동일 세션 내 4 WO 완주. Plan B 실행 속도가 핵심.
- **워커 자율 판단**: server 워커가 `actions/cache` 15분 hang 독립 해결, android 워커가 ai-review Mark 가드 패턴 자체 설계. 두 발견 모두 ADR-010에 즉시 반영.
- **Mark-step 긴급 대응**: WO-016 §1 예시 패턴 버그를 server 1차 실행에서 발견 → ADR/WO 정정 → android 워커에 tmux 긴급 알림 → android가 server main YAML cross-check 후 정상 적용. **라이브 스펙 정정 + 크로스 워커 전파 1 세션 내 완결.**
- **iOS self-hosted 전환(WO-010)의 숨겨진 배당**: iOS가 billing 독립이라 WO-012에서 유일하게 즉시 green 확보. 선행 투자가 이번 세션의 부분 성공 보장.

## 아쉬운 것 (다음 사이클 입력)

- **WO-016 §1 예시 패턴 버그**: `continue-on-error` + `needs.x.result` 조합이 작동 안 하는 건 Architect(나)가 spec 작성 시 검증 안 한 것. **spec 예시 코드에 대한 dry-run 검증 프로세스 부재**. → 다음부터 workflow 패턴 spec 작성 시 "1회 실행 후 spec 확정" 원칙 적용
- **billing 차단 조기 감지 실패**: WO-012 dispatch 시 billing 차단을 3 워커 모두 실행한 뒤에야 발견. ci-status.sh 같은 사전 체크가 있었으면 1 워커만 실행하고 방향 전환 가능했음.
- **정상 시나리오 검증 deferred**: server/android 모두 billing 차단 상태라 "primary green → fallback skipped" 경로를 실증 못 함. 코드 레벨 보증만 존재. billing 복구 후 반드시 재검증.
- **JDK 17 vs 21 미스매치**: WO-014/015 spec에 JDK 17 고정 가정했으나 실제 프로젝트는 JDK 21 필요. **Architect의 spec 전제 검증 부족**. 워커가 현장 보정했지만 spec 정확도 개선 필요.
- **Android SDK 경로 spec 오류**: `$HOME/Library/Android/sdk` 예상했으나 실제 brew cask는 `/opt/homebrew/share/android-commandlinetools`. spec 작성 시 설치 전에 경로 가정 → 설치 후 정정 필요했음.

## 다음에 적용할 것

1. **Workflow 패턴 spec에 실행 검증 게이트 추가**: spec §1 예시 코드 작성 후 → 1 워커 dispatch → 실증 → spec 확정 → 나머지 워커 dispatch. "spec-first-verify-first" 원칙.
2. **billing/quota 사전 체크**: dispatch 전 `gh api /repos/.../actions/runners` + billing 상태 확인 step을 dispatch.md에 Phase 0으로 추가
3. **프로젝트 JDK/SDK 버전 사전 조사**: WO 작성 시 `build.gradle.kts` 의 `jvmTarget`, `compileSdk` 확인 후 spec에 반영. Architect가 워커 프로젝트 빌드 설정 1회 읽기를 의무화.
4. **ADR-010 §8 (Mark-step 패턴)을 새 WO template에 포함**: hybrid fallback workflow WO 발행 시 자동 체크리스트 항목
5. **billing 복구 후 정상 시나리오 검증**: WO-017 후보 (cron 또는 수동)

## Compound Assets (이번 사이클에서 생성된 재사용 자산)

| 자산 | 경로 | 재사용 시점 |
|---|---|---|
| ADR-010 (Hybrid Fallback 전략) | `specs/decisions/010-server-android-self-hosted-hybrid.md` | 새 리포 CI 세팅, runner 추가 시 |
| Mark-step 패턴 (§8) | ADR-010 §8 | GitHub Actions continue-on-error 사용 시 전부 |
| self-hosted runner 등록 절차 | WO-014/015 §1 (Architect 완료 섹션) | 새 runner 추가 시 |
| send-seq 실전 로그 | `docs/worker-prompts/2026-04-17.md` | 직렬 dispatch 프롬프트 엔지니어링 참조 |
| 솔루션: continue-on-error masking | `docs/solutions/2026-04-17-continue-on-error-masking.md` | GitHub Actions workflow 작성 시 |

## For AI Agents

다음 세션에서 이 회고를 입력으로 받을 때:
- **billing 차단이 해소됐는지 먼저 확인**: `gh api /repos/Mino777/aidy-server/actions/runs --jq '.workflow_runs[0] | {conclusion, created_at}'` 로 최신 run 이 billing fail 인지 체크
- **정상 시나리오 검증 미실행**: WO-016 server/android 모두 "primary green → fallback skipped" 실증 필요. billing 복구 감지 시 즉시 빈 커밋 push로 검증
- **ADR-010 §8 (Mark-step) 은 GitHub Actions 고유 버그 우회**: `continue-on-error: true` 가 `needs.x.result` 를 마스킹하는 건 미문서화 동작. GitHub 가 고치면 Mark-step 불필요해질 수 있으니 주기적 재확인
- **runner 3대 동시 busy 경합**: MBA CPU/메모리 모니터링 (`top -l 1` 또는 `activity monitor`) + runner 대기 시간 P95 추적 필요
- **upload-artifact v5 함정**: release note "Node 24 호환" vs action.yml `using: node20` 불일치. 새 액션 bump 시 action.yml 의 `runs.using` 직접 확인 필수
