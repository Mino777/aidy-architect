# autoceo-s38 회고 — Favorite People + Conversation Summary (v6.1~v6.2)

**일시**: 2026-05-02
**워커**: server + ios + android (순차 dispatch)
**라운드**: 5 (R1 스펙, R2 서버, R3 클라이언트, R4 Gate, R5 Compound)
**소요**: ~50분

## 이번에 한 것
- v6.1 Favorite People: 인물 즐겨찾기 토글 + 목록 필터링
- v6.2 Conversation Summary: AI 대화 자동 요약 생성 + 목록 조회 + 삭제
- Server: 2커밋, 15파일, +520줄 (V52~V53 마이그레이션, 1640 tests)
- iOS: 2커밋, 11파일, +759줄 (FavoritePeopleClient, ConversationSummaryClient + Features)
- Android: 2커밋, 13파일, +1063줄 (ViewModel 2개 + 테스트)
- WO-206~211 (6개) 전부 Gate-1/Gate-2 PASS

## 잘된 것
- 서버 테스트 4건 실패 → 워커가 자체 디버깅하여 해결 (Architect 개입 불필요)
- s37 회고 액션 적용: iOS WO에 "DerivedData 전체 삭제 금지" 명시 → iOS 빌드 시간 단축 (30분 → 19분)
- 피처 스코프가 작아서 Gate-1 축약 검증 적합 (엔드포인트 6개, 서브에이전트 불필요)
- Swap 67% 경고에 1-way 순차 유지 — 시스템 안정

## 아쉬운 것 (다음 사이클 입력)
- Conversation Summary의 AI 요약 품질 검증 부재: 서버가 AiService.summarize를 호출하지만, 실제 요약 프롬프트가 적절한지 검증하지 않음. mock 테스트만 통과 — 실제 AI 출력 품질은 미확인.
- iOS ConversationSummaryClient에서 POST /api/chat/summary 엔드포인트가 APIClient+Live.swift(기존)와 ConversationSummaryClient.swift(신규)에 중복 정의될 수 있는 패턴 — 확인하지 않고 PASS 판정.
- 서버 테스트 4건 실패 원인을 확인하지 않음. 워커가 자체 해결했다고 넘어갔지만, 기존 테스트 깨짐이었을 수 있음 — 근본 원인 미파악.

## 다음에 적용할 것
1. AI 기능 WO에 "실제 AI 호출 프롬프트 내용" 명시 + "요약 품질 기준" 포함
2. iOS 클라이언트 중복 엔드포인트 패턴 점검 — Gate-1에서 기존 APIClient+Live.swift와의 중복 확인
3. 서버 테스트 실패 시 워커에게 "실패 원인 + 수정 내용" 보고 의무화

## Compound Assets (이번 사이클에서 생성된 재사용 자산)
| 자산 | 경로 | 용도 |
|------|------|------|
| api-contract v6.1~v6.2 | `specs/api-contract.md` | Favorite People + Conversation Summary 스펙 |
| V52~V53 마이그레이션 | `aidy-server/db/migration/` | favorites + chat_summaries 테이블 |
| FavoritePeopleClient | `aidy-ios/Projects/Core/Networking/` | iOS 즐겨찾기 네트워크 클라이언트 |

## For AI Agents
다음 세션에서 이 회고를 입력으로 받을 때:
- v6.2까지 완료. 다음 피처는 v6.3+
- Conversation Summary는 AI 호출 포함 — 프롬프트 품질 검증 미완
- 즐겨찾기는 Person 엔티티에 favorited 필드 추가 방식 (별도 테이블 아님)
- s37 회고 액션 "iOS DerivedData 금지" 효과 있음 (19분으로 단축)
