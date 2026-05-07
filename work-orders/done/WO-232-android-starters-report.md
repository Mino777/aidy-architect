# WO-232: Android Conversation Starters V2 + Insights Report V2 (v8.2~v8.3)

## 스펙: §5.63 + §5.64

## 구현 범위
### Starters V2
- StarterCardApiService — cards, save, saved, delete, used
- StarterCardRepository + StarterCardViewModel
- StarterCardScreen (Compose) — 카드 UI + 저장

### Insights Report V2
- ReportApiService — monthly, yearly
- ReportRepository + ReportViewModel
- MonthlyReportScreen + YearlyReportScreen (Compose)
- ViewModel 테스트

## 제약
- [R8-android] feat: WO-232 ..., testDebugUnitTest 필수, 파일 10개 이하
