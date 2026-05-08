# WO-240: iOS — Activity Summary + Auto-Grouping (v8.6~v8.7)

## 담당: ios

## 스펙
`specs/api-contract.md` § 5.67, 5.68 참조

## 구현 범위

### v8.6 Contact Activity Summary
1. ActivitySummaryClient (API 클라이언트)
2. ActivitySummaryFeature (TCA Reducer)
3. PersonDetailView에 활동 요약 섹션 추가

### v8.7 Smart Auto-Grouping
1. AutoGroupClient (API 클라이언트)
2. AutoGroupFeature (TCA Reducer)
3. AutoGroupSuggestionView — 추천 그룹 UI + 적용 버튼

## 완료 기준
- tuist build PASS (xcodebuild test 금지)
- 커밋 메시지: `[R6-ios] feat: WO-240 Activity Summary + Auto-Grouping`
