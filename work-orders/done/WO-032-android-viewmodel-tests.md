# WO-032: Android ViewModel 테스트 — s11~s13 기능

**담당**: android
**우선순위**: P2
**상태**: in-progress

## 목표
s11-s13에서 추가된 기능의 ViewModel 단위 테스트 작성.

## 대상 기능 (테스트 미커버)
1. MemoryViewModel — updateMemory (수정 + optimistic UI)
2. MemoryViewModel — togglePin (핀/언핀 + 정렬)
3. ChatViewModel — searchHistory (서버 검색 + debounce)
4. ChatViewModel — deleteMessage (삭제 + pair delete)
5. SettingsViewModel — exportMemories (내보내기)
6. SettingsViewModel — saveProfile (서버 동기화)

## 검증 기준
- [ ] 6개 기능 각 2건+ 테스트 (happy + error)
- [ ] 기존 135 unit tests 통과 유지
- [ ] 커밋 메시지에 테스트 통계 포함
