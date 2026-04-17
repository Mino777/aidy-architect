# WO-031: iOS Feature 테스트 — s11~s13 기능

**담당**: ios
**우선순위**: P2
**상태**: in-progress

## 목표
s11-s13에서 추가된 기능의 TCA TestStore 테스트 작성.

## 대상 기능 (테스트 미커버)
1. MemoryFeature — editMemory (수정 시트 열기/저장/실패)
2. MemoryFeature — togglePin (핀/언핀 + 로컬 정렬)
3. ChatFeature — searchHistory (서버 검색 + debounce)
4. ChatFeature — deleteMessage (삭제 확인 + pair delete)
5. SettingsFeature — exportMemories (내보내기 + ShareSheet)
6. SettingsFeature — saveProfile (서버 동기화)

## 검증 기준
- [ ] 6개 기능 각 2건+ 테스트 (happy + error)
- [ ] 기존 124 unit tests 통과 유지
- [ ] 커밋 메시지에 테스트 통계 포함
