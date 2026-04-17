# WO-014: aidy-server self-hosted Linux runner 전환

**담당**: server (runner 등록은 architect 선행, workflow 변경은 워커)
**우선순위**: P0-긴급 (WO-012 Gate 2 unblock — billing 독립성)
**상태**: done
**의존**: 없음 (MBA 여유 디스크/CPU만 확인)
**Related**: ADR-009, ADR-010 (초안), WO-012

## 목표

aidy-server GitHub Actions를 사용자 MBA의 self-hosted Linux runner 위에서 돌려 GitHub billing 의존성을 제거한다. iOS WO-010 패턴을 Linux 환경으로 복제.

## 배경

- 2026-04-17: GitHub Actions billing 차단으로 WO-012 green run 확보 실패
- 빌링 복구 불가 → self-hosted 통합으로 우회 결정
- ADR-009 후속 검토 항목 "aidy-server / aidy-android 도 같은 패턴 적용 여부" 에 대한 실행

## 전제

- 사용자 MBA (`jominhoui-MacBookAir`, macOS 26.3.1, Apple Silicon)에 이미 `jominhoui-mba-ios` runner 동작 중
- 동일 머신에 별도 runner 디렉토리 추가 등록 가능 (GitHub 공식 지원)
- Linux runner 미제공 환경 → **macOS runner 위에서 JVM 기반 server 빌드 실행** (Linux 바이너리 불필요, Spring Boot + Gradle은 OS-agnostic)
- 최종 라벨 예시: `self-hosted, macOS, ARM64, aidy-server` (운영체제 실제 값 따름)

## 구현 요구사항

### 1. Architect 선행 작업 — Runner 등록 + JDK 17 ✅ 완료 (2026-04-17)

- Runner: `jominhoui-mba-server`
- Labels: `self-hosted, macOS, ARM64, aidy-server`
- 디렉토리: `~/actions-runner-server/`
- Service: launchd user agent `actions.runner.Mino777-aidy-server.jominhoui-mba-server` (started)
- Status: online / busy=false
- JDK: openjdk@17 (17.0.18) 설치 → `/opt/homebrew/opt/openjdk@17`
- Runner `.env` 주입: `JAVA_HOME=/opt/homebrew/opt/openjdk@17`, `PATH` 앞에 JDK 17 배치

```bash
gh api /repos/Mino777/aidy-server/actions/runners --jq '.runners[] | {name,status,busy}'
# → {"busy":false,"name":"jominhoui-mba-server","status":"online"}
```

### 2. 워커 작업 — workflow `runs-on` 전환

대상: `aidy-server/.github/workflows/test.yml` + `ai-review.yml` (있으면)

```yaml
# before
runs-on: ubuntu-latest

# after (WO-014 단독 완료 시점)
runs-on: [self-hosted, macOS, ARM64, aidy-server]
```

⚠️ **주의**: WO-014 단독으로는 **self-hosted only** 전환. WO-016 에서 fallback 구조로 재편됨. WO-014 완료 시점에는 단일 runs-on 으로 충분.

### 3. 워커 작업 — JAVA_HOME 명시 여부

runner `.env` 에 이미 `JAVA_HOME=/opt/homebrew/opt/openjdk@17` 주입됨 → workflow `env:` 블록 **선택**. 명시적으로 두고 싶으면:

```yaml
env:
  JAVA_HOME: /opt/homebrew/opt/openjdk@17
```

Gradle 캐시는 `~/.gradle/caches` 에 로컬 영구 → `actions/cache` 불필요 (iOS 와 동일 원리).

### 4. setup-java step 제거 여부 판단

- `actions/setup-java@v5` 가 워크플로에 있으면: self-hosted 환경에서 **Oracle JDK 재설치 시도** 가능 → 제거 또는 `with: distribution: temurin` 그대로 두기 (멱등)
- 보수적으로 유지 (첫 run 에서 확인 후 제거 판단)

## 검증 기준

- [ ] Runner `jominhoui-mba-server` online (`gh api /repos/Mino777/aidy-server/actions/runners`)
- [ ] test.yml (또는 ai-review.yml) 1회 green run (billing 무관하게 실행됨)
- [ ] `./gradlew test` 로컬 결과와 동일 test count 보고
- [ ] runner 로그에 권한/환경 에러 0건 (`~/Library/Logs/actions.runner.Mino777-aidy-server.jominhoui-mba-server/Runner_*.log`)
- [ ] 동시 job 시나리오 점검: iOS runner busy 중에 server runner 는 독립 실행되는가 확인

## 완료 보고

`inbox/server-WO-014-done.md`
- runner 등록 정보 (name, labels, online)
- workflow 변경 커밋 SHA
- green run URL + duration
- JDK 셋업 결과 (JAVA_HOME 경로, 버전 출력)
- 특이사항 (setup-java step 처리, Gradle 캐시 히트율 추정)

## 리스크

- **MBA 동시 부하**: iOS runner 와 server runner 가 동시 busy 일 때 CPU/메모리 경합. Spring Boot 테스트는 메모리 집약 → 현장 모니터링 필요
- **JAVA_HOME 드리프트**: 사용자가 Mac 환경 JDK 를 바꾸면 CI 영향. ADR-010 에 "self-hosted runner 의존 Mac 환경은 변경 시 CI 재검증" 규칙 기록
- **디스크 포화**: Gradle 캐시/Docker 볼륨 누적. 월 1회 `rm -rf ~/.gradle/caches/build-cache-*` 또는 `docker system prune` 가이드 ADR-010 운영 섹션에 포함

## 참고

- ADR-009: iOS self-hosted 전환의 성공 사례 (timeline, 트레이드오프)
- WO-010: 구현 디테일 참조 (runner 등록 명령어 패턴 동일)
