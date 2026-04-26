# WO-195: Android — Conversation Templates UI (v5.6)

## 담당: android
## 우선순위: P4
## 관련 스펙: api-contract.md § 5.46

## 작업 내용
1. ConversationTemplateRepository + API
2. ConversationTemplatesViewModel (UiState data class 패턴)
3. ConversationTemplatesScreen — 카테고리별 템플릿 목록
4. 템플릿 사용 + feedback API 연동

## 완료 기준
- [ ] 2개 엔드포인트 연동
- [ ] UiState data class 패턴 사용
- [ ] 카테고리 필터 UI
- [ ] testDebugUnitTest 통과
- [ ] 커밋: `[R3-android] feat: WO-195 Conversation Templates UI`

## 제약
- 커밋 1건당 파일 10개 이하
- 기존 패키지만 사용
