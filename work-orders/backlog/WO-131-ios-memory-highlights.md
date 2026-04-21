# WO-131: Memory Highlights UI (v3.8) — iOS

## 담당: ios
## 스펙: api-contract.md § 5.29

## 작업
1. `MemoryHighlight` 모델 + `MemoryHighlightClient` API
2. `MemoryHighlightFeature` (TCA Reducer)
   - 주간/월간 하이라이트 로드
   - 하이라이트 저장/목록 조회
   - 기간 전환 (weekly ↔ monthly)
3. `MemoryHighlightView`
   - 하이라이트 카드 (중요도 게이지 + 태그 칩)
   - 기간 요약 텍스트
   - 저장 버튼 (북마크 아이콘)
   - 저장된 하이라이트 별도 탭
4. Home 또는 Memory 탭에 "이번 주 하이라이트" 섹션 추가
5. 테스트 각 최소 3개

## 금지
- 기존 Home/Memory 화면 구조 변경 금지
- 커밋 1건당 파일 10개 이하
