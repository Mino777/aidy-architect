# WO-059: Chat Bookmarks + AI Feedback UI (Android, v1.4)

**담당**: android
**우선순위**: P2
**상태**: backlog
**API 버전**: v1.4.0

## 작업 내용

### 1. Chat Bookmarks UI

- ChatScreen 메시지 롱프레스 메뉴에 "북마크" 옵션 추가
- 북마크된 메시지에 북마크 아이콘 표시
- 새 화면: BookmarksScreen + BookmarksViewModel (북마크 목록)
- 위치: 설정 화면 또는 채팅 화면 상단 필터
- AidyApiService: `bookmarkMessage(id)`, `getBookmarks(offset, limit)`

### 2. AI Feedback UI

- assistant 메시지 하단에 👍/👎 아이콘 버튼 (Material3 IconButton, 작게)
- 피드백 전송 후 선택 상태 표시 (tint 변경)
- AidyApiService: `feedbackMessage(id, rating)`

### 참조
- `specs/api-contract.md` v1.4 섹션
- Server WO-057 완료 후 진행

## 완료 기준
- [ ] 롱프레스 → 북마크 토글 동작
- [ ] 북마크 목록 화면 존재
- [ ] AI 메시지에 피드백 버튼 표시
- [ ] 피드백 전송 + 상태 표시
- [ ] 테스트 작성 (최소 8건)
- [ ] 커밋: `[R3-android] feat: Chat Bookmarks + AI Feedback UI (v1.4)`
