# WO-229: iOS Daily Routine + Gratitude Journal (v8.0~v8.1)

## 스펙: §5.61 + §5.62

## 구현 범위
### Daily Routine
- RoutineClient — CRUD + complete API
- RoutineListFeature (TCA) + RoutineListView (SwiftUI)
- 루틴 완료 버튼 + streak 표시

### Gratitude Journal
- GratitudeClient — CRUD + trend API
- GratitudeListFeature (TCA) + GratitudeListView + GratitudeTrendView
- PersonDetailView에 감사 일기 연결

## 제약
- [R4-ios] feat: WO-229 ..., tuist build 필수, 파일 10개 이하
