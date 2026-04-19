# WO-075: Memory Connections UI (Android, v1.9)

**담당**: android
**우선순위**: P2
**상태**: backlog
**API 버전**: v1.9.0

## 작업 내용

### Memory Connections UI
- 메모리 상세 화면에 "관련 메모리" 섹션 추가
- ConnectionsList Composable: 관련 메모리 카드 리스트 (title, category, relevance LinearProgressIndicator)
- 카드 탭 시 해당 메모리로 네비게이션
- "연결 추가" FAB → 메모리 검색 BottomSheet → 선택하여 수동 연결
- SwipeToDismiss로 연결 해제
- AidyApiService: `getConnections(memoryId, limit)`, `addConnection(memoryId, targetId)`, `deleteConnection(memoryId, targetId)`

### 참조
- `specs/api-contract.md` v1.9 섹션

## 완료 기준
- [ ] 메모리 상세에 관련 메모리 섹션
- [ ] 수동 연결 추가 동작
- [ ] 연결 삭제 동작
- [ ] 테스트 최소 8건
- [ ] 커밋: `[RN-android] feat: Memory Connections UI (v1.9)`
