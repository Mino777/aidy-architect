# autoceo s31 세션 교훈 (2026-04-21)

## Agent Teams 첫 실전 결과
- **서버**: Agent Teams로 태스크 9개 분해 → 병렬 작업 확인
  - Entity/Migration/Repo 병렬 진행, Service/Controller 순차
  - 코드 생성은 빨랐으나 Build+Test 단계에서 40분 소요 (H2 호환 이슈)
- **iOS**: Agent Teams 태스크 분해 사용 (Feature/View/Tests 병렬)
- **Android**: 빠른 완료 (5분대) — Agent Teams 효과 체감

## 서버 빌드 병목 (40분)
- R3에서 H2 테스트 호환성 문제 (Flyway migration + H2 DDL 차이)
- `./gradlew clean test`가 Swap 48% 환경에서 매우 느림
- 워커가 `--no-build-cache`, `--rerun-tasks` 등 다양한 옵션 시도
- **최종 해결**: `ddl-auto: create` 설정으로 H2 스키마 자동 생성
- **교훈**: `gradlew clean` 없이 `gradlew test`만 실행 권장 (증분 빌드)

## auto-gate1.sh 실전 미확인
- 서버 워커가 커밋 시 auto-gate1 hook이 실행됐을 것이나, 로그 미확인
- **교훈**: 다음 세션에서 hook 실행 로그 확인 필요

## 성과
- 5라운드, 4피처 (v3.9~v4.2), WO 12개 완료
- 서버 6커밋 (969 tests), iOS 3커밋 (616 tests), Android 4커밋 (838 tests)
- Gate-2 PASS: 빌드+테스트 전원 통과
- iOS 크래시 0회

## Advisor 자문 요청 0건
- 워커들이 자율적으로 판단하여 완료 (자문 프로토콜 미사용)
- **교훈**: 단순 CRUD 피처에선 자문 필요성 낮음. 아키텍처 변경 시 효과 기대
