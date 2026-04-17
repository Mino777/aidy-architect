# WO-034: iOS — 메모리 일괄 작업 + 채팅 통계 UI

**담당**: ios
**우선순위**: P1
**상태**: in-progress
**의존**: WO-033

## 구현 요구사항

### 1. 메모리 일괄 작업
- MemoryView: 다중 선택 모드 (편집 버튼 → 체크박스 표시)
- 선택 후 하단 툴바: "삭제" / "📌 핀" / "📌 해제"
- APIClient.batchMemories(action:ids:) → POST /api/memories/batch
- MemoryFeature에 selectMode, batchAction 관련 action 추가
- 성공 → 로컬 리스트 업데이트

### 2. 채팅 통계
- SettingsView 또는 ChatView에 통계 섹션 추가
- APIClient.getChatStats() → GET /api/chat/stats
- 표시: 총 메시지, 일평균, 메모리 추출 수, 첫/마지막 대화 날짜

### 3. accessibilityIdentifier
- memory_select_mode_button, memory_batch_delete, memory_batch_pin
- chat_stats_section

## 검증 기준
- [ ] 다중 선택 + 일괄 작업 UI
- [ ] 채팅 통계 표시
- [ ] 기존 테스트 통과 유지
