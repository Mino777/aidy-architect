# WO-173: Android Mood Tracking + Contact Frequency Goals UI

**담당**: android
**우선순위**: P4
**상태**: backlog
**스펙**: api-contract.md §5.40, §5.41

## 구현 요구사항

### 1. Mood Tracking
- MoodRepository: POST/DELETE /api/chat/{chatId}/mood, GET /api/mood/trends
- MoodPickerRow: 대화 후 감정 선택 (8개 이모지 Chip, 채팅 화면 하단)
- MoodTrendsViewModel + MoodTrendsScreen: 기간별 감정 분포 (바 차트 Compose)
- Settings 또는 Insights 네비게이션에서 접근

### 2. Contact Frequency Goals
- FrequencyGoalRepository: PUT/DELETE /api/people/{personId}/frequency-goal, GET /api/frequency-goals
- FrequencyGoalViewModel + FrequencyGoalScreen: 목표 설정/삭제/목록
- FrequencyGoalSettingDialog: PersonDetail에서 목표 설정
- FrequencyDashboardCard: 전체 목표 달성 현황 (onTrack/overdue 표시)

### 3. 테스트
- MoodTrendsViewModelTest, FrequencyGoalViewModelTest

## 완료 기준
- [ ] Mood 태깅 + 트렌드 UI 동작
- [ ] Frequency 목표 설정 + 대시보드 동작
- [ ] 빌드 PASS + 테스트 숫자 보고
