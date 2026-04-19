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

---

## 완료 보고

**커밋 1**: `[R5-ios] fix: ConversationStarterFeatureTests` (1 file)
**커밋 2**: `[R5-ios] feat: Relationship Nudges UI (v2.5)` (10 files, 신규 6 + 수정 4)
**테스트**: 511 tests, 0 failures (전체 PASS — pre-existing failure도 수정)
**신규 테스트**: 13건 전체 PASS

### 구현 내역

| 항목 | 파일 | 상태 |
|------|------|------|
| Model | `Core/Model/Nudge.swift` | Nudge, NudgePriority, NudgeSettings, NudgeSettingsPatch |
| Client | `Core/Network/NudgeClient.swift` | @DependencyClient, 4 endpoints |
| Feature | `Feature/Nudge/NudgeFeature.swift` | NudgeFeature + NudgeSettingsFeature |
| ListView | `Feature/Nudge/NudgeListView.swift` | priority 색상, dismiss 스와이프, 설정 시트 |
| SettingsView | `Feature/Nudge/NudgeSettingsView.swift` | 토글, 스테퍼(1~90, 1~10), 인물 제외 |
| DashboardFeature | `Feature/Settings/DashboardFeature.swift` | 넛지 로드 + dismiss 추가 |
| DashboardView | `Feature/Settings/DashboardView.swift` | 넛지 카드 (상위 3건) |
| L10n | `Core/L10n/L10n.swift` | 넛지 관련 한/영 17개 문자열 |
| Tests | `Tests/NudgeFeatureTests.swift` | 13 tests |
| Tests | `Tests/DashboardFeatureTests.swift` | nudgeClient 의존성 추가 |
| Fix | `Tests/ConversationStarterFeatureTests.swift` | pre-existing failure 수정 |

### 스펙 준수 확인
- [x] API contract § 5.16 필드명/타입 1:1 대조 완료
- [x] 엔드포인트 URL contract 그대로 복사
- [x] Keychain 토큰 사용 (UserDefaults 미사용)
- [x] silentDaysThreshold: 1~90 범위 클램핑
- [x] maxNudgesPerDay: 1~10 범위 클램핑
- [x] TestStore 테스트 필수 (happy + error path)
