# WO-101: iOS — Quick Notes UI (v2.8)

**담당**: ios
**스펙**: `specs/api-contract.md` § 5.19 Quick Notes (v2.8)

## 구현 범위

### API Client
1. **QuickNoteClient** — `POST /api/memories/note` + `POST /api/memories/note/batch`

### UI (TCA + SwiftUI)
1. **QuickNoteFeature** — TCA Reducer
   - content 입력 + category 선택 (optional)
   - personName 자동완성 (기존 People 목록에서)
   - 생성 성공 시 dismiss + 메모리 목록 갱신 트리거
2. **QuickNoteSheet** — 바텀 시트 UI
   - 텍스트 필드 (content)
   - 카테고리 칩 선택 (optional, "자동" 기본)
   - 인물 연결 (optional, People 검색)
   - "메모 저장" 버튼
3. **HomeView/MemoryListView에 + FAB 또는 네비게이션바 "+" 버튼**
   - QuickNoteSheet 트리거

### 커밋 규칙
- 메시지: `[R2-ios] feat: Quick Notes UI (v2.8)`
- 파일 10개 이하/커밋
