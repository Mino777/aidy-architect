# WO-191: iOS — Conversation Templates UI (v5.6)

## 담당: ios
## 우선순위: P4
## 관련 스펙: api-contract.md § 5.46

## 작업 내용
1. ConversationTemplateClient (Interface/Live)
2. ConversationTemplatesFeature (TCA Reducer)
3. ConversationTemplatesView — 카테고리별 템플릿 목록
4. 템플릿 사용 → use API 호출 + feedback

## 완료 기준
- [ ] Client Interface + Live 분리 (TMA)
- [ ] 카테고리 필터 (congratulation/comfort/gratitude/catchup/apology)
- [ ] personId 필터 지원
- [ ] tuist build 통과
- [ ] 커밋: `[R3-ios] feat: WO-191 Conversation Templates UI`

## 제약
- 커밋 1건당 파일 10개 이하
- xcodebuild test 금지, tuist build만
