# WO-092: iOS — Relationship Nudges UI (v2.5)

**담당**: ios
**스펙**: `specs/api-contract.md` § 5.16 Relationship Nudges (v2.5)
**선행**: WO-091 (서버 API)

## 구현 범위

### 화면
1. **NudgeListView** — 넛지 카드 리스트
   - priority별 색상 (high: 빨강, medium: 주황, low: 회색)
   - 인물 이름 + relationship + daysSilent 표시
   - suggestion 텍스트
   - dismiss 스와이프 액션
2. **NudgeSettingsView** — 넛지 설정 화면
   - enabled 토글
   - silentDaysThreshold 스테퍼 (1~90)
   - maxNudgesPerDay 스테퍼 (1~10)
   - excludedPersonIds 인물 선택

### 데이터
1. **NudgeClient** — API 4개 엔드포인트
2. **NudgeFeature (TCA)** — 상태 관리
3. Dashboard에 넛지 섹션 추가

### 커밋 규칙
- 메시지: `[R7-ios] feat: Relationship Nudges UI (v2.5)`
- 파일 10개 이하/커밋
