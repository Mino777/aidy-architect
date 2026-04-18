# WO-060: Chat Topics + Chat Export API (v1.5)

**담당**: server
**우선순위**: P2
**상태**: backlog
**API 버전**: v1.5.0

## 작업 내용

### 1. Chat Topics (AI 기반 주제 추출)

엔드포인트:
- `GET /api/chat/topics?days=7` — 대화 주제 클러스터링

구현:
- 최근 N일 메시지를 가져와서 AI(Claude)에 주제 추출 요청
- 프롬프트: "다음 대화에서 주요 주제를 추출하고 각 주제별 키워드 3개와 메시지 수를 JSON으로 반환해줘"
- 응답 파싱: topics 배열 (title, messageCount, keywords, sampleMessageId)
- 간단한 in-memory 캐시 (같은 userId+days로 1시간 이내 재요청 시 캐시)

### 2. Chat Export (대화 내보내기)

엔드포인트:
- `GET /api/chat/export?format=text&days=30`

구현:
- format=text: Content-Type text/plain, [timestamp] role: content 형식
- format=json: Content-Type application/json, 메시지 배열
- Content-Disposition 헤더 포함 (다운로드용)
- 메시지 없으면 빈 응답 (200, 에러 아님)

### 참조
- `specs/api-contract.md` v1.5 섹션

## 완료 기준
- [ ] GET /api/chat/topics — AI 주제 추출 + 캐시 동작
- [ ] GET /api/chat/export?format=text — 텍스트 형식 내보내기
- [ ] GET /api/chat/export?format=json — JSON 형식 내보내기
- [ ] Content-Disposition 헤더 포함
- [ ] 테스트 작성 (최소 10건)
- [ ] 커밋: `[R6-server] feat: Chat Topics + Export (v1.5)`
