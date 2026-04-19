# WO-098: iOS — Relationship Timeline UI (v2.7)

**담당**: ios
**스펙**: `specs/api-contract.md` § 5.18 Relationship Timeline (v2.7)

## 구현 범위

### API Client
1. **RelationshipTimelineClient** — `GET /api/people/{personId}/timeline` 호출
   - types, limit, offset 파라미터 지원

### UI (TCA + SwiftUI)
1. **RelationshipTimelineFeature** — TCA Reducer
   - 타임라인 로드 + 무한 스크롤 (offset 기반)
   - types 필터 토글 (chat/memory/anniversary)
2. **RelationshipTimelineView** — 타임라인 리스트
   - 이벤트 타입별 아이콘 + 색상 구분
   - memory → MemoryDetail로 네비게이션
   - anniversary → AnniversaryDetail로 네비게이션
   - chat → ChatHistory 스크롤 이동
3. **PersonDetailView에 "타임라인" 버튼 추가**

### 커밋 규칙
- 메시지: `[R2-ios] feat: Relationship Timeline UI (v2.7)`
- 파일 10개 이하/커밋
