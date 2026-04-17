# WO-016 완료 보고 (server)

**시각**: 2026-04-16
**최종 main**: `86fe88c WO-016 cleanup: 장애 시나리오 주입 step 제거 (#4)`
**상태**: hybrid 패턴 정상 동작 확인. **1 가지 중요 발견**은 ADR-010 업데이트 필요.

---

## 1. Workflow 변경 요약

| 파일 | 변경 | 줄수 (순 변화) |
|---|---|---|
| `.github/workflows/test.yml` | 1-job → 2-job hybrid (primary + fallback) + Mark 패턴 | +62 / -3 |
| `.github/workflows/ai-review.yml` | 1-job → 2-job hybrid + Mark 패턴 | +132 / -1 |

총 4개 커밋이 main 에 squash merge 됨:
- `eb8db70` (#2) WO-016: 최초 hybrid 적용 + `continue-on-error` 버그 우회
- `61ce3ec` (#3) 장애 시나리오 주입 (step-level exit 1)
- `86fe88c` (#4) 주입 step 제거 (최종 정리)

### Reusable workflow — **미채택**
- WO-016 §2 의 `continue-on-error` 제약 (reusable caller 에서 job-level 불가) 로 인해
  `if:` 조건을 별도 작성해야 함 → 패턴 단일화 이득 상쇄
- server 는 workflow 2개 (test / ai-review) + shape 서로 다름 → DRY 이득 적음
- **인라인 복제** 방식으로 가독성 우선. task 지침 "인라인 복제로 가도 OK" 에 부합.

---

## 2. 중요 발견 — WO-016 §1 예시 패턴의 버그 (ADR-010 업데이트 필요)

### 현상
최초 커밋 (`0afbfdc`, 지금은 main 에 없음) 으로 WO-016 §1 의 예시 패턴 그대로 적용:
```yaml
test-gh-hosted:
  runs-on: ubuntu-latest
  continue-on-error: true
test-self-hosted:
  needs: test-gh-hosted
  if: needs.test-gh-hosted.result != 'success'
```

실제 run (24539214108) 관찰:
- primary `conclusion`: `failure` (billing 차단)
- fallback `conclusion`: **`skipped`** ← 예상과 반대
- workflow 전체: `success`

### 원인
`continue-on-error: true` 가 job-level 에 있으면 `needs.<job>.result` 가 실제
실패에도 불구하고 **`success` 로 마스킹됨** (GitHub Actions 의 문서화 빈약한 동작).
결과적으로 `!= 'success'` 조건이 항상 false → fallback 영원히 skip.

### 수정 패턴 (이 WO 에서 채택)
```yaml
test-gh-hosted:
  runs-on: ubuntu-latest
  continue-on-error: true
  outputs:
    passed: ${{ steps.mark.outputs.passed }}
  steps:
    - # ... 실제 작업 steps ...
    - name: Mark primary success
      id: mark
      # 암묵적 if: success() — 이전 step 중 하나라도 failure 면 실행 안 됨
      run: echo "passed=true" >> $GITHUB_OUTPUT
    - # upload 같은 if: always() step 은 Mark *이후* 배치해야 안전

test-self-hosted:
  needs: test-gh-hosted
  # always() 로 skipped 도 평가. outputs 는 continue-on-error 에 마스킹되지 않음.
  if: ${{ always() && needs.test-gh-hosted.outputs.passed != 'true' }}
```

**제안**: ADR-010 §7 또는 새 §8 "hybrid fallback YAML 패턴" 항목으로 이 버그/수정 박제.

---

## 3. 정상 시나리오 검증 — **현재 billing 하에서 관찰 불가 (설계상 한계)**

**요구**: primary green → fallback skipped

**실측**: 모든 run 에서 primary 가 billing 차단으로 failure → 한 번도 primary green 을 관찰할 기회 없음

**간접 증명**:
- Mark step (`echo passed=true`) 은 암묵 `if: success()` 로 primary 전 step 성공 시에만 실행
- fallback 의 `if: always() && outputs.passed != 'true'` 는 `passed == 'true'` 면 skip
- 따라서 billing 복구 후 primary green 이면 fallback 자동 skip 될 것 (코드 레벨 보증)

**후속**: billing 정상화 시 즉시 이 시나리오 재검증 요청. 또는 architect 가 billing 복구
전에 이 시나리오 수동 관찰이 필요하다고 판단하면 알려주길.

---

## 4. 장애 시나리오 검증 — **두 경로 모두 관찰**

### 경로 A: 자연 발생 (billing 차단 → job startup 실패)
run 24539324015 (Test workflow, fix 직후):
- primary `conclusion`: failure, `started_at`: 23:27:46, `completed_at`: 23:27:47 (1초, `steps: []`)
- fallback `conclusion`: success, `started_at`: 23:27:50, `completed_at`: 23:28:26 (36초)
- **trigger 지연**: 23:27:47 → 23:27:50 = **3초**
- workflow 전체: success (continue-on-error 의 의도대로)

### 경로 B: step-level failure 명시 주입
커밋 `61ce3ec` 에 primary 첫 step 으로 `exit 1` 추가 후 run 24539473856:
- primary `conclusion`: failure, `started_at`: 23:32:13, `completed_at`: 23:32:15, **`steps: []`**
- fallback `conclusion`: success (36초)
- trigger 지연: **3초** (경로 A와 동일)

⚠️ **경로 B 의 한계**: `steps: []` 는 `exit 1` step 이 실제로는 실행되지 않았음을 의미.
billing 차단이 job 시작 단계에서 끊어내서 step-level 실패 모드와 job-startup 실패
모드를 구별할 수 없음. **기능적으로는 동일** — Mark step 미실행 → outputs.passed
미설정 → fallback 트리거. 설계된 우회 패턴은 양 경로에서 동일하게 작동 입증됨.

---

## 5. 핵심 Run URL

| 시나리오 | Workflow | Run ID | URL | 결과 |
|---|---|---|---|---|
| 장애 (billing 자연) | Test | 24539324015 | https://github.com/Mino777/aidy-server/actions/runs/24539324015 | primary fail → fallback green |
| 장애 (billing 자연) | Auto Merge | 24539324003 | https://github.com/Mino777/aidy-server/actions/runs/24539324003 | primary fail → fallback green (squash merge 까지) |
| 장애 (exit 1 주입) | Test | 24539473856 | https://github.com/Mino777/aidy-server/actions/runs/24539473856 | 주입 step 도달 못함 (billing), 나머지 동일 |
| 최종 정리 | Test | 24539570464 | https://github.com/Mino777/aidy-server/actions/runs/24539570464 | 주입 제거 후 fallback green 확인 |
| 최종 정리 | Auto Merge | 24539570441 | https://github.com/Mino777/aidy-server/actions/runs/24539570441 | 동일, main squash merge |

---

## 6. Fallback Trigger 지연 측정값

| Run | Workflow | 지연 (sec) | 비고 |
|---|---|---|---|
| 24539324015 | Test | **3** | primary 종료 23:27:47 → fallback start 23:27:50 |
| 24539324003 | Auto Merge | 43 | Test fallback 이 먼저 runner 점유 → Auto Merge fallback 대기 |
| 24539473856 | Test | **3** | exit 1 주입 run |
| 24539570441 | Auto Merge | 3 | 23:35:08 → 23:35:11 |
| 24539570464 | Test | 57 | Auto Merge fallback 이 먼저 점유 → 대기 (23:35:08 → 23:36:05) |

**결론**: runner 유휴 시 **~3초** 의 공통 지연 (GitHub Actions 의 job 평가/dispatch overhead).
동일 workflow 조합에서 self-hosted runner 가 이미 busy 면 대기 시간 추가 (20~60초).
ADR-010 "MBA 부하 집중" 리스크 실측 — 현재는 server runner 1개만 있어 Test + Auto Merge
fallback 이 직렬화됨.

---

## 7. 테스트 숫자

| Run | 출처 | tests | failures | errors |
|---|---|---|---|---|
| 24539324015 | 장애 시나리오 fallback artifact | **207** | **0** | **0** |
| 24539570464 | 최종 정리 fallback artifact | **207** | **0** | **0** |

`./gradlew test --no-daemon` 결과 WO-014 baseline 과 동일. ChatControllerTest flake 재현 없음.

---

## 8. 추가 검증 항목

- [x] primary(ubuntu) / fallback(self-hosted) 2-job 구조 전환 ✓
- [x] fallback trigger: failure + cancelled + billing-startup-fail 모두 커버 ✓
- [x] self-hosted job 에서 `actions/cache` 제거 (ADR-010 §7) ✓
- [x] primary 에서만 `actions/cache@v5` 사용 ✓
- [x] `actions/upload-artifact@v7` (v6+ 조건) + artifact 이름 분리 (`test-reports-{gh,self}-hosted`) ✓
- [x] `setup-java@v5` Temurin 21 양쪽 동일 ✓
- [x] Auto Merge 전체 파이프라인(PR 생성 / rebase / test / squash / reset) fallback 에서도 성공 ✓
- [x] iOS workflow 변경 없음 (이 repo 범위 외) ✓
- [x] 최종 main green 상태 (`86fe88c`) ✓

---

## 9. Architect 결정/확인 필요 항목

1. **ADR-010 업데이트 제안**: §8 "hybrid fallback YAML 패턴 (Mark-step 우회)" 추가로
   `continue-on-error` masking 버그 박제. WO-015 가 같은 패턴 적용했거나 적용 예정이면
   미리 공유 필요 (동일 버그 재현 방지).
2. **정상 시나리오 검증 deferred**: billing 복구 시 primary green → fallback skipped
   수동 관찰 (workflow_dispatch 또는 빈 커밋 push). 지금 할 수단 없음.
3. **Runner 직렬화 비용**: Test + Auto Merge fallback 이 같은 self-hosted runner 를
   두고 직렬 대기. 매 PR 마다 ~2분 추가 소요. ADR-010 §5 "fallback 발동률" 모니터링에
   "runner 대기 시간" 지표 추가 고려.
4. **WO-016 §1 예시 수정**: WO-016 문서 자체의 §1 예시 코드 블록이 틀린 패턴을 담고 있음.
   WO-015 / 향후 WO 에서 같은 함정에 빠지지 않도록 문서 정정 권장.
