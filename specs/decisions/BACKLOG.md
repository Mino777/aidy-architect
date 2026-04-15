# 의사결정 백로그

> 아직 결정되지 않았거나, 다음 스프린트에서 결정해야 할 아키텍처 이슈.

## 대기 중

| ID | 제목 | 긴급도 | 관련 WO | 비고 |
|----|------|--------|---------|------|
| P-001 | JWT 인증 방식 (v0.2) | P1 | WO-004 예정 | 서버 + 클라이언트 모두 영향 |
| P-002 | 실시간 채팅 (WebSocket vs SSE) | P2 | 미정 | 스트리밍 응답 필요 시 |
| P-003 | 메모리 추출 AI 프롬프트 최적화 | P1 | WO-001 후속 | 추출 정확도 개선 |
| P-004 | AI 호출 Circuit Breaker + Multi-Provider Fallback | P2 | 서버 WO 예정 | ai-study Journal 006 패턴 이식. timeout+retry+에러분류 |
| P-005 | AI 출력 런타임 검증 (5-Layer 패턴) | P2 | 서버 WO 예정 | ai-study Journal 009-023 패턴. Layer 1 텍스트가드 → Layer 5 LLM-as-Judge |
| P-006 | Multi-Agent Pipeline 설계 (메모리 추출) | P3 | ADR 필요 | 단일 LLM → 전문화된 에이전트 파이프라인 검토 |

## 결정 완료 → ADR 이동

| ID | ADR | 결정 |
|----|-----|------|
| P-006 | ADR-004 | 현행 유지 + WO-005 검증 강화. 추출 실패율 >15% 시 2단 파이프라인 전환 |
| NEW | ADR-005 | 관계 메모리 아키텍처 — B+C 합성, Phase 1/2 분리, UNIQUE+ON CONFLICT |
