# WO-074: Memory Connections UI (iOS, v1.9)

**담당**: ios
**우선순위**: P2
**상태**: backlog
**API 버전**: v1.9.0

## 작업 내용

### Memory Connections UI
- 메모리 상세 화면에 "관련 메모리" 섹션 추가
- ConnectionsListView: 관련 메모리 카드 리스트 (title, category, relevance 바)
- 카드 탭 시 해당 메모리로 네비게이션
- "연결 추가" 버튼 → 메모리 검색 sheet → 선택하여 수동 연결
- 스와이프 삭제로 연결 해제
- APIClient: `getConnections(memoryId:limit:)`, `addConnection(memoryId:targetId:)`, `deleteConnection(memoryId:targetId:)`

### 참조
- `specs/api-contract.md` v1.9 섹션

## 완료 기준
- [ ] 메모리 상세에 관련 메모리 섹션
- [ ] 수동 연결 추가 동작
- [ ] 연결 삭제 동작
- [ ] 테스트 최소 8건
- [ ] 커밋: `[RN-ios] feat: Memory Connections UI (v1.9)`
