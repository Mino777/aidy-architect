# WO-026: Android — 채팅 삭제 + 메모리 내보내기 UI

**담당**: android
**우선순위**: P1
**상태**: in-progress
**의존**: WO-024

## 목표
채팅 메시지 삭제 UI + 메모리 내보내기 기능 구현.

## 구현 요구사항

### 1. 채팅 메시지 삭제
- ChatScreen: 롱프레스 BottomSheet에 "삭제" 옵션 추가 (기존 "복사" 옆)
- 삭제 확인 AlertDialog: "이 메시지를 삭제할까요?" (user면 "AI 응답도 함께 삭제됩니다")
- ApiService에 deleteMessage(id) → DELETE /api/chat/{id}
- ChatViewModel에 deleteMessage action 추가
- 삭제 성공 → 로컬 메시지 리스트에서 제거 (pair 포함)

### 2. 메모리 내보내기
- SettingsScreen에 "메모리 내보내기" 버튼 추가
- ApiService에 exportMemories(category) → GET /api/memories/export
- Intent.ACTION_SEND로 JSON 파일 공유
- 다운로드 중 CircularProgressIndicator

### 3. testTag 추가 (TestTags.kt)
- `CHAT_DELETE_BUTTON`, `CHAT_DELETE_CONFIRM`
- `SETTINGS_EXPORT_MEMORIES_BUTTON`

## 검증 기준
- [ ] 메시지 삭제 UI + API 연동
- [ ] 메모리 내보내기 + ShareIntent
- [ ] 기존 테스트 통과 유지
