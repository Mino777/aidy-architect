# WO-207: Server Conversation Summary API (v6.2)

## 목표
AI 대화 자동 요약 생성 + 목록 조회 + 삭제.

## 스펙 참조
`specs/api-contract.md` §5.52 Conversation Summary (v6.2)

## 구현 범위
1. `ChatSummary` Entity — summaryId, userId, summary, messageFrom, messageTo, messageCount, createdAt
2. Flyway migration — chat_summaries 테이블
3. `ChatSummaryController` — POST /api/chat/summary, GET /api/chat/summaries, DELETE /api/chat/summaries/{summaryId}
4. `ChatSummaryService` — 최근 N개 메시지 수집, AI에 요약 요청 (기존 AiService 활용), 결과 저장
5. 단위 테스트 (AI 호출은 mock)

## 제약
- 커밋 메시지: `[R2-server] feat: WO-207 Conversation Summary API`
- 커밋 1건당 파일 10개 이하
- 새 패키지 설치 금지
- AiService의 기존 Claude 호출 패턴 재사용

## 완료 기준
- [ ] 3개 엔드포인트 동작
- [ ] AI 요약 생성 로직 (mock 테스트 포함)
- [ ] 빌드 성공
