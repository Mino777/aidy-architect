# WO-083: iOS — Conversation Starters UI (v2.2)

**담당**: ios
**스펙**: `specs/api-contract.md` § 5.13 Conversation Starters (v2.2)
**선행**: WO-082 (서버 API)

## 구현 범위

### 화면
- PeopleDetail 화면에 "대화 주제 추천" 섹션 추가
- 카드 형태로 topic + suggestion + context 표시
- category별 아이콘/색상 구분
- 카드 탭 → 채팅 화면으로 이동 (suggestion 텍스트 프리필)

### 데이터
1. **ConversationStarterClient** — API 호출
2. **ConversationStarterFeature (TCA)** — 상태 관리
3. **ConversationStarterView** — 카드 리스트 UI
4. confidence 낮은 항목 (< 0.5) 은 연하게 표시

### 커밋 규칙
- 메시지: `[R3-ios] feat: Conversation Starters UI (v2.2)`
- 파일 10개 이하/커밋
