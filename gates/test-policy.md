# Aidy — 테스트 정책 (Universal)

> **의도**: 모든 변경은 **실행되는 테스트**로 검증된다. "컴파일만 됨", "빌드만 성공" 은 증거가 아니다.
> 각 워커는 스스로 테스트 실행 결과 (숫자) 를 보고해야 하며, Architect는 Gate에서 재검증한다.

본 문서는 3 영역 공통 규칙이다. 영역별 상세는:
- [test-policy-server.md](./test-policy-server.md) — Kotlin/Spring Boot
- [test-policy-ios.md](./test-policy-ios.md) — Swift/TCA
- [test-policy-android.md](./test-policy-android.md) — Kotlin/Compose/MVVM

---

## 핵심 원칙

### P1. 테스트 없는 머지 없음
- 새 public 함수/서비스/Reducer/ViewModel 메서드 → **단위 테스트 필수**
- 버그 수정 → 회귀 테스트 먼저 (red) → 코드 수정 (green)
- 리팩터 → 기존 테스트 무변경 + 그대로 PASS 보존

### P2. 실행 증거 제출
- 워커는 커밋 전 실제 테스트를 실행하고, 결과 숫자를 커밋 메시지 또는 `inbox/`에 남긴다
- 예: `테스트: 113 tests · 0 failures · 0 errors`
- 빌드 성공만으로 "테스트 통과" 라고 주장 금지 — `tuist test`, `./gradlew test`, 등은 실제 실행 로그를 봐야 함

### P3. 금지 패턴
- **테스트 비활성화 (@Disabled, .skipped = "YES") 금지** — 예외: 외부 의존(실제 AI API) 필요 시, 반드시 이유 주석
- **assertThrows 없이 예외 경로 테스트 생략 금지**
- **커버리지 위장 금지** — `verify()` 없는 stub-only 테스트 금지
- **프로덕션 코드 경로 하나라도 타지 않는 "가짜 통과" 테스트 금지** (예: `assertTrue(true)`)

### P4. 외부 의존성 격리
- AI API (Anthropic) → 반드시 Mock/Stub. 실호출 테스트 금지.
- DB → 영역별 규정 따름 (H2/인메모리/테스트 전용 스키마)
- 네트워크 → MockWebServer / URLSession stub / mock HTTP

### P5. 테스트 네이밍
- 형식: `<대상>_<동작>_<조건>` 또는 한국어 `~할 때 ~한다`
- 예: `deleteMemory_rollsBack_whenApiFails`, `파싱 실패 시 AiReply fallback 반환`

### P6. Flaky 테스트 금지
- 시간/순서/스레드 의존 테스트 발견 시 즉시 수정 (스킵 금지)
- 재시도로 가리기 금지

---

## 워커 필수 루틴

모든 워커는 WO 처리 시 **다음 순서를 반드시 따른다**:

```
1. WO 읽기
2. specs/api-contract.md + gates/test-policy-<영역>.md 읽기
3. 구현 전 또는 병행 — 테스트 작성 (최소한의 happy path + 1 failure case)
4. 구현
5. ./gradlew test / xcodebuild test / ./gradlew testDebugUnitTest 실행
6. 실행 결과 숫자 확인 (e.g., "42 tests passed")
7. inbox/worker-status.json 업데이트 + 결과 기록
8. 커밋 메시지에 테스트 통계 포함
9. PR 없이 바로 커밋 (본 프로젝트 정책)
```

---

## Gate 검증 (Architect)

### Gate 1 (스펙 준수) — 테스트 관점
- [ ] 새 API 엔드포인트/기능에 대응 테스트 파일 존재
- [ ] Happy path + 최소 1 error/edge case 테스트
- [ ] 테스트 파일이 실제로 실행됐는지 확인 (커밋 메시지 통계 또는 직접 재실행)
- [ ] 기존 테스트 비활성화 (@Disabled, skipped = "YES") 없음

### Gate 2 (통합) — 테스트 관점
- [ ] 전체 테스트 스위트 PASS
- [ ] Warning as error가 있으면 해결
- [ ] 테스트 실행 시간 합리적 (서버 < 1분, 클라 < 3분 목표)
- [ ] Code coverage 기준선 유지 (영역별 상세)

---

## 금지 탈출구

다음 문구는 정책 위반이다. 발견 시 Gate FAIL:
- "테스트는 나중에 추가하겠습니다"
- "빌드가 통과했으니 OK"
- "tuist build 성공 = 테스트 통과"
- "기존 테스트가 있으니 새 테스트는 생략"
- "이 변경은 UI만이라 테스트 불필요" — UI도 ViewModel/Feature 로직으로 분리해 테스트 가능

---

## 참고 문서
- [security-hardening-checklist.md](./security-hardening-checklist.md) — 보안 체크리스트
- [gate-checklist.md](./gate-checklist.md) — Gate 기본 체크리스트
