# WO-015: aidy-android self-hosted runner 전환 (Android SDK 통합)

**담당**: android (runner 등록은 architect 선행, workflow 변경은 워커)
**우선순위**: P0-긴급 (WO-012 Gate 2 unblock — billing 독립성)
**상태**: done
**의존**: 없음 (WO-014와 병렬 진행 가능, MBA 디스크 여유 20GB+ 확인)
**Related**: ADR-009, ADR-010 (초안), WO-012, WO-014

## 목표

aidy-android GitHub Actions를 사용자 MBA의 self-hosted runner + Android SDK 위에서 돌려 GitHub billing 의존성을 제거한다. WO-014 패턴을 Android SDK 환경으로 확장.

## 배경

- 2026-04-17: GitHub Actions billing 차단으로 WO-012 green run 확보 실패 (server/android 동일)
- 빌링 복구 불가 → self-hosted 통합으로 우회 결정
- Android는 SDK 용량이 커서 (~15GB) 별도 WO로 분리 (WO-014와 병렬이지만 디스크 영향 큼)

## 전제

- 사용자 MBA (macOS 26.3.1, Apple Silicon)에 iOS runner + WO-014 server runner 가동 중 (또는 동시 세팅)
- macOS 26 + Apple Silicon에서 Android SDK (command-line tools + platform-tools + platforms) 정상 동작
- 최종 라벨: `self-hosted, macOS, ARM64, aidy-android`

## 구현 요구사항

### 1. Architect 선행 작업 — Runner 등록 ✅ 완료 (2026-04-17)

- Runner: `jominhoui-mba-android`
- Labels: `self-hosted, macOS, ARM64, aidy-android`
- 디렉토리: `~/actions-runner-android/`
- Service: launchd user agent `actions.runner.Mino777-aidy-android.jominhoui-mba-android` (started)
- Status: online / busy=false

```bash
gh api /repos/Mino777/aidy-android/actions/runners --jq '.runners[] | {name,status,busy}'
# → {"busy":false,"name":"jominhoui-mba-android","status":"online"}
```

### 2. Android SDK 설치 (MBA 1회 세팅)

✅ **Architect 완료 (2026-04-17)**: `brew install --cask android-commandlinetools` → 실제 경로 `/opt/homebrew/share/android-commandlinetools` (brew cask 기본 경로). spec 원안 `$HOME/Library/Android/sdk` 와 다름에 주의.

설치된 컴포넌트:
```
build-tools;35.0.0   | 35.0.0
platform-tools       | 37.0.0
platforms;android-35 | 2
```

SDK licenses: 수락 완료 (`yes | sdkmanager --licenses`).

⚠️ **Android Studio 설치 비추천**: GUI 불필요, command-line tools 만으로 `./gradlew testDebugUnitTest` 동작.

### 3. JDK 17 공유 (WO-014 와 동일 JDK)

Android Gradle Plugin 8.x 기준 JDK 17 필수. WO-014 에서 세팅한 JDK 17 재사용:
- `JAVA_HOME=/opt/homebrew/opt/openjdk@17`
- 별도 설치 불필요

### 4. 워커 작업 — workflow `runs-on` 전환

대상: `aidy-android/.github/workflows/test.yml` + `ai-review.yml` (있으면)

```yaml
# before
runs-on: ubuntu-latest

# after (WO-015 단독 완료 시점)
runs-on: [self-hosted, macOS, ARM64, aidy-android]
```

ℹ️ **runner `.env` 에 이미 주입됨 (Architect 세팅)**:
```
JAVA_HOME=/opt/homebrew/opt/openjdk@17
ANDROID_HOME=/opt/homebrew/share/android-commandlinetools
ANDROID_SDK_ROOT=/opt/homebrew/share/android-commandlinetools
PATH=<openjdk@17>:<cmdline-tools>:<platform-tools>:<brew>:...
```

→ workflow 에 별도 `env:` 블록 불필요. 다만 명시적으로 두고 싶으면 `env:` 에 동일 값 선언 가능 (idempotent).

WO-016 fallback 전환은 별도 WO.

### 5. setup-android step 처리

기존 workflow 에 `android-actions/setup-android` 등이 있으면:
- self-hosted 에 이미 SDK 있으므로 **제거 권장** (매 run 다운로드 방지)
- 또는 idempotent 확인 후 유지

### 6. Android SDK 라이선스 수락 검증

CI 첫 run 에서 "SDK licenses not accepted" 실패 가능 → `sdkmanager --licenses` 사전 수락했는지 확인. workflow 에도 보호 step:

```yaml
- name: Verify SDK licenses
  run: |
    yes | sdkmanager --licenses >/dev/null 2>&1 || true
    echo "$ANDROID_HOME"
    sdkmanager --list_installed | head -20
```

## 검증 기준

- [ ] Runner `jominhoui-mba-android` online
- [ ] test.yml 1회 green run (billing 무관)
- [ ] `./gradlew testDebugUnitTest` 로컬 결과와 동일 test count 보고
- [ ] `./gradlew assembleDebug` 성공 (SDK 의존 확인)
- [ ] runner 로그에 SDK licenses/missing component 에러 0건
- [ ] 디스크 사용량 보고 (~/Library/Android/sdk, ~/.gradle/caches, _work)

## 완료 보고

`inbox/android-WO-015-done.md`
- runner 등록 정보
- Android SDK 버전/경로 (sdkmanager --list_installed 출력)
- workflow 변경 커밋 SHA
- green run URL + duration
- 디스크 사용량 변화 (MBA df 전후)
- setup-android step 처리 결과

## 리스크

- **디스크 포화**: Android SDK 15GB + .gradle 5GB+ + _work 누적 → iOS Xcode 30GB 와 합치면 50GB+. MBA 용량 확인 필수. 월 1회 `./gradlew --stop && rm -rf ~/.gradle/caches/build-cache-*` 가이드
- **AGP/SDK 버전 드리프트**: 로컬에서 업데이트하면 CI 영향. ADR-010 운영 섹션에 "Android SDK 업그레이드는 별도 WO 로 처리" 규칙
- **emulator 사용 시**: instrumented test (`connectedCheck`) 는 self-hosted MBA 에서 emulator 필요 → 현재 WO 범위 외 (unit test 만 타겟)
- **동시 실행 경합**: iOS + server + android runner 3개 동시 busy 시 MBA 리소스 고갈 가능. 동시성 모니터링 가이드 ADR-010 에 포함

## 참고

- WO-014: JDK 17 세팅, Gradle 캐시, JAVA_HOME export 패턴 공유
- ADR-009: iOS self-hosted 성공 패턴
- [Android cmdline-tools docs](https://developer.android.com/tools/sdkmanager) — WebFetch 금지 시 skip
