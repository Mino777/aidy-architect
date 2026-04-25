# WO-167: Mood Tracking API

**담당**: server
**우선순위**: P4
**상태**: backlog
**스펙**: api-contract.md §5.40

## 구현 요구사항

### 1. Entity
- ChatMood: id, chatId(FK), userId, mood(enum), taggedAt
- Mood enum: happy, grateful, neutral, anxious, sad, angry, excited, lonely

### 2. Controller + Service
- POST /api/chat/{chatId}/mood — 감정 태그 upsert
- DELETE /api/chat/{chatId}/mood — 감정 태그 삭제
- GET /api/mood/trends — 기간별 감정 분포 + 트렌드

### 3. 트렌드 로직
- period: week/month/year (기본 month)
- distribution: mood별 count
- dominantMood: 최다 mood
- trend: 최근 2주 vs 이전 2주 긍정 비율 비교 (improving/stable/declining)
- weeklyBreakdown: 주별 dominant mood + count

### 4. 테스트
- ChatMoodControllerTest: 태그 설정/삭제/트렌드 조회
- 경계: 존재하지 않는 chatId, 유효하지 않은 mood

## 완료 기준
- [ ] POST/DELETE /api/chat/{chatId}/mood 구현
- [ ] GET /api/mood/trends 구현 (week/month/year)
- [ ] trend 계산 로직 정확
- [ ] 빌드 PASS + 테스트 숫자 보고
