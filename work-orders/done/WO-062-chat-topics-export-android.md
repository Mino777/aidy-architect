# WO-062: Chat Topics + Chat Export UI (Android, v1.5)

**담당**: android
**우선순위**: P2
**상태**: done
**API 버전**: v1.5.0

## 작업 내용

### 1. Chat Topics UI

- 새 화면: TopicsScreen + TopicsViewModel
- 위치: 채팅 화면 상단 toolbar에 "주제" 아이콘
- 주제 카드 리스트: title, keywords (Chip), messageCount, 날짜 범위
- 주제 탭 시 해당 sampleMessageId로 채팅 히스토리 스크롤
- AidyApiService: `getTopics(days: Int)`

### 2. Chat Export UI

- 위치: 설정 화면 또는 채팅 화면 메뉴
- 포맷 선택: 텍스트 / JSON (Material3 SegmentedButton 또는 AlertDialog)
- 기간 선택: 7일 / 30일 / 전체
- 내보내기 버튼 → Intent.ACTION_SEND로 파일 공유
- AidyApiService: `exportChat(format: String, days: Int)`

### 참조
- `specs/api-contract.md` v1.5 섹션

## 완료 기준
- [ ] 주제 목록 화면 존재 + API 연동
- [ ] 내보내기 포맷/기간 선택 UI
- [ ] Intent.ACTION_SEND로 파일 공유
- [ ] 테스트 작성 (최소 8건)
- [ ] 커밋: `[R7-android] feat: Chat Topics + Export UI (v1.5)`
