# ADR-008: 실시간 채팅 스트리밍 — SSE (P-002)

**Date**: 2026-04-16
**Status**: Accepted
**Sprint**: autoceo-s5-R7
**Related**: P-002 (BACKLOG), ChatController, AiService

## 배경
현재 `POST /api/chat` 은 AI 응답 전체를 한 번에 반환. 응답 긴 경우 유저가 수 초 동안 로딩만 바라봄. 스트리밍으로 점진적 표시가 UX 대폭 개선.

## 결정
**SSE (Server-Sent Events) 채택.** WebSocket 은 미채택.

신규 엔드포인트: `GET /api/chat/stream` — 기존 `POST /api/chat` 과 공존.

### 왜 SSE인가 (vs WebSocket)
| 기준 | SSE | WebSocket | 선택 |
|------|-----|-----------|------|
| 방향성 | 서버→클라 단방향 (채팅 응답 전송에 충분) | 양방향 | SSE |
| 프로토콜 복잡도 | HTTP/1.1 리소스, 단순 | 별도 핸드셰이크 | SSE |
| 로드밸런서/프록시 호환 | HTTP이므로 투명 | 일부 환경 문제 | SSE |
| 재연결 | `Last-Event-ID` 자동 | 수동 | SSE |
| Spring 지원 | `SseEmitter` 내장 | 추가 설정 | SSE |
| 클라 지원 | iOS URLSession streaming / Android OkHttp BufferedSource 가능 | 라이브러리 필요 | SSE |

**결정 근거**: 채팅은 **서버→클라 스트리밍**만 필요 (클라→서버는 POST로 충분). 양방향 필요 없음.

## 프로토콜 설계

### Request
```
GET /api/chat/stream?message=hello
Authorization: Bearer {JWT}
Accept: text/event-stream
```

또는 더 안전한 POST:
```
POST /api/chat/stream
Content-Type: application/json
Authorization: Bearer {JWT}

{ "message": "hello" }
```
→ **POST 채택**. 이유: message가 쿼리스트링 URL 로그에 남는 것을 피하고 길이 제한 회피.

### Response 스트림 이벤트
```
event: token
data: {"text": "안녕"}

event: token
data: {"text": "하세요"}

event: memory
data: {"category": "schedule", "title": "...", "content": "..."}

event: done
data: {"messageId": 42, "totalTokens": 128}

event: error
data: {"code": "AI_TIMEOUT", "error": "..."}
```

- `token`: 텍스트 조각 (청크)
- `memory`: 추출된 메모리 (있으면)
- `done`: 종료 신호
- `error`: 에러 (스트림 종료)

### 에러/종료
- 정상 종료: `event: done` 후 서버가 connection close
- 에러: `event: error` 후 close (스트림 중간에도 발생 가능)
- 타임아웃: `SseEmitter` timeout 30s
- Circuit Breaker OPEN: 연결 즉시 `error` 후 close

## 구현 범위 (이 스프린트, R7)
1. **서버 — Phase 1** (이번 라운드):
   - `/api/chat/stream` 엔드포인트 (POST) — `SseEmitter`
   - AiService 는 여전히 non-streaming — fake stream (청크 분할 전송) 으로 시뮬레이션
   - Anthropic API streaming 직접 연동은 Phase 2
   - 테스트: MockMvc async 지원으로 이벤트 시퀀스 검증

2. **클라이언트** (다음 스프린트, 범위 밖):
   - iOS: URLSession byteStream + event 파싱
   - Android: OkHttp + SSE lib 또는 수동 파싱

## Rate Limit + 보안
- `/api/chat/stream` 도 chat rpm=20 버킷 공유
- 인증 필수 (Bearer)
- MaxConnections per user = 2 (추상 가이드라인 — 강제는 Phase 2)

## Trade-off
- (+) UX 개선: 점진 표시
- (+) 0 dependency (Spring Web 내장 SseEmitter)
- (+) 기존 `POST /api/chat` 유지 (공존)
- (−) HTTP/1.1 연결 점유 — 다중 사용자 스케일 시 고려
- (−) Fake stream (Phase 1) 은 체감 개선 제한적 — 실제 개선은 Anthropic streaming 연동 Phase 2에서

## Phase 2 (다음 스프린트)
- Anthropic Messages API streaming (`stream=true`) 연동
- 클라이언트 SSE 구독 (iOS/Android)
- Circuit Breaker / Validator 가 스트리밍과 어떻게 상호작용하는지 설계

## BACKLOG 업데이트
- P-002 → "결정 완료 → ADR-008 (SSE)"
