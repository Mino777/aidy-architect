# WO-086: iOS — Anniversary Reminders UI (v2.3)

**담당**: ios
**스펙**: `specs/api-contract.md` § 5.14 Anniversary Reminders (v2.3)
**선행**: WO-085 (서버 API)

## 구현 범위

### 화면
1. **AnniversaryListView** — 다가오는 기념일 카드 리스트
   - daysUntil에 따라 긴급도 색상 (7일 이내 빨강, 30일 이내 주황)
   - type별 아이콘 (birthday: 케이크, anniversary: 하트, custom: 별)
2. **AnniversaryFormView** — 기념일 등록/수정 폼
   - personId 선택 (People 목록에서)
   - date picker (MM-dd)
   - type 선택
3. **AnniversaryDetectView** — AI 감지 결과 화면
   - 후보 리스트 + confidence 표시
   - 체크박스로 선택 → 일괄 등록

### 데이터
1. **AnniversaryClient** — API 5개 엔드포인트
2. **AnniversaryFeature (TCA)** — 상태 관리
3. 탭바에 기념일 배지 (7일 이내 기념일 수)

### 커밋 규칙
- 메시지: `[R4-ios] feat: Anniversary Reminders UI (v2.3)`
- 파일 10개 이하/커밋

---

## 완료 보고

**커밋**: `[R1-ios] feat: Anniversary Reminders UI (v2.3)`
**파일 수**: 10 (신규 7 + 수정 3)
**테스트**: 487 tests, 1 pre-existing failure (ConversationStarterFeatureTests)
**신규 테스트**: 15건 전체 PASS

### 구현 내역

| 항목 | 파일 | 상태 |
|------|------|------|
| Model | `Core/Model/Anniversary.swift` | Anniversary, AnniversaryCandidate, AnniversaryType, request/response 모델 |
| Client | `Core/Network/AnniversaryClient.swift` | @DependencyClient, 5 endpoints (fetchList, create, update, delete, detect) |
| Feature | `Feature/Anniversary/AnniversaryFeature.swift` | AnniversaryFeature + AnniversaryFormFeature + AnniversaryDetectFeature |
| ListView | `Feature/Anniversary/AnniversaryListView.swift` | 긴급도 색상, type별 아이콘, swipe actions |
| FormView | `Feature/Anniversary/AnniversaryFormView.swift` | person picker, MM-dd date, type picker |
| DetectView | `Feature/Anniversary/AnniversaryDetectView.swift` | 후보 리스트, 체크박스, confidence badge |
| AppFeature | `App/AppFeature.swift` | anniversary 탭 + Scope 추가 |
| AppView | `App/AppView.swift` | gift.fill 탭 + .badge(urgentCount) |
| L10n | `Core/L10n/L10n.swift` | 기념일 관련 한/영 31개 문자열 |
| Tests | `Tests/AnniversaryFeatureTests.swift` | 15 tests (happy + error path) |

### 스펙 준수 확인
- [x] API contract § 5.14 필드명/타입 1:1 대조 완료
- [x] 엔드포인트 URL contract 그대로 복사
- [x] Keychain 토큰 사용 (UserDefaults 미사용)
- [x] API 키 하드코딩 없음
- [x] TestStore 테스트 필수 (happy + error path)
