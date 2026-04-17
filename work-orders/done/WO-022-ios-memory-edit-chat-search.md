# WO-022: iOS — 메모리 수정 + 채팅 검색 UI

**담당**: ios
**우선순위**: P1-높음 (새 기능)
**상태**: in-progress
**의존**: WO-021 (서버 구현)

## 목표
메모리 수정 UI + 채팅 히스토리 검색 UI 구현.

## 구현 요구사항

### 1. 메모리 수정
- MemoryView에서 메모리 항목 탭 → 수정 시트/다이얼로그
- title, content 수정 가능 (category 읽기 전용)
- APIClient에 `updateMemory(id:title:content:)` 추가 → PUT /api/memories/{id}
- MemoryFeature에 editMemory action 추가
- 수정 성공 → 로컬 리스트 업데이트 (optimistic UI)
- 수정 실패 → 에러 토스트

### 2. 채팅 검색
- ChatView의 기존 검색 필터를 **서버 검색으로 전환** (현재 클라이언트 필터)
- APIClient에 `searchChatHistory(query:)` 추가 → GET /api/chat/history/search?q=
- ChatFeature에 searchHistory action 추가
- 검색 결과를 별도 리스트로 표시 (기존 메시지와 구분)
- 검색어 debounce 300ms
- 빈 결과 → "검색 결과 없음" 표시

### 3. Accessibility + 테스트
- 새 UI 요소에 accessibilityIdentifier 추가
- 기존 124 unit + 42 UI tests 통과 유지

## 검증 기준
- [ ] 메모리 수정 UI + API 연동
- [ ] 채팅 서버 검색 UI + API 연동
- [ ] api-contract v0.3.0 스펙과 일치
- [ ] 기존 테스트 통과 유지
