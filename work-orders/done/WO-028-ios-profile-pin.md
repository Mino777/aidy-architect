# WO-028: iOS — 프로필 수정 + 메모리 핀 UI

**담당**: ios
**우선순위**: P1
**상태**: in-progress
**의존**: WO-027

## 구현 요구사항

### 1. 프로필 닉네임 서버 동기화
- SettingsView의 닉네임 저장 → 서버 PATCH /api/auth/profile 호출
- APIClient에 updateProfile(nickname:) 추가
- SettingsFeature에 saveProfile action 추가
- 성공 → 로컬 저장 + 서버 동기화, 실패 → 에러 토스트

### 2. 메모리 핀
- MemoryView: 메모리 항목에 핀 아이콘 (📌) 표시
- 스와이프 또는 탭으로 핀/언핀 토글
- APIClient에 pinMemory(id:pinned:) → POST /api/memories/{id}/pin
- MemoryFeature에 togglePin action
- 핀된 메모리 리스트 상단 고정 (클라이언트 정렬)
- 카테고리 칩에 "📌 고정" 필터 추가

### 3. accessibilityIdentifier
- settings_save_profile_button
- memory_pin_button, memory_pinned_filter

## 검증 기준
- [ ] 닉네임 서버 동기화 동작
- [ ] 메모리 핀/언핀 UI + API 연동
- [ ] 핀 메모리 상단 고정
- [ ] 기존 테스트 통과 유지
