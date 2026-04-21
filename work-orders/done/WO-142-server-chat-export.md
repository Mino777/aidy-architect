# WO-142: Chat Export API (v4.2) — Server

## 담당: server
## 스펙: api-contract.md § 5.33

## 작업
1. `ChatExportService`
   - exportJson(userId, startDate, endDate): JSON 형식 내보내기
   - exportText(userId, startDate, endDate): 텍스트 형식 내보내기
   - getStats(userId): 내보내기 가능 데이터 통계
2. `ChatExportController` — 2개 엔드포인트
   - GET /api/chat/export (format=json|text, startDate, endDate)
   - GET /api/chat/export/stats
3. JSON 형식: reactions 포함
4. Text 형식: "YYYY-MM-DD HH:mm [user/assistant] 내용" 줄바꿈 구분
5. 테스트 각 최소 3개

## 금지
- 기존 Chat 엔드포인트 수정 금지
- 커밋 1건당 파일 10개 이하
