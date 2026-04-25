# WO-172: iOS Communication Quality + Milestones UI

**담당**: ios
**우선순위**: P4
**상태**: backlog
**스펙**: api-contract.md §5.42, §5.43

## 구현 요구사항

### 1. Communication Quality
- CommunicationQualityClient: GET /api/insights/communication-quality
- CommunicationQualityFeature (TCA): 점수 조회 + 기간 전환
- CommunicationQualityView: 4차원 레이더/바 차트, suggestions 카드
- Insights 탭 또는 Settings에서 접근

### 2. Milestones
- MilestoneClient: GET/POST/PATCH/DELETE milestones API
- MilestoneFeature (TCA): 이정표 목록/등록/축하/삭제
- MilestoneListView: PersonDetail 내 이정표 섹션
- MilestoneFormView: 수동 이정표 등록 시트
- 이정표 축하 시 컨페티 애니메이션 (간단한 overlay)

### 3. 테스트
- CommunicationQualityFeatureTests, MilestoneFeatureTests

## 완료 기준
- [ ] Quality Score 4차원 시각화 동작
- [ ] Milestone CRUD + 축하 토글 동작
- [ ] 빌드 PASS + 테스트 숫자 보고
