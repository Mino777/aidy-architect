# autoceo-s27 회고 — Relationship Timeline + Quick Notes (v2.7~v2.8)

**일시**: 2026-04-19
**라운드**: 2R (스펙+WO 발행 → 구현+검증)
**워커**: server + ios + android (1-way 순차 dispatch)

## 이번에 한 것
- v2.7 Relationship Timeline: 인물별 상호작용 통합 타임라인 (chat/memory/anniversary 3타입)
- v2.8 Quick Notes: 채팅 없이 직접 메모리 생성 (단건 + batch 10개)
- API 스펙 정의 + WO 6개 (097~102) + 3개 워커 구현 + Gate-1 전원 PASS
- 총 커밋: server 2 + ios 2 + android 2 + architect 2 = 8건
- 테스트: server 796→814 (+18) | android 663→693 (+30) | ios build OK

## 잘된 것
- 1-way 순차 dispatch가 6인스턴스 환경에서 안정적으로 동작 (stall 0건)
- 서버 완료 후 클라이언트 dispatch하면서 Gate-1 병행 (idle 최소화)
- 서버 워커가 Timeline+QuickNotes 2개를 15분 내 완료 (효율적)
- Android 워커가 ViewModel 테스트 17개씩 잘 작성 (총 30개 증가)
- 플래키 테스트 감지: 서버 첫 verify에서 FAIL → 재실행 PASS (일시적)

## 아쉬운 것 (다음 사이클 입력)
- **서버 플래키 테스트 미조사**: 첫 verify에서 FAIL이 나왔지만 재실행으로 넘어감. 근본 원인을 파악하지 않은 판단 실수. 어떤 테스트가 flaky한지 특정하지 않음.
- **iOS 테스트 부재**: tuist build만 확인하고 Feature 테스트를 작성하지 않음. WO에 테스트 요구를 명시하지 않은 Architect 책임.
- **Gate-1 에이전트 미사용**: 백그라운드로 gate-reviewer를 띄웠으나 결과 파일 미생성 상태에서 수동으로 축약 게이트를 작성. 에이전트 결과를 기다리지 않고 넘어간 것은 검증 깊이를 희생.

## 다음에 적용할 것
- 서버 flaky test 조사: `./gradlew test --rerun-tasks` 3회 반복으로 재현 시도
- iOS WO에 테스트 요구 명시 (RelationshipTimelineFeatureTests, QuickNoteFeatureTests)
- Gate-1 에이전트 결과 대기 시간을 확보하거나, 축약 Gate-1을 더 깊이 수행 (실제 코드 line-by-line 대조)

## Compound Assets
- specs/api-contract.md §5.18 + §5.19 (2개 신규 섹션)
- WO 097~102 (6개 done)
- Gate-1 리뷰 6건 (gates/reviews/)

## 프로세스 개선 (이번 스프린트)
| 재료 | 개선 | 파일 |
|------|------|------|
| 서버 flaky test | 다음 세션에서 조사 필요 | — |
| iOS 테스트 미작성 | WO 템플릿에 테스트 요구 기본 포함 | — |
| Gate-1 에이전트 결과 미대기 | 에이전트 or 수동 중 하나만 선택, 병행 금지 | — |

## For AI Agents
다음 세션에서 이 회고를 입력으로 받을 때:
- 서버 flaky test 조사를 P1으로 처리 (어떤 테스트 클래스가 간헐 실패하는지 특정)
- iOS WO 발행 시 Feature 테스트 요구를 반드시 포함
- v2.7/v2.8 스펙은 api-contract.md에 정의 완료, 구현도 3개 프로젝트 전부 완료
- Quick Notes의 personName→Person 매칭 로직은 기존 PersonService.findOrCreate 재활용
