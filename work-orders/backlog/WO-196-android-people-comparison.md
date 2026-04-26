# WO-196: Android — People Comparison UI (v5.7)

## 담당: android
## 우선순위: P4
## 관련 스펙: api-contract.md § 5.47

## 작업 내용
1. PeopleComparisonRepository + API
2. PeopleComparisonViewModel (UiState data class 패턴)
3. PeopleComparisonScreen — 두 인물 선택 + 비교 결과
4. 비교 차트/카드 Compose UI

## 완료 기준
- [ ] 엔드포인트 연동
- [ ] UiState data class 패턴 사용
- [ ] 두 인물 선택 picker UI
- [ ] testDebugUnitTest 통과
- [ ] 커밋: `[R3-android] feat: WO-196 People Comparison UI`

## 제약
- 커밋 1건당 파일 10개 이하
- 기존 패키지만 사용
