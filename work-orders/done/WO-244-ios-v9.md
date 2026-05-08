# WO-244: iOS — v9.0~v9.3 전체

## 담당: ios

## 스펙
`specs/api-contract.md` § 5.69~5.72

## 구현 범위
### v9.0 Weekly Digest
- DigestClient + DigestFeature + WeeklyDigestView

### v9.1 AI Memory Questions  
- MemoryQuestionClient + MemoryQuestionFeature + MemoryQuestionView

### v9.2 People Notes
- PersonNoteClient + PersonNoteFeature + PersonNotesView (PersonDetailView에 섹션 추가)

### v9.3 Contact Streak
- StreakClient + StreakFeature + StreakView + LeaderboardView

## 완료 기준
- tuist build PASS (xcodebuild test 금지)
- 커밋: [R8-ios] feat: WO-244 설명
