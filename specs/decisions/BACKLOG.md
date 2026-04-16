# 의사결정 백로그

> 아직 결정되지 않았거나, 다음 스프린트에서 결정해야 할 아키텍처 이슈.

## 대기 중

| ID | 제목 | 긴급도 | 관련 WO | 비고 |
|----|------|--------|---------|------|
| ~~P-001~~ | ~~JWT 인증 방식 (v0.2)~~ | ~~P1~~ | WO-009 done | 완료 — ADR-006 |
| ~~P-002~~ | ~~실시간 채팅 (WebSocket vs SSE)~~ | ~~P2~~ | autoceo-s5-R7 | 완료 — ADR-008 (SSE 채택) |
| ~~P-003~~ | ~~메모리 추출 AI 프롬프트 최적화~~ | ~~P1~~ | R5 완료 | 프롬프트 강화됨 |
| ~~P-004 Phase 1~~ | ~~Circuit Breaker~~ | ~~P2~~ | autoceo-s4-R2 done | 완료 — ADR-007 |
| P-004 Phase 2 | Multi-Provider Fallback (OpenAI 등) | P3 | 미정 | 2nd API key 필요 |
| ~~P-005~~ | ~~AI 출력 런타임 검증 (5-Layer 패턴)~~ | ~~P2~~ | WO-005 done | 완료 |
| P-006 | Multi-Agent Pipeline 설계 (메모리 추출) | P3 | ADR 필요 | 단일 LLM → 전문화된 에이전트 파이프라인 검토 |

## 결정 완료 → ADR 이동

| ID | ADR | 결정 |
|----|-----|------|
| P-006 | ADR-004 | 현행 유지 + WO-005 검증 강화. 추출 실패율 >15% 시 2단 파이프라인 전환 |
| NEW | ADR-005 | 관계 메모리 아키텍처 — B+C 합성, Phase 1/2 분리, UNIQUE+ON CONFLICT |
| P-001 | ADR-006 | JWT 인증 — bcrypt + jjwt + Keychain(iOS) + EncryptedSharedPrefs(Android) |
| P-003 | — | 프롬프트 최적화 — normalizedName 정규화 규칙 강화, 추출 품질 힌트 |
| P-005 | — | AI 출력 5-Layer 런타임 검증 — WO-005로 구현 완료 |
| P-004 Phase 1 | ADR-007 | AI Circuit Breaker — in-memory, 0 dep, CLOSED/OPEN/HALF_OPEN |
| P-002 | ADR-008 | SSE 스트리밍 채팅 — `/api/chat/stream`, fake-stream Phase 1 |
