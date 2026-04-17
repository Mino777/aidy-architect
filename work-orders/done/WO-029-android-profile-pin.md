# WO-029: Android — 프로필 수정 + 메모리 핀 UI

**담당**: android
**우선순위**: P1
**상태**: in-progress
**의존**: WO-027

## 구현 요구사항

### 1. 프로필 닉네임 서버 동기화
- SettingsScreen 저장 버튼 → 서버 PATCH /api/auth/profile 호출
- ApiService에 updateProfile(request) 추가
- SettingsViewModel에 saveProfile action
- 성공 → EncryptedSharedPrefs + 서버 동기화, 실패 → Snackbar

### 2. 메모리 핀
- MemoryScreen: 메모리 카드에 핀 아이콘 표시
- 스와이프 또는 롱프레스로 핀/언핀 토글
- ApiService에 pinMemory(id, request) → POST /api/memories/{id}/pin
- MemoryViewModel에 togglePin action
- 핀된 메모리 리스트 상단 고정 (클라이언트 정렬)
- 카테고리 칩에 "📌 고정" 필터 추가

### 3. TestTags
- SETTINGS_SAVE_PROFILE_BUTTON
- MEMORY_PIN_BUTTON, MEMORY_PINNED_FILTER

## 검증 기준
- [ ] 닉네임 서버 동기화 동작
- [ ] 메모리 핀/언핀 UI + API 연동
- [ ] 핀 메모리 상단 고정
- [ ] 기존 테스트 통과 유지
