# GitHub Actions `continue-on-error` 가 `needs.result` 를 마스킹하는 버그

## 증상

```yaml
jobs:
  primary:
    runs-on: ubuntu-latest
    continue-on-error: true       # 실패해도 다음 job 진행
  fallback:
    needs: primary
    if: needs.primary.result != 'success'    # ← 항상 false
    runs-on: [self-hosted, ...]
```

primary 가 billing/step 실패로 fail 해도 **fallback 이 영원히 skipped**. workflow 전체는 `success` 로 표시.

## 근본 원인

`continue-on-error: true` 가 **job-level** 에 있으면 `needs.<job>.result` 가 실제 실패에도 불구하고 `'success'` 로 마스킹됨. GitHub Actions 의 미문서화 동작.

- `needs.primary.result` → `'success'` (실제: failure)
- `needs.primary.outcome` → 존재하지 않음 (job-level 에는 `outcome` 미제공, step-level 에만 있음)

따라서 `result` 또는 `outcome` 어느 것으로도 "실제 실패 여부" 를 needs 에서 확인 불가.

## 해결 (before → after)

### Before (작동 안 함)
```yaml
fallback:
  needs: primary
  if: needs.primary.result != 'success'   # 항상 false
```

### After — Mark-step 우회 패턴
```yaml
primary:
  runs-on: ubuntu-latest
  continue-on-error: true
  outputs:
    passed: ${{ steps.mark.outputs.passed }}
  steps:
    - # actual work ...
    - name: Mark primary success
      id: mark
      # 암묵적 if: success() — 이전 step 중 하나라도 fail 이면 skip
      run: echo "passed=true" >> $GITHUB_OUTPUT
    - # upload-artifact 등 if: always() step 은 Mark *뒤* 에 배치

fallback:
  needs: primary
  if: ${{ always() && needs.primary.outputs.passed != 'true' }}
  runs-on: [self-hosted, ...]
```

### 왜 작동하는가
1. `outputs` 는 `continue-on-error` 에 의해 마스킹되지 않음 (step-level 값 직접 전달)
2. Mark step 은 `if: success()` (암묵 기본값) — 이전 step 실패 시 skip → `passed` 미설정 → fallback 발동
3. billing 차단(job startup fail) → 어떤 step 도 실행 안 됨 → `passed` 미설정 → fallback 발동
4. `always()` 는 `needs.primary` 가 skipped/cancelled 인 경우에도 평가 실행

### Merge-step 가드 강화 (조건부 step 이 있는 경우)
```yaml
- id: merge
  if: <merge 조건>
  run: ...
  outputs:
    merged: ${{ steps.merge.outputs.merged }}

- name: Mark primary success
  id: mark
  if: steps.merge.outputs.merged == 'true'   # 조건부 step 결과까지 확인
  run: echo "passed=true" >> $GITHUB_OUTPUT
```

## 체크리스트 (재발 방지)

- [ ] `continue-on-error: true` 사용 시 fallback 트리거에 `needs.x.result` 절대 사용 금지
- [ ] 반드시 Mark-step 패턴 적용 (`outputs.passed` + `if: always() && != 'true'`)
- [ ] 조건부 step (`if: <조건>`) 이 primary 에 있으면 Mark 에 동일/파생 가드 추가
- [ ] `upload-artifact` 등 `if: always()` step 은 Mark step **뒤** 에 배치
- [ ] artifact `name` 은 primary / fallback 분리 (`-gh-hosted` / `-self-hosted`)
- [ ] 새 workflow 작성 시 1회 dry-run 후 spec 확정 (spec-first-verify-first)

## 발견 경로

- WO-016 (server) 1차 적용 → run 24539214108: primary fail + fallback **skipped** → 예상 반대 결과
- 원인 분석 → Mark-step 우회 패턴 설계 → 2차 적용 → run 24539324015: primary fail → fallback **green** (3초 지연) ✓
- ADR-010 §8 + WO-016 §1 즉시 정정 → android 워커에 tmux 긴급 알림 → cross-check 후 정상 적용

## 참조

- ADR-010 §8 (Aidy project 내부)
- GitHub Community: "continue-on-error masks needs.result" — 공식 문서에 명시 안 됨 (2026-04 기준)
