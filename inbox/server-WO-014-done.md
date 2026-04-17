# WO-014 완료 보고 (server) — WO-012 Gate 2 동시 복구

**시각**: 2026-04-16
**브랜치**: `wo-012-actions-node24` (squash-merged → main as `0217c05`)
**상태**: 모든 검증 PASS. Gate 2 unblocked.

---

## 1. Workflow 변경 요약

| 파일 | 변경 | 줄수 |
|---|---|---|
| `.github/workflows/test.yml` | `runs-on` 전환 + `actions/cache` 제거 | +1 / -11 |
| `.github/workflows/ai-review.yml` | `runs-on` 전환 | +1 / -1 |

**단일 의미 변경 (WO-014)**:
- `runs-on: ubuntu-latest` → `runs-on: [self-hosted, macOS, ARM64, aidy-server]` (양쪽 파일)
- `actions/cache@v5` step 제거 (test.yml 10줄 삭제) — WO-014 §4 근거

**동반 커밋 (WO-012 이전 commit 포함)**:
- `e5e4a6d` WO-012: Node.js 24 호환 bump (checkout v4→v6, setup-java v4→v5, github-script v7→v8, cache v4→v5, upload-artifact v4→v7)
- `18878d8` WO-014: self-hosted 전환
- `b5b6cff` WO-014: actions/cache 제거 (Post Cache Gradle 행양 대응)

→ Squash merge 결과 main: `0217c05 WO-014: self-hosted macOS runner 전환 + WO-012 Gate 2 복구 (#1)`

---

## 2. Green Run 증거

| Workflow | Run ID | URL | 결과 | Duration |
|---|---|---|---|---|
| Auto Merge to main | 24521716347 | https://github.com/Mino777/aidy-server/actions/runs/24521716347 | ✅ SUCCESS | ~2m 56s (16:27:01→16:29:57) |
| Test | 24521716355 | https://github.com/Mino777/aidy-server/actions/runs/24521716355 | ✅ SUCCESS | ~4m 29s (16:27:01→16:31:30) |

Auto Merge 는 전 단계 통과(Test Gate → Squash Merge → Reset branch to main) — 이 보고의 closure 동작.

---

## 3. 테스트 결과 (JUnit XML 집계)

```
./gradlew test --no-daemon
BUILD SUCCESSFUL in 42s
```

Test 24521716355 의 `test-reports` artifact 다운로드 후 집계:
- **207 tests total · 0 failures · 0 errors · 0 skipped**
- 모든 24개 testsuite 파일에서 `failures="0" errors="0" skipped="0"`

JDK 사용: `Java_Temurin-Hotspot_jdk/21.0.10-7.0.LTS/arm64` (setup-java@v5 가 `$RUNNER_TOOL_CACHE` 에 자동 설치)

---

## 4. Self-hosted Runner 검증

```json
// 실행 중 확인
{"busy":true,"labels":["self-hosted","macOS","ARM64","aidy-server"],"name":"jominhoui-mba-server","status":"online"}
// 완료 후
{"busy":false,"name":"jominhoui-mba-server","status":"online"}
```

runner pickup 정상. iOS runner 와 label 분리 (`aidy-server`) 작동 확인.

---

## 5. WO-012 Deprecation 0건 재확인

- Auto Merge 24521716347 전체 log grep: `node.?js 20|deprecat` → **0 matches**
- Test 24521716355 전체 log grep: `node.?js 20|deprecat` → **0 matches**

Node.js 24 호환 bump(WO-012) + self-hosted runner 조합에서 경고 없이 green.

---

## 6. 특이사항 / 운영 메모

### setup-java 처리 — **유지 (멱등 확인)**
- WO-014 §3 가이드대로 보수적 유지.
- 첫 run 에서 `setup-java@v5` 가 Temurin 21 을 `$RUNNER_TOOL_CACHE` 에 설치 (21.0.10-7.0.LTS/arm64). 이후 run 은 cache hit.
- runner `.env` 의 `JAVA_HOME=/opt/homebrew/opt/openjdk@17` 는 사용되지 않음 (setup-java 가 자체 JDK 로 override). 다만 baseline 으로 남아 있어도 해롭지 않음.

### actions/cache 제거 — **계획 외 조치**
1차 실행(24521202022)에서 **실제 테스트는 모두 SUCCESS** 했으나 `Post Cache Gradle` 단계가 15분+ hanging.
- 원인 추정: GitHub Actions cache 서비스로의 upload 가 billing 제약과 맞물려 지연/중단. self-hosted macOS 에서는 `~/.gradle/caches` 가 이미 로컬 영구 → remote cache 무의미.
- 조치: run 취소 + `actions/cache@v5` 블록 제거 (WO-014 §4 명시 근거 "`actions/cache` 불필요").
- 결과: 후속 run 에서 Post-step hang 완전 소멸, Test 4m 29s 에 green.

### ConcurrentModificationException flake — **재현 없음**
1차 Auto Merge(24521200045) 에서 `ChatControllerTest.kt:285 - POST api chat stream ... 이벤트 순서 검증` 테스트 1건 failed (ConcurrentModificationException). 동일 코드로 2차 run 포함 3회 추가 실행에서 재현 안됨.
- 자체 판단: SSE 스트림 테스트의 스레드 타이밍 flake 로 추정. self-hosted macOS ARM64 의 cold daemon + iOS/server runner 동시 부하 상황에서 드물게 발생 가능.
- 범위 외(코드 수정 금지)라 그대로 두되, CLAUDE.md 의 테스트 정책 및 ADR-010 "MBA 부하 집중" 리스크 항목과 연결. 재발 3회 누적 시 test-policy-server 에 flake 등록 건의.

### 디스크 / 캐시
- `_work/_tool/` 아래 Temurin 21 설치 (~200MB)
- Gradle 캐시 `~/.gradle/caches` 로컬 유지 (크기 측정 생략)
- ADR-010 운영 규칙 §2 "월 1회 cache 정리" 에 서버 아이템 포함됨

---

## 7. Gate 체크리스트 재확인

- [x] Runner `jominhoui-mba-server` online ✓
- [x] workflow 1회 green run (test.yml + ai-review.yml 둘 다) ✓
- [x] `./gradlew test` test count 보고: **207 tests · 0 failures** ✓
- [x] deprecation 경고 0건 (양 workflow log grep 0 matches) ✓
- [x] JAVA_HOME / JDK 21 확인 (Temurin 21.0.10) ✓
- [x] 동시 busy → idle 전이 확인 ✓

---

## 8. 후속 항목 (architect 판단 필요)

1. **WO-012 PR closure**: squash merge 로 main 반영됨 (`0217c05`). WO-012 의 별도 원본 PR 이 있었다면 close 필요 (확인 안 함).
2. **Inbox 정리**: 이전 세션에서 생성한 `inbox/server-request.md` (billing 블로커 에스컬레이션) 는 ADR-010 결정으로 resolved. 삭제 또는 아카이브 요청.
3. **WO-016 (Hybrid fallback) 선행 준비**: 현 상태는 self-hosted *only*. WO-016 에서 `runs-on` 을 primary(ubuntu-latest) + fallback(self-hosted) 조합으로 다시 손볼 예정 — 이 때 cache 재도입 여부도 재검토 필요.
