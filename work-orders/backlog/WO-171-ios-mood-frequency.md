# WO-171: iOS Mood Tracking + Contact Frequency Goals UI

**담당**: ios
**우선순위**: P4
**상태**: backlog
**스펙**: api-contract.md §5.40, §5.41

## 구현 요구사항

### 1. Mood Tracking
- MoodClient (Dependencies): POST/DELETE /api/chat/{chatId}/mood, GET /api/mood/trends
- MoodPickerView: 대화 후 감정 선택 (8개 이모지 버튼, 채팅 화면 하단에 배치)
- MoodTrendsFeature (TCA): 기간별 감정 분포 차트 (바 차트 + 주별 dominant)
- MoodTrendsView: Settings 또는 Insights 탭에서 접근

### 2. Contact Frequency Goals
- FrequencyGoalClient: PUT/DELETE /api/people/{personId}/frequency-goal, GET /api/frequency-goals
- FrequencyGoalFeature (TCA): 목표 설정/삭제/목록
- FrequencyGoalSettingView: PersonDetail에서 목표 설정 시트
- FrequencyDashboardView: 전체 목표 달성 현황 (onTrack/overdue 뱃지)

### 3. 테스트
- MoodTrendsFeatureTests, FrequencyGoalFeatureTests

## 완료 기준
- [ ] Mood 태깅 + 트렌드 UI 동작
- [ ] Frequency 목표 설정 + 대시보드 동작
- [ ] 빌드 PASS + 테스트 숫자 보고
