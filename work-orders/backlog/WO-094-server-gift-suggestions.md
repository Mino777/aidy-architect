# WO-094: Server — Gift Suggestions API (v2.6)

**담당**: server
**스펙**: `specs/api-contract.md` § 5.17 Gift Suggestions (v2.6)

## 구현 범위

### API
1. **POST /api/people/{id}/gift-suggestions** — AI 선물 제안

### 로직
- Person의 PersonMemory에서 취향/관심사 추출
- 다가오는 Anniversary가 있으면 자동 occasion 설정
- AI 프롬프트로 선물 제안 생성 (기존 AiService 활용)
- sourceMemoryIds로 근거 연결
- budget 파라미터로 가격대 필터링 힌트
- rate limit: chat 버킷 공유

### 커밋 규칙
- 메시지: `[R7-server] feat: Gift Suggestions API (v2.6)`
- 파일 10개 이하/커밋
