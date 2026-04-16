# /gate-2 — 통합 검증 (머지 직전)

Gate 1 통과한 워커의 코드를 **빌드 + 테스트 + 크로스 프로젝트 호환성** 관점에서 검증.
CI에 위임하지 않는다. 로컬에서 직접 확인.

## 전제

- Gate 1이 **PASS**인 WO만 Gate 2 진입 가능
- `gates/reviews/gate-1-WO-{번호}-{워커}.md`가 존재해야 함

---

## Phase 0 — CI 상태 자동 수집 (P3-9)

머지 직전, 3개 워커 repo의 GitHub Actions 결과부터 본다. 빨간불이면 그 자리에서 FAIL.

```bash
cd ~/Develop/aidy-architect
./ci-status.sh --watch --limit 5      # 실패 워크플로 한 줄 보고
./ci-status.sh --since 24h --limit 10 # 최근 24h 컨텍스트
```

`--watch` 가 비어 있어야 Phase 1로 진행. 빨간불이 있으면 워커에게 재작업 지시.

---

## Phase 1 — 빌드 검증

### 서버
```bash
cd ~/Develop/aidy-server
docker compose up -d  # PostgreSQL
./gradlew clean build
./gradlew test
```

### iOS
```bash
cd ~/Develop/aidy-ios
tuist generate
xcodebuild -scheme Aidy -destination 'platform=iOS Simulator,name=iPhone 16' build
xcodebuild test -scheme AidyTests -destination 'platform=iOS Simulator,name=iPhone 16'
```

### Android
```bash
cd ~/Develop/aidy-android
./gradlew assembleDebug
./gradlew test
```

---

## Phase 2 — 크로스 프로젝트 호환성

서버 + 클라이언트 간 Request/Response 스키마가 **양쪽에서 동일하게 파싱**되는지 확인:

```bash
# 서버의 DTO 필드 추출
grep -rn "val \|var " ~/Develop/aidy-server/src/main/kotlin/**/dto/ | sort

# iOS의 Model 필드 추출
grep -rn "let \|var " ~/Develop/aidy-ios/Sources/**/Model* | sort

# Android의 Data class 필드 추출
grep -rn "val \|var " ~/Develop/aidy-android/src/**/model/ | sort
```

3개 프로젝트의 필드명/타입을 **교차 대조**.

---

## Phase 3 — 보안 체크리스트

`~/Develop/aidy-architect/gates/security-hardening-checklist.md` 기준으로 검증.

---

## Phase 4 — 판정 + 리뷰 문서

```markdown
# Gate 2 Review: WO-{번호} ({워커})

**일시**: YYYY-MM-DD
**검증자**: Architect
**Gate 1**: gates/reviews/gate-1-WO-{번호}-{워커}.md

## 결과: PASS / FAIL

## 빌드
- 빌드: PASS/FAIL
- 테스트: N passed, N failed
- 테스트 커버리지: (있으면)

## 크로스 프로젝트 호환성
- [ ] 서버-iOS 필드 일치
- [ ] 서버-Android 필드 일치

## 보안
- [ ] security-hardening-checklist 통과

## 다음 액션
- [ ] 머지 승인 / 재작업 지시
```

리뷰 문서를 `gates/reviews/gate-2-WO-{번호}-{워커}.md`에 저장.

---

## 머지 승인

Gate 2 PASS 시:
1. WO를 done으로 이동: `./architect-cli.sh wo-done {번호}`
2. 워커에게 머지 승인 전달
3. `/compound` 실행하여 문서화
