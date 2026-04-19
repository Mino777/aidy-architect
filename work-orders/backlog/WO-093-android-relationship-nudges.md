# WO-093: Android — Relationship Nudges UI (v2.5)

**담당**: android
**스펙**: `specs/api-contract.md` § 5.16 Relationship Nudges (v2.5)
**선행**: WO-091 (서버 API)

## 구현 범위

### 화면
1. **NudgeListScreen** — 넛지 카드 리스트
   - priority별 색상 (high: 빨강, medium: 주황, low: 회색)
   - 인물 이름 + relationship + daysSilent 표시
   - suggestion 텍스트
   - dismiss SwipeToDismiss
2. **NudgeSettingsScreen** — 넛지 설정 화면
   - enabled Switch
   - silentDaysThreshold Slider (1~90)
   - maxNudgesPerDay Slider (1~10)
   - excludedPersonIds 인물 선택 Dialog

### 데이터
1. **NudgeApi** — Retrofit 인터페이스
2. **NudgeRepository**
3. **NudgeViewModel** — 상태 관리
4. Dashboard에 넛지 섹션 추가

### 커밋 규칙
- 메시지: `[R7-android] feat: Relationship Nudges UI (v2.5)`
- 파일 10개 이하/커밋
