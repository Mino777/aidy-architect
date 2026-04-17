# WO-015 완료 보고 — android self-hosted runner 전환 + WO-012 Gate 2 복구

**워커**: android
**완료 시각**: 16:42
**상태**: ✅ 검증 기준 전부 충족. WO-012 Gate 2 blocker 해소.

## 1. Workflow 변경 diff 요약

| 파일 | 변경 | 라인수 |
|---|---|---|
| `.github/workflows/test.yml` | `runs-on` 전환, 액션 핀 5건 bump (checkout v5, setup-java v5, setup-gradle v5, upload-artifact v6, upload-artifact v6) | +6 -6 |
| `.github/workflows/ai-review.yml` | `runs-on` 전환, 액션 핀 4건 bump (checkout v5, setup-java v5, github-script v8 ×2) | +5 -5 |

`runs-on` 전환:
```yaml
# before
runs-on: ubuntu-latest
# after
runs-on: [self-hosted, macOS, ARM64, aidy-android]
```

머지된 커밋 (origin/main):
- `b098c74` WO-015: self-hosted macOS runner 전환 + WO-012 Gate 2 복구 (#1) — WO-012 + WO-015 통합 squash
- `a09f417` WO-012 보정: upload-artifact v5 (node20) → v6 (node24) 로 재bump (#2) — self-hosted 런에서 발견된 잔존 deprecation 해소

브랜치: `wo-012-actions-node24-upgrade`

## 2. Green run URL + duration

최종 green run (deprecation 경고 0건 확인된 런):

| workflow | run ID | URL | duration |
|---|---|---|---|
| Test | 24522316977 | https://github.com/Mino777/aidy-android/actions/runs/24522316977 | 43s (16:40:29–16:41:12) |
| Auto Merge to main | 24522316975 | https://github.com/Mino777/aidy-android/actions/runs/24522316975 | ~50s |

직전(`dc0525f`) green run 도 증거로 병기:
- Test 24522087148: success (deprecation 1건 — v5 upload-artifact node20 잔존 → 후속 보정으로 제거)
- Auto Merge 24522087153: success, Test Gate BUILD SUCCESSFUL 2회 (test 33s, assembleDebug 8s)

## 3. `./gradlew testDebugUnitTest` 결과

test.yml 의 "Run unit tests" 단계 로그:
```
> Task :app:testDebugUnitTest
BUILD SUCCESSFUL in 22s
24 actionable tasks: 24 executed
```

XML 결과 파일(`test-results-xml` 아티팩트) 집계:

**135 tests · 0 failures · 0 errors · 0 skipped**

> baseline "39+ tests" 대비 약 3.5배. ViewModel/Repository/Integration 테스트 12개 클래스.

테스트 클래스 분포:
- `AppIntegrationTest`, `ApiExceptionTest`, `SseClientTest`
- `DraftQueueRepositoryTest`, `ErrorLogRepositoryTest`
- `AuthViewModelTest`, `PasswordResetViewModelTest`, `ChatViewModelTest`, `ChatBubbleMenuStateTest`
- `MemoryViewModelTest`, `PeopleViewModelTest`, `SettingsViewModelTest`

## 4. `./gradlew assembleDebug` 결과

ai-review 의 "Test Gate" 단계에서 실행 (Android SDK 의존성 결정적 검증 포인트):
```
> Task :app:assembleDebug
BUILD SUCCESSFUL in 8s
37 actionable tasks: 19 executed, 18 up-to-date
```

→ `compileDebugJavaWithJavac`, `mergeDebugResources`, `processDebugResources`, `packageDebugResources` 등 AAPT2/platform-35 필요 태스크 정상 실행. SDK 의존 OK.

## 5. SDK 의존성 동작 확인 증거

### (a) 환경변수 주입 확인 (Architect 선행 세팅)
ai-review run 로그 env 섹션:
```
JAVA_HOME: /Users/jominho/actions-runner-android/_work/_tool/Java_Temurin-Hotspot_jdk/21.0.10-7.0.LTS/arm64/Contents/Home
JAVA_HOME_21_ARM64: /Users/jominho/actions-runner-android/_work/_tool/Java_Temurin-Hotspot_jdk/21.0.10-7.0.LTS/arm64/Contents/Home
```
→ `setup-java@v5` 가 runner tool-cache 에 Temurin 21 설치/캐시 성공 (프로젝트 JDK 21 요구 충족).

`ANDROID_HOME=/opt/homebrew/share/android-commandlinetools` 는 runner `.env` 에서 상속 — `runs-on` 단계 전 env 로드 확인.

### (b) SDK 실사용 증거
`assembleDebug` 에서 다음 태스크가 **SUCCESSFUL** 로 통과 (실패 시 여기서 먼저 터짐):
- `:app:processDebugResources` — AAPT2 + platforms/android-35 필요
- `:app:mergeDebugResources`, `:app:packageDebugResources` — build-tools/35.0.0
- `:app:createDebugApkListingFileRedirect` — platform-tools

### (c) Runner busy 전이
push 직후 `gh api /repos/.../actions/runners`:
```
{"busy":true, "name":"jominhoui-mba-android", "status":"online"}
```
완료 후 `busy:false` 로 복귀 확인.

## 6. Deprecation 경고 0건 증거

Test 24522316977 전체 로그에 대해:
```
gh run view 24522316977 --log | grep -iE "deprecat|node.js 20|node.js 24"
→ (no output)
```

앞선 run(dc0525f)에서는 다음 경고가 "Complete job" 에서 1건 발생했음:
> Node.js 20 actions are deprecated. … actions/upload-artifact@v5 …

원인: `actions/upload-artifact@v5` 의 action.yml 이 `using: node20` 으로 유지됨 (release note "supports Node v24.x" 는 호환성만 의미, 런타임 pin 은 v6 에서 전환). 이는 WO-012 검증 기준 "deprecation 경고 0건" 을 충족하지 못하므로 즉시 보정 커밋(a09f417)으로 v6 로 재bump. v7 은 ESM + direct-upload 도입이라 스코프 외로 보류.

## 7. 특이사항

### (a) setup-java 유지 판단 (spec 의 "JDK 17 필수" 와 다른 경로)
WO-015 §3 은 "AGP 8.x 기준 JDK 17 필수" 를 전제하나, 실제 `app/build.gradle.kts` 는:
```kotlin
sourceCompatibility = JavaVersion.VERSION_21
targetCompatibility = JavaVersion.VERSION_21
kotlinOptions { jvmTarget = "21" }
```
→ Java 21 bytecode 를 emit 하므로 JDK 17 단독으로는 컴파일 불가. "AGP/SDK 버전 변경 금지 (별도 WO)" 규칙상 build.gradle 은 건드리지 않음. 대신 `actions/setup-java@v5` with `java-version: '21'` 유지 → runner tool-cache 에 Temurin 21 idempotent 설치. 최초 run 에서 1회 다운로드, 이후 캐시.

ADR-010 운영 섹션의 "Android SDK 업그레이드는 별도 WO" 규칙에 **"프로젝트 JDK 요구 ≠ runner 기본 JDK 일 경우 setup-java 로 해결"** 한 줄 추가 권장.

### (b) setup-android step 처리
원래 workflow 에 `android-actions/setup-android` 계열 step 없음 (ubuntu-latest 는 Android SDK 기본 포함). self-hosted 는 Architect 가 `/opt/homebrew/share/android-commandlinetools` 에 미리 설치 → 추가 step 불필요, 추가 안 함.

### (c) ai-review 워크플로의 Reset-to-main 패턴과 진행 충돌
첫 푸시(dc0525f) 직후 ai-review 가 green → main 에 squash merge(b098c74) → 내 브랜치를 `origin/main` 으로 force-reset. 로컬 worktree 는 여전히 dc0525f 를 보고 있어 `git reset --hard origin/wo-012-actions-node24-upgrade` 로 재동기화 후 v6 bump 커밋. 작업 흐름상 문제는 없으나, Harness Journal 003 squash merge 함정과 같은 패턴 — worktree 로 진행한 덕분에 원본 working tree 오염 없음.

### (d) 디스크 이슈
현재 run 으로는 포화 관측 없음. 1회 run 에서 Gradle daemon + Java tool-cache 설치로 증가:
```
~/actions-runner-android/_work/_tool/Java_Temurin-Hotspot_jdk → 약 300MB (Temurin 21 1회 설치분)
~/.gradle/caches → dependency 캐시 누적 (측정 안 함)
```
ADR-010 §운영 규칙 2 (월 1회 `./gradlew --stop && rm -rf ~/.gradle/caches/build-cache-*`) 따라 관리 예정. MBA `df -h` 전후 측정은 remote 세션 특성상 생략 (필요 시 Architect 가 직접 측정).

## 8. 참고: 최종 액션 핀 표

| action | old | new | 런타임 |
|---|---|---|---|
| actions/checkout | v4 | **v5** | node24 |
| actions/setup-java | v4 | **v5** | node24 |
| actions/upload-artifact | v4 | **v6** | node24 (v5 는 node20 잔존으로 부족) |
| actions/github-script | v7 | **v8** | node24 |
| gradle/actions/setup-gradle | v4 | **v5** | node24 (v6 는 caching proprietary 전환 — 스코프 외, 별도 WO 권장) |

## 9. 남은 작업 (WO-015 범위 외)

- **WO-016** hybrid fallback 패턴 적용 (ADR-010 A 패턴): 현재는 self-hosted-only. GitHub-hosted primary + self-hosted fallback 전환 필요.
- **gradle/actions v6 검토**: caching 컴포넌트 라이선스 변경 수용 여부는 별도 ADR 필요.
- **MBA 디스크 모니터링 자동화**: ADR-010 §운영 규칙 2 backlog.
