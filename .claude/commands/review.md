# /review — 2-Stage Pre-Landing Review

PR 또는 현재 diff를 머지 전 리뷰한다.
Plan 문서(PLAN.md 또는 WO)가 존재하면 2-stage, 없으면 1-stage.

## Stage 0: Plan/WO 문서 탐지

- Plan/WO 문서 있음 → **Stage 1 + Stage 2** 순차 실행
- Plan/WO 문서 없음 → **Stage 2만** 실행

## Stage 1: Spec Compliance (Plan/WO 있을 때만)

Plan 또는 WO의 각 항목을 diff와 line-by-line 대조. api-contract.md 준수 여부도 확인.

### 체크리스트
- [ ] Plan/WO의 모든 항목이 구현되었는가?
- [ ] api-contract.md와 일치하는가?
- [ ] Plan에 없는 스코프 밖 변경이 있는가?

### 판정
- ✅ PASS / ⚠️ WARNING / ❌ FAIL
- Stage 1이 FAIL이면 Stage 2 진행하지 말고 즉시 보고.

## Stage 2: Code Quality (항상 실행)

### 체크리스트
- [ ] 보안: OWASP Top 10
- [ ] 타입 안전
- [ ] 에러 처리: 경계에서만 검증
- [ ] 성능
- [ ] 테스트: 변경된 로직에 대한 커버리지
- [ ] api-contract.md 스키마 일치

### 판정
- ✅ PASS / ⚠️ WARNING / ❌ FAIL

## 출력 형식

```markdown
# Review: [WO 번호 또는 브랜치명]

## Stage 1: Spec Compliance [PASS/WARN/FAIL/SKIP]
## Stage 2: Code Quality [PASS/WARN/FAIL]
## 최종 판정: [PASS/WARN/FAIL]
```
