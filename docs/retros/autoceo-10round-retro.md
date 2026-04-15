# autoceo 10라운드 회고 — 관계 메모리 Phase 1

**일시**: 2026-04-16
**범위**: 설계 + 구현 + 검증 풀 사이클

## 라운드별 요약

| Round | 작업 | 서버 | iOS | Android |
|-------|------|------|-----|---------|
| R1 | WO-002/003 Gate 2 → done | 빌드 ✅ | 빌드 ✅ | 빌드 ✅ |
| R2 | iOS 동기화 | — | 2커밋 | — |
| R3 | API Contract v0.2.0 | — | — | — |
| R4 | WO-006 서버 관계 메모리 | 2커밋 | — | — |
| R5 | WO-007/008 피플 탭 | — | 1커밋 | 1커밋 |
| R6 | Gate 1 검증 + 수정 | 1커밋 | 1커밋 | 1커밋 |
| R7 | Gate 2 → WO done | — | — | — |
| R8 | WO-005 AI 검증 | 1커밋 | — | — |
| R9 | CHANGELOG | — | — | — |
| R10 | Compound | — | — | — |

## 성과
- WO 6개 완료 (WO-002~008, WO-005 포함)
- 총 커밋: server 4 + iOS 4 + Android 2 = 10건
- Gate 통과: 6/6 (WO-002~008)
- 신규 테이블: 3개 (persons, person_memories, memory_feedback)
- 신규 API: 2개 (GET /memories/people, POST /memories/{id}/feedback)
- 신규 화면: 피플 탭 (iOS+Android), 인물 상세, 확인 카드, 피드백 버튼

## 잘된 것
- 서버 우선 → 클라이언트 병렬 패턴이 잘 작동. R4에서 서버 완료 후 R5에서 iOS/Android 동시 dispatch.
- Gate 1 서브에이전트 병렬 실행이 효율적. 3개 프로젝트를 동시에 코드 레벨 검증.
- Gate 1 CONDITIONAL → 수정 → PASS 사이클이 한 라운드 안에 완결.

## 아쉬운 것
- iOS 워커가 R2에서 작업을 나눠서 커밋하느라 추가 dispatch 필요했음. 프롬프트를 더 구체적으로.
- R2에서 설정 화면 구현이 확인 안 됨 (SettingsView.swift 수정은 있었지만 신규 생성인지 확인 못함)
- normalizedName 품질 실측 테스트를 못 함. 실제 LLM 호출로 추출 정확도 확인 필요.

## 다음에 적용할 것
- autoceo 라운드에 실제 E2E 테스트 포함 (서버 실행 + curl로 API 호출)
- Phase 2 착수 전에 normalizedName 품질 실측 (10개 테스트 대화)
- iOS/Android 워커 프롬프트에 "한 번에 모든 작업 완료 후 커밋" 명시

## For AI Agents
- 관계 메모리 Phase 1이 3개 프로젝트에 모두 구현됨. 서버 API + iOS/Android UI.
- Phase 2 (그룹/브리핑/타임라인/감쇠알림)는 Phase 1 데이터 축적 후 착수.
- normalizedName CRITICAL GAP은 실측 후 판단. WO-005의 5-Layer 검증이 가드레일.
- 다음 스프린트: normalizedName 품질 테스트 → Phase 2 WO 기획 → 또는 P-001 JWT 인증.
