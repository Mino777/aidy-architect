# WO-230: Android Daily Routine + Gratitude Journal (v8.0~v8.1)

## 스펙: §5.61 + §5.62

## 구현 범위
### Daily Routine
- RoutineApiService — CRUD + complete
- RoutineRepository + RoutineViewModel
- RoutineListScreen (Compose) + 완료 버튼 + streak

### Gratitude Journal
- GratitudeApiService — CRUD + trend
- GratitudeRepository + GratitudeViewModel
- GratitudeListScreen + GratitudeTrendScreen (Compose)
- ViewModel 테스트

## 제약
- [R5-android] feat: WO-230 ..., testDebugUnitTest 필수, 파일 10개 이하
