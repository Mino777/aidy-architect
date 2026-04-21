# WO-133: Chat Context Memory API (v3.9) — Server

## 담당: server
## 스펙: api-contract.md § 5.30

## 작업
1. `ChatContext` Entity + Repository
   - id, userId, summary, topics(JSON), lastUpdated, messageCount, expiresAt
   - 만료 기본 7일
2. `ChatContextService`
   - getContext(userId): 활성 컨텍스트 조회
   - refreshContext(userId, messageCount): AI가 최근 N개 메시지 분석 → 요약 생성
   - clearContext(userId): 컨텍스트 삭제
3. `ChatContextController` — 3개 엔드포인트
   - GET /api/chat/context
   - POST /api/chat/context/refresh
   - DELETE /api/chat/context
4. 기존 ChatService에서 대화 시 자동으로 context 주입 (AI 프롬프트에 summary 포함)
5. 테��트 각 최소 3��

## 금지
- 기존 Chat 엔드포인트 수정 금지 (context 주입은 서비스 레이어에서)
- 커밋 1건당 파일 10개 이하
