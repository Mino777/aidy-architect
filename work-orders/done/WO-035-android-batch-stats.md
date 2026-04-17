# WO-035: Android — 메모리 일괄 작업 + 채팅 통계 UI

**담당**: android
**우선순위**: P1
**상태**: in-progress
**의존**: WO-033

## 구현 요구사항

### 1. 메모리 일괄 작업
- MemoryScreen: 다중 선택 모드 (편집 FAB → 체크박스 표시)
- 선택 후 TopAppBar 액션: "삭제" / "📌 핀" / "📌 해제"
- ApiService.batchMemories(request) → POST /api/memories/batch
- MemoryViewModel에 selectMode, batchAction 관련 state/action
- 성공 → 로컬 리스트 업데이트

### 2. 채팅 통계
- SettingsScreen 또는 ChatScreen에 통계 섹션
- ApiService.getChatStats() → GET /api/chat/stats
- 표시: 총 메시지, 일평균, 메모리 추출 수, 첫/마지막 대화

### 3. TestTags
- MEMORY_SELECT_MODE_BUTTON, MEMORY_BATCH_DELETE, MEMORY_BATCH_PIN
- CHAT_STATS_SECTION

## 검증 기준
- [ ] 다중 선택 + 일괄 작업 UI
- [ ] 채팅 통계 표시
- [ ] 기존 테스트 통과 유지
