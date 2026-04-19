# WO-099: Android — Relationship Timeline UI (v2.7)

**담당**: android
**스펙**: `specs/api-contract.md` § 5.18 Relationship Timeline (v2.7)

## 구현 범위

### API/Data Layer
1. **RelationshipTimelineApi** — `GET /api/people/{personId}/timeline` Retrofit 인터페이스
2. **RelationshipTimelineRepository** — 타임라인 데이터 조회 + 페이지네이션

### UI (Jetpack Compose + MVVM)
1. **RelationshipTimelineViewModel** — 타임라인 로드 + 무한 스크롤
   - types 필터 상태 관리
2. **RelationshipTimelineScreen** — LazyColumn 타임라인
   - 이벤트 타입별 아이콘/색상 구분
   - memory → MemoryDetail 네비게이션
   - anniversary → AnniversaryDetail 네비게이션
   - chat → ChatHistory 스크롤 이동
3. **People 상세에서 "타임라인" 버튼 추가 + NavGraph 연결**

### 커밋 규칙
- 메시지: `[R2-android] feat: Relationship Timeline UI (v2.7)`
- 파일 10개 이하/커밋
