# WO-065: Memory Smart Review UI (Android, v1.6)

**담당**: android
**우선순위**: P2
**상태**: backlog
**API 버전**: v1.6.0

## 작업 내용

### Memory Smart Review UI
- 새 화면: ReviewSuggestionsScreen + ReviewSuggestionsViewModel
- 위치: 메모리 탭 상단에 "리뷰 필요" 배지/배너 (suggestions 개수 표시)
- 배너 탭 시 리뷰 목록 BottomSheet 표시
- 각 제안 카드: title, reason, priority 배지 (Material3 색상)
- 액션 버튼 3개: 확인, 수정, 삭제
- AidyApiService: `getReviewSuggestions(limit)`, `reviewMemory(id, action)`

### 참조
- `specs/api-contract.md` v1.6 섹션

## 완료 기준
- [ ] 메모리 탭에 리뷰 배너 표시
- [ ] 리뷰 목록 + 3가지 액션 동작
- [ ] 테스트 최소 8건
- [ ] 커밋: `[R3-android] feat: Memory Smart Review UI (v1.6)`
