# WO-025: iOS — 채팅 삭제 + 메모리 내보내기 UI

**담당**: ios
**우선순위**: P1
**상태**: in-progress
**의존**: WO-024

## 목표
채팅 메시지 삭제 UI + 메모리 내보내기 기능 구현.

## 구현 요구사항

### 1. 채팅 메시지 삭제
- ChatView: 메시지 롱프레스 컨텍스트 메뉴에 "삭제" 옵션 추가 (기존 "복사" 옆)
- 삭제 확인 Alert: "이 메시지를 삭제할까요?" (user 메시지면 "AI 응답도 함께 삭제됩니다" 부제)
- APIClient에 deleteMessage(id:) → DELETE /api/chat/{id}
- ChatFeature에 deleteMessage action 추가
- 삭제 성공 → 로컬 메시지 리스트에서 제거 (pair 포함)

### 2. 메모리 내보내기
- SettingsView에 "메모리 내보내기" 버튼 추가
- APIClient에 exportMemories(category:) → GET /api/memories/export
- ShareSheet로 JSON 파일 공유 (UIActivityViewController)
- 다운로드 중 로딩 표시

### 3. accessibilityIdentifier 추가
- `chat_delete_button`, `chat_delete_confirm`
- `settings_export_memories_button`

## 검증 기준
- [ ] 메시지 삭제 UI + API 연동
- [ ] 메모리 내보내기 + ShareSheet
- [ ] 기존 테스트 통과 유지
