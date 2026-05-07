# WO-231: iOS Conversation Starters V2 + Insights Report V2 (v8.2~v8.3)

## 스펙: §5.63 + §5.64

## 구현 범위
### Starters V2
- StarterCardClient — cards, save, saved, delete, used API
- StarterCardFeature (TCA) + StarterCardView (카드 UI)
- 저장된 카드 목록

### Insights Report V2
- ReportClient — monthly, yearly API
- MonthlyReportFeature (TCA) + MonthlyReportView
- YearlyReportFeature + YearlyReportView

## 제약
- [R7-ios] feat: WO-231 ..., tuist build 필수, 파일 10개 이하
