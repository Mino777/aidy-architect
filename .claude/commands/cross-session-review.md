# /cross-session-review — 워커 세션 결과물 크로스 검증

다른 Claude 세션(워커)이 작업한 결과를 **메타데이터 신뢰 없이 line-by-line 검증**한다.
Journal 019에서 박제한 프로토콜 적용.

**핵심**: 커밋 메시지가 깨끗해도 diff는 망가져 있을 수 있다. 검증 없이 신뢰 금지.

---

## 입력

- 워커 이름 (예: `server`)
- 또는 "전체" — 모든 워커 순회

---

## Phase 1 — 변경 범위만 추출 (메타데이터 무시)

```bash
cd ~/Develop/aidy-<worker>
git log --oneline -5
git diff HEAD~1 --stat
git diff HEAD~1
```

**금지**: commit message를 근거로 인용하지 마. 코드만 본다.

---

## Phase 2 — 4 함정 grep (aidy 적용)

### 함정 1: 스펙에 없는 엔드포인트/필드 추가
```bash
# 서버: contract에 없는 매핑
grep -rn "@GetMapping\|@PostMapping\|@DeleteMapping" src/main/kotlin/ | grep -v "test"
# 결과를 api-contract.md와 대조
```

### 함정 2: Dead code (소비자 0건)
```bash
# 새로 추가된 필드/함수의 사용처 확인
git diff HEAD~1 | grep "^+.*fun \|^+.*val \|^+.*var " | head -20
# 각각에 대해 grep으로 호출부 확인
```

### 함정 3: 에러 코드 스펙 불일치
```bash
# 실제 에러 코드 vs contract Error Codes 표
grep -rn "error\|Error\|ERROR" src/main/kotlin/ | grep -v "test\|import"
```

### 함정 4: 하드코딩된 시크릿/API 키
```bash
grep -rn "api.key\|secret\|password\|token" src/ --include="*.kt" --include="*.swift" --include="*.java" | grep -v "test\|Test\|env\|ENV\|config"
```

---

## Phase 3 — 빌드 검증 (CI 위임 금지)

```bash
cd ~/Develop/aidy-<worker>
# 프로젝트별 빌드 + 테스트
# server: ./gradlew clean build
# ios: tuist generate && xcodebuild build
# android: ./gradlew assembleDebug
```

---

## Phase 4 — 분류 + 리포트

| 카테고리 | 의미 | 처리 |
|---|---|---|
| 🔴 심각 | 스펙 불일치, 빌드 실패, 보안 | 즉시 재작업 지시 |
| 🟡 수정필요 | dead code, 과잉설계 | 사용자 합의 후 처리 |
| 🟢 다음 WO | 동작에 영향 없음 | 기록만 |
| ⚪ OK | 스펙과 정확히 일치 | 통과 |

---

## 안티패턴

- ❌ "워커가 완료했다고 하니 OK" — 메타데이터 신뢰 금지
- ❌ "빌드 통과했으니 OK" — 필드 불일치는 빌드로 잡히지 않는다
- ❌ 발견 사항을 구두로만 전달 — gate review 파일로 박제
