# WO-100: Server — Quick Notes API (v2.8)

**담당**: server
**스펙**: `specs/api-contract.md` § 5.19 Quick Notes (v2.8)

## 구현 범위

### API
1. **POST /api/memories/note** — 직접 메모리 생성
2. **POST /api/memories/note/batch** — 일괄 메모리 생성 (최대 10개)

### 로직
- content 필수 (1~2000자), 빈 문자열/누락 → 400
- category optional → 미지정 시 AI 자동 분류 (기존 AiService 활용)
- AI로 title 자동 생성 (autoTitle=true)
- personName optional → people 카테고리일 때 Person 매칭 또는 생성
  - normalizedName 기준 기존 Person 검색
  - 없으면 새 Person 생성 (기존 PersonService.findOrCreate 활용)
  - personDetail 응답 포함
- batch: notes 배열 1~10개, AI 1회 호출로 전체 처리
- rate limit: chat 버킷

### 커밋 규칙
- 메시지: `[R2-server] feat: Quick Notes API (v2.8)`
- 파일 10개 이하/커밋
