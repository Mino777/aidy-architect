# WO-233: Server + iOS 테스트 갭 해소

## 담당: server + ios

## 서버 (1건)
- PersonEmotionController 통합 테스트 작성
- 기존 패턴 참조: PersonControllerTest.kt

## iOS (14건 Feature 테스트)
다음 Feature에 대한 TCA 기본 테스트 작성:
1. ChatSummaryFeature
2. CoachingFeature
3. EmotionTrendFeature
4. ForecastFeature
5. ForecastSummaryFeature
6. GoalListFeature
7. GoalSummaryFeature
8. LifeEventListFeature
9. MonthlyReportFeature
10. NotificationListFeature
11. PersonaSettingsFeature
12. RecurringEventListFeature
13. StarterCardFeature
14. UpcomingEventsFeature

## 완료 기준
- Server: PersonEmotionController 테스트 PASS
- iOS: 14개 Feature 테스트 파일 생성 + tuist build PASS
- 커밋 메시지: `[R2-server] test: PersonEmotionController`, `[R2-ios] test: Feature tests batch`
- iOS는 xcodebuild test 금지, tuist build만
