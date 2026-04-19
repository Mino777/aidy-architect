# autoceo s27 회고 — v2.3~v2.6 4개 피처 풀스택 구현

**일시**: 2026-04-19
**라운드**: 10 (R1~R10)
**소요**: ~90분

## 이번에 한 것

### 피처 구현 (4개 버전)
| 버전 | 피처 | 서버 | iOS | Android |
|------|------|------|-----|---------|
| v2.3 | Anniversary Reminders | 이미 완료 | WO-086 ✅ | WO-087 ✅ |
| v2.4 | Notification Preferences | WO-088 ✅ | WO-089 ✅ | WO-090 ✅ |
| v2.5 | Relationship Nudges | WO-091 ✅ | WO-092 ✅ | WO-093 ✅ |
| v2.6 | Gift Suggestions | WO-094 ✅ | WO-095 ✅ | WO-096 ✅ |

### 수치
- 총 커밋: 서버 5 + iOS 6 + Android 7 = **18건**
- 코드 변경: 서버 2,148줄 + iOS 5,145줄 + Android 5,404줄 = **12,697줄**
- 테스트: 서버 796 + iOS 554 + Android 663 = **2,013개 테스트**
- 신규 WO: 9개 (WO-088~096)
- Gate-1: 전원 PASS (12/12)
- Build verify: server + android PASS (iOS는 워커 자체 검증)

### 품질 보강 (R6)
- 서버: +33 에지 케이스 테스트 (v2.4/v2.5)
- iOS: +24 에지 케이스 테스트 + ConversationStarter 기존 failure 수정
- Android: 에지 케이스 테스트 보강

## 잘된 것
1. **파이프라이닝 효과**: 워커 대기 중 다음 피처 스펙 + WO 작성 → idle 시간 최소화
2. **순차 dispatch 안정성**: Preflight 경고(6 instances)에도 1-way 순차로 429 없이 완주
3. **축약 Gate-1**: 엔드포인트 5개 이하 → Architect 직접 검증 → 토큰 절약
4. **서버 우선 → 클라 병렬 패턴 정착**: API 변경 시 서버 먼저, 완료 후 2-way 클라 dispatch
5. **10라운드 완주**: 피처 4개 + 품질 보강 + 빌드 검증 + compound까지 무사고

## 아쉬운 것 (다음 사이클 입력)
1. **iOS 빌드 검증 미실행**: `verify ios`를 R9에서 실행하지 않았다. xcodebuild 시뮬레이터 지연을 우려해 워커 자체 검증에 의존했지만, **내가 확인 안 한 것**이다. s20~s23 교훈 반복.
2. **iOS/Android 워커 알림 표시 불일치**: 서버만 "Architect 알림 전송 완료"를 표시. 클라이언트 워커 CLAUDE.md에 동일 규칙이 있는지 확인하지 않았다.
3. **v2.6 스펙이 단일 엔드포인트**: Gift Suggestions가 POST 1개뿐이라 얇다. 저장/즐겨찾기/히스토리 기능이 없어서 실용성이 제한적.
4. **중복 dispatch**: R7에서 서버에 동일 메시지를 2번 전송했다 (background 실행 실수). 워커가 중복을 감지했지만, 토큰 낭비.
5. **Checkpoint 태그 업데이트 안 됨**: round-2/3 태그가 이전 커밋을 가리키고 있었다. `git tag -f`가 현재 HEAD를 찍는데, 워커 프로젝트에서 커밋이 안 반영된 시점에 태그를 찍음.

## 다음에 적용할 것
1. R9 Build verify에서 **iOS도 반드시 실행** (`verify ios` 또는 최소 `tuist build`)
2. 워커 완료 알림 규칙을 iOS/Android CLAUDE.md에서 확인하고 통일
3. Gift Suggestions v2.6.1: 제안 저장 + 히스토리 기능 추가 검토
4. Checkpoint 태그는 **워커 커밋 확인 후** 찍기
5. `./architect-cli.sh send` 후 run_in_background 사용하지 않기 (중복 전송 방지)

## Compound Assets (재사용 자산)
- api-contract.md § 5.15~5.17: 3개 신규 섹션
- Gate-1 리뷰 12건: gates/reviews/
- WO 템플릿 패턴: 서버 → 클라 선행 의존성 관리

## 프로세스 개선 (이번 스프린트)
| 재료 | 개선 | 파일 |
|------|------|------|
| iOS verify 미실행 | 의무화 규칙 강화 필요 | CLAUDE.md |
| 중복 dispatch | send 후 background 사용 금지 | 피드백 메모리 |

## For AI Agents
다음 세션에서 이 회고를 입력으로 받을 때:
- v2.3~v2.6까지 구현 완료 상태. 다음 피처는 v2.7부터.
- Gift Suggestions는 POST 1개뿐 — 저장/히스토리 확장 고려
- iOS verify 반드시 실행 (tuist build 최소)
- 테스트 기준: 서버 796, iOS 554, Android 663 — 이 이상 유지
- Notification Preferences + Nudge Settings + 기존 Settings = 3개 설정 화면 존재
