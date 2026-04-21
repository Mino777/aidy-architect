# s32 회고 — Onboarding + Dashboard + Media + Smoke Test + 인프라 대폭 개선

**일시**: 2026-04-22
**autoceo**: 2회 실행 (R1~R2 × 2 사이클)
**WO 완료**: WO-145~156 (12건)

## 이번에 한 것

### 사이클 1: 피처 3개 (v4.3~v4.5)
- **Onboarding Progress (v4.3)**: 첫 사용자 튜토리얼 5단계 추적
- **Home Dashboard (v4.4)**: 메인 화면 통합 브리핑 (다이제스트+추천+건강점수)
- **Memory Media (v4.5)**: 메모리 이미지 첨부 (multipart, 3장 제한)

### 사이클 2: 테스트 인프라 (v4.6 + ingest)
- **Test Account (v4.6)**: UI 테스트 전용 어드민 계정 서버 시딩
- **Robot Pattern**: iOS/Android 화면별 Robot 클래스 5개씩
- **Smoke Test**: 핵심 유저 플로우 E2E (로그인→채팅→기억→인물)

### 인프라 개선 (이번 세션)
- `build_prompt` 구조화 마크다운 반영
- `watch-workers` 개별 알림 + 1800s timeout + bash3 호환 + 오탐 방지
- `restart-workers` PGID kill + pane 완전 정리
- `preflight` memory_pressure/compressor/고아프로세스 체크
- 워커 중간 보고 + 병렬 Gate-1 + compound 강제 호출

## 잘된 것
- 3-way 병렬 dispatch로 피처 3개를 1라운드에 완료 (서버+클라 동시)
- watch-workers 개별 알림이 동작 — Android/iOS 순차 완료 확인 가능
- ingest(뱅크샐러드) → WO 발행 → 즉시 구현 파이프라인 잘 동작

## 아쉬운 것
- **compound를 2회 autoceo 모두 스킵했다.** 프로토콜에 "자동 실행"이라 쓰여 있었지만, 최종 리포트 후 바로 다음 작업으로 넘어감. 유저가 지적해서야 인지. → 강제 호출로 수정했지만, 내 판단 순서에서 compound를 "선택적"으로 취급한 게 근본 원인.
- **watch-workers bash3 호환 미확인.** `local -A` 작성 후 테스트 없이 배포. macOS = bash 3이라는 사실을 매번 잊음.
- **restart-workers 즉시 종료 이슈 재발.** 이전 세션에서 "꼭 잡고 넘어가라" 지시받았는데 또 재발. 메모리에 기록만 하고 코드 수정을 안 한 것이 원인 → 이번에 코드 수정으로 해결.
- **서버 Mockito any() null 이슈 반복.** Kotlin non-null + Mockito any()=null 조합. 매번 같은 패턴으로 실패 → 워커가 자체 해결하지만 시간 소모.

## 다음에 적용할 것
- compound는 autoceo 최종 리포트 직후 Skill tool로 강제 호출 (적용 완료)
- bash 스크립트 변경 시 `bash --version` 체크하거나 bash3 문법만 사용
- 피드백 메모리는 행동 강제력 없음 → 반복 이슈는 코드/CLAUDE.md에 직접 반영

## Compound Assets
- `gates/reviews/gate1-s32-r2.md` — v4.3~v4.5 Gate-1 리뷰
- `gates/reviews/gate1-s32-r3.md` — Smoke Test Gate-1 리뷰
- Robot Pattern 코드: iOS `Projects/App/UITests/Robots/`, Android `app/src/androidTest/java/com/mino/aidy/robots/`

## 프로세스 개선 (이번 스프린트)
| 재료 | 개선 | 파일 |
|------|------|------|
| watch-workers 10분 timeout 노이즈 | 기본 1800s + 개별 알림 | architect-cli.sh |
| restart-workers 즉시 종료 재발 | PGID kill + pane 정리 | architect-cli.sh |
| bash3 `local -A` 에러 | 변수명 방식으로 교체 | architect-cli.sh |
| preflight swap만 체크 | compressor/memory_pressure/고아 추가 | architect-cli.sh |
| compound 미실행 | autoceo에 BLOCKING REQUIREMENT 추가 | autoceo.md |
| 워커 진행률 블라인드 | 중간 보고 + 병렬 Gate-1 | architect-cli.sh + autoceo.md |

## For AI Agents
다음 세션에서 이 회고를 입력으로 받을 때:
- compound는 선택이 아니라 의무. autoceo 최종 리포트 후 반드시 Skill tool 호출
- bash 스크립트는 bash3 문법만 사용 (associative array 금지)
- feedback_ 메모리는 참고용. 행동 변경이 필요하면 코드나 CLAUDE.md를 수정해야 효과
- Mockito Kotlin any() null 이슈: `anyNonNull()` 또는 `any(Type::class.java)` 사용
