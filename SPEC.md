# SPEC — Aidy Architect (멀티에이전트 관제 센터)

> 이 저장소는 Aidy 프로젝트의 **설계 허브**다.
> 코드를 작성하지 않고, 아키텍처를 결정하고, 스펙을 정의하고, 워커를 관제한다.

---

## Purpose

3개 워커 프로젝트(server, iOS, Android)의 API 스펙을 단일 진실 소스로 관리하고,
Work Order 기반으로 작업을 분배하며, 검증 게이트로 품질을 보장한다.

**핵심 명제**: 스펙이 진실이고, 코드는 스펙의 구현체다. 코드가 스펙과 다르면 코드가 틀린 것이다.

---

## Core Entities

### 1. API Contract — `specs/api-contract.md`

- Aidy 전체의 **단일 진실 소스**
- 모든 엔드포인트, Request/Response 스키마, Error Code 정의
- 워커는 이 스펙과 정확히 일치하는 구현만 허용

### 2. Work Order — `work-orders/{backlog,in-progress,done}/WO-*.md`

- 워커에게 전달되는 작업 지시서
- 상태: `backlog` → `in-progress` → `done`
- 필수 필드: 담당, 우선순위, 완료 기준

### 3. Architecture Decision Record — `specs/decisions/ADR-*.md`

- 아키텍처 결정과 그 근거를 박제
- 한 번 Accepted된 ADR은 새 ADR로만 덮어씀

### 4. 검증 게이트 — `gates/`

- Gate 1 (스펙 준수): PR 생성 직후
- Gate 2 (통합 검증): 머지 직전
- 체크리스트: `gates/gate-checklist.md`

---

## Data Flow

### 작업 사이클

```
Architect                          Worker
   │                                 │
   ├── API 스펙 정의                  │
   ├── WO 발행 (/dispatch)           │
   │        ─────────────────────▶   │
   │                                 ├── WO 읽기 + 구현
   │                                 ├── PR 생성
   │   ◀─────────────────────────    │
   ├── Gate 1 검증 (/gate-1)         │
   │        ─────────────────────▶   │ (수정 필요 시)
   ├── Gate 2 검증 (/gate-2)         │
   ├── 머지 승인                      │
   └── /compound (회고 박제)          │
```

### 워커 프로젝트 맵

| 워커 | 레포 | 스택 | 빌드 명령 | 테스트 명령 |
|------|------|------|----------|------------|
| server | aidy-server | Spring Boot + Kotlin | `./gradlew clean build` | `./gradlew test` |
| ios | aidy-ios | Tuist + TCA + SwiftUI | `tuist generate && xcodebuild build` | `xcodebuild test` |
| android | aidy-android | Jetpack Compose + MVVM | `./gradlew assembleDebug` | `./gradlew testDebugUnitTest` |

---

## Acceptance Spec — 검증 가능한 품질 기준

> SDD 원칙: 코드 != 진실, Spec = 진실. 아래 기준을 통과해야 "완료"다.

### Build Gate (자동 검증)

| 기준 | 명령 | 통과 조건 |
|------|------|----------|
| Server 빌드 | `cd ~/Develop/aidy-server && ./gradlew clean build` | 에러 0, exit code 0 |
| Server 테스트 | `cd ~/Develop/aidy-server && ./gradlew test` | 전체 통과, 실행 숫자 확인 |
| iOS 빌드 | `cd ~/Develop/aidy-ios && tuist generate && xcodebuild build -workspace ... -scheme Aidy` | 에러 0 |
| iOS 테스트 | `cd ~/Develop/aidy-ios && xcodebuild test -workspace ... -scheme Aidy -destination 'platform=iOS Simulator,...'` | 전체 통과, 숫자 증거 |
| Android 빌드 | `cd ~/Develop/aidy-android && ./gradlew assembleDebug` | 에러 0 |
| Android 테스트 | `cd ~/Develop/aidy-android && ./gradlew testDebugUnitTest` | 전체 통과, 숫자 증거 |
| CI 상태 | `./ci-status.sh` | 모든 워커 green |

> **"테스트 통과"의 정의**: `no tests to run` / `skipped`는 FAIL. 반드시 실행 숫자(`NN tests passed`)가 존재해야 한다.
> 근거: `docs/solutions/2026-04-16-ios-tests-never-ran.md`

### Content Gate (수동/AI 검증)

| 기준 | 검증 방법 | 통과 조건 |
|------|----------|----------|
| API Contract 일치 | `/gate-1` (코드 line-by-line 대조) | 엔드포인트, 스키마, 에러코드 100% 일치 |
| 컨벤션 준수 | `specs/conventions.md` 기준 대조 | 네이밍, 브랜치, 커밋 메시지 규칙 준수 |
| WO 완료 기준 | WO 파일의 체크리스트 | 모든 항목 체크 |
| 보안 체크리스트 | `gates/security-hardening-checklist.md` | 환경변수 default 없음, 키 하드코딩 없음, 내부 정보 노출 없음 |
| 크로스 프로젝트 호환 | `/gate-2` (서버-클라이언트 필드 대조) | Request/Response 양쪽 파싱 일치 |
| 테스트 실행 증거 | 커밋 메시지 또는 inbox/ 파일 | 숫자 포함 (워커 자체보고만으로 부족) |

> **메타데이터 불신 원칙**: 커밋 메시지, PR 설명은 참고만. 코드를 직접 읽어서 검증한다.

### Promotion Gate (솔루션/ADR 승격 시)

| 기준 | 검증 방법 | 통과 조건 |
|------|----------|----------|
| 삽질 기록 박제 | `/compound` Phase 1 (회고) | 문제-원인-해결 3단 구조 작성 |
| 솔루션 문서화 | `docs/solutions/` 확인 | 재현 가능한 해결책 명시 |
| ADR 필요성 | 아키텍처 변경 여부 판단 | 변경 시 `specs/decisions/` ADR 작성 |
| 지식 전이 | ai-study 허브 동기화 여부 | 범용 패턴이면 허브에 이슈/엔트리 생성 |
| CLAUDE.md 반영 | `/compound` Phase 3 | 워커 가이드에 새 규칙 반영 (캐시 보존 원칙: 세션 중 직접 수정 X) |

---

## 판정 기준

| 결과 | 조건 | 후속 |
|------|------|------|
| **PASS** | 3개 Gate 모두 통과 | WO → done, 머지 승인 |
| **CONDITIONAL** | Build/Content 통과, Promotion 일부 미달 | 머지 후 다음 /compound에서 보완 |
| **FAIL** | Build 또는 Content Gate 실패 | 재작업 → 워커에게 수정 지시 |

---

## 현재 상태 (2026-04-19)

| 항목 | 값 |
|------|-----|
| API 버전 | v1.5.0 |
| 완료된 WO | 62개 |
| 진행 중 WO | 0개 |
| ADR | 11개 (001~011) + BACKLOG |
| 워커 | 3개 (server, ios, android) |
| 슬래시 커맨드 | 10개 |
