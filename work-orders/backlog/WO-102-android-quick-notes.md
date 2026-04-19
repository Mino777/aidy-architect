# WO-102: Android — Quick Notes UI (v2.8)

**담당**: android
**스펙**: `specs/api-contract.md` § 5.19 Quick Notes (v2.8)

## 구현 범위

### API/Data Layer
1. **QuickNoteApi** — `POST /api/memories/note` + `POST /api/memories/note/batch`
2. **QuickNoteRepository** — 메모 생성/일괄 생성

### UI (Jetpack Compose + MVVM)
1. **QuickNoteViewModel** — 메모 생성 + 카테고리 선택 + 인물 연결
2. **QuickNoteDialog** — BottomSheet
   - TextField (content)
   - 카테고리 칩 그리드 (optional, "자동" 기본)
   - 인물 검색/선택 (optional)
   - "저장" 버튼
3. **HomeScreen/MemoryListScreen에 FAB "+" 버튼**
   - QuickNoteDialog 트리거
4. **NavGraph에 QuickNote 추가**

### 커밋 규칙
- 메시지: `[R2-android] feat: Quick Notes UI (v2.8)`
- 파일 10개 이하/커밋
