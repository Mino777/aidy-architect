# WO-168: Contact Frequency Goals API

**담당**: server
**우선순위**: P4
**상태**: backlog
**스펙**: api-contract.md §5.41

## 구현 요구사항

### 1. Entity
- FrequencyGoal: id, userId, personId(FK), targetDays(1~365), reminderEnabled, createdAt, updatedAt

### 2. Controller + Service
- PUT /api/people/{personId}/frequency-goal — 빈도 목표 upsert
- DELETE /api/people/{personId}/frequency-goal — 빈도 목표 삭제
- GET /api/frequency-goals — 전체 목표 + 달성 현황

### 3. 달성 현황 계산
- lastContactDate: 해당 인물 관련 최근 ChatMessage 또는 InteractionLog 날짜
- daysSinceContact: 오늘 - lastContactDate
- onTrack: daysSinceContact <= targetDays

### 4. 테스트
- FrequencyGoalControllerTest: 설정/삭제/목록 조회/onTrack 계산

## 완료 기준
- [ ] PUT/DELETE /api/people/{personId}/frequency-goal 구현
- [ ] GET /api/frequency-goals 구현
- [ ] onTrack 계산 정확
- [ ] 빌드 PASS + 테스트 숫자 보고
