# WO-174: Android Communication Quality + Milestones UI

**담당**: android
**우선순위**: P4
**상태**: backlog
**스펙**: api-contract.md §5.42, §5.43

## 구현 요구사항

### 1. Communication Quality
- CommunicationQualityRepository: GET /api/insights/communication-quality
- CommunicationQualityViewModel + CommunicationQualityScreen: 점수 조회 + 기간 전환
- QualityScoreCard: 4차원 바 차트, suggestions 카드
- Insights 또는 Settings 네비게이션에서 접근

### 2. Milestones
- MilestoneRepository: GET/POST/PATCH/DELETE milestones API
- MilestoneViewModel + MilestoneScreen: 이정표 목록/등록/축하/삭제
- MilestoneListSection: PersonDetail 내 이정표 섹션
- MilestoneFormDialog: 수동 이정표 등록
- 축하 시 간단한 애니메이션 (scale + confetti)

### 3. 테스트
- CommunicationQualityViewModelTest, MilestoneViewModelTest

## 완료 기준
- [ ] Quality Score 4차원 시각화 동작
- [ ] Milestone CRUD + 축하 토글 동작
- [ ] 빌드 PASS + 테스트 숫자 보고
