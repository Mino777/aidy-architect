# WO-241: Android — Activity Summary + Auto-Grouping (v8.6~v8.7)

## 담당: android

## 스펙
`specs/api-contract.md` § 5.67, 5.68 참조

## 구현 범위

### v8.6 Contact Activity Summary
1. ActivitySummaryApi + Repository
2. ActivitySummaryViewModel + tests
3. PersonDetailScreen에 활동 요약 섹션 추가

### v8.7 Smart Auto-Grouping
1. AutoGroupApi + Repository
2. AutoGroupViewModel + tests
3. AutoGroupScreen (Compose) — 추천 그룹 UI + 적용

## 완료 기준
- testDebugUnitTest PASS
- 커밋 메시지: `[R6-android] feat: WO-241 Activity Summary + Auto-Grouping`
- ViewModel 테스트 필수
