# /gate-1 — 스펙 준수 검증 (워커 PR/커밋 직후)

워커의 구현이 API Contract와 정확히 일치하는지 **line-by-line 검증**한다.
메타데이터(커밋 메시지, PR 설명)를 신뢰하지 않는다. 코드만 본다.

## 입력

사용자가 다음 중 하나를 명시:
- 워커 이름 (예: `server`, `ios`, `android`)
- WO 번호 (예: `001`)
- 또는 자유 입력

입력 없으면 첫 질문: *"어느 워커의 어떤 WO를 검증할까요?"*

---

## Phase 1 — 변경 범위 수집

```bash
# 워커 프로젝트로 이동하여 최근 변경 확인
cd ~/Develop/aidy-<worker>
git log --oneline -10
git diff HEAD~1 --stat
git diff HEAD~1
```

---

## Phase 2 — API Contract 대조

`~/Develop/aidy-architect/specs/api-contract.md`를 읽고, 워커의 실제 코드와 **필드별** 대조:

### 서버 (Spring Boot + Kotlin)
```bash
# Controller 엔드포인트 매핑
grep -rn "@GetMapping\|@PostMapping\|@DeleteMapping\|@PutMapping" src/
# DTO 필드
grep -rn "val \|var " src/main/kotlin/**/dto/
# Error code
grep -rn "ErrorCode\|error.*code\|EMPTY_MESSAGE\|MEMORY_NOT_FOUND" src/
```

### iOS (TCA + SwiftUI)
```bash
# API 엔드포인트 정의
grep -rn "endpoint\|url\|path" Sources/**/API*
# Model 필드
grep -rn "struct.*Response\|struct.*Request" Sources/**/Model*
```

### Android (Jetpack Compose)
```bash
# Retrofit 엔드포인트
grep -rn "@GET\|@POST\|@DELETE" src/**/api/
# Data class 필드
grep -rn "data class" src/**/model/
```

---

## Phase 3 — 체크리스트 실행

`~/Develop/aidy-architect/gates/gate-checklist.md`의 Gate 1 항목을 하나씩 검증:

| 항목 | 검증 방법 |
|------|----------|
| 엔드포인트 URL | Controller 매핑 vs contract |
| HTTP method | 동일 |
| Request body | DTO 필드명+타입 vs contract |
| Response body | DTO 필드명+타입 vs contract |
| Error code | 스펙 Error Codes 표 vs 실제 코드 |
| HTTP status | 동일 |
| 네이밍 | conventions.md 준수 |
| 보안 | default secret 없음, API 키 하드코딩 없음 |

---

## Phase 4 — 판정 + 리뷰 문서 생성

```markdown
# Gate 1 Review: WO-{번호} ({워커})

**일시**: YYYY-MM-DD
**검증자**: Architect

## 결과: PASS / CONDITIONAL / FAIL

## 엔드포인트별 검증

| 엔드포인트 | 상태 | 불일치 상세 |
|-----------|------|-----------|
| POST /api/chat | ✅/❌ | ... |
| ... | ... | ... |

## 보안 체크
- [ ] default secret 없음
- [ ] 에러 메시지에 내부 정보 노출 없음
- [ ] API 키 하드코딩 없음

## 발견 사항
- 🔴 심각: ...
- 🟡 수정필요: ...
- 🟢 다음 WO: ...
- ⚪ OK: ...

## 다음 액션
- [ ] ...
```

리뷰 문서를 `gates/reviews/gate-1-WO-{번호}-{워커}.md`에 저장.

---

## 안티패턴

- ❌ 커밋 메시지를 근거로 인용 — 코드만 본다
- ❌ "빌드 통과했으니 OK" — 필드 불일치는 빌드로 잡히지 않는다
- ❌ 발견 사항을 구두로만 전달 — 반드시 파일로 박제
- ❌ CONDITIONAL을 남발 — 스펙 불일치는 무조건 FAIL
