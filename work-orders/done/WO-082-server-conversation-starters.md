# WO-082: Server — Conversation Starters API (v2.2)

**담당**: server
**스펙**: `specs/api-contract.md` § 5.13 Conversation Starters (v2.2)
**선행**: 없음

## 구현 범위

### 엔드포인트
- `GET /api/people/{personId}/conversation-starters`

### 상세
1. **ConversationStarterController** — 엔드포인트 1개
2. **ConversationStarterService** — AI 프롬프트로 대화 주제 생성
   - 해당 인물의 메모리 + 최근 대화 분석
   - category: recent_memory | shared_interest | follow_up | seasonal | general
   - confidence 점수 포함 (0.0~1.0)
   - 최대 5개, confidence 내림차순
3. **캐싱**: 6시간 TTL (인물별)
4. **엣지 케이스**: 메모리 0건 → general 카테고리 2개만 반환
5. **에러**: PERSON_NOT_FOUND (404)

### 커밋 규칙
- 메시지: `[R2-server] feat: Conversation Starters API (v2.2)`
- 파일 10개 이하/커밋
