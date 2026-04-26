# WO-192: iOS — People Comparison UI (v5.7)

## 담당: ios
## 우선순위: P4
## 관련 스펙: api-contract.md § 5.47

## 작업 내용
1. PeopleComparisonClient (Interface/Live)
2. PeopleComparisonFeature (TCA Reducer)
3. PeopleComparisonView — 두 인물 선택 + 비교 결과
4. 비교 차트/카드 (빈도, 감정, 품질, 토픽)

## 완료 기준
- [ ] Client Interface + Live 분리 (TMA)
- [ ] 두 인물 선택 UI (picker)
- [ ] comparison insights 표시
- [ ] tuist build 통과
- [ ] 커밋: `[R3-ios] feat: WO-192 People Comparison UI`

## 제약
- 커밋 1건당 파일 10개 이하
- xcodebuild test 금지, tuist build만
